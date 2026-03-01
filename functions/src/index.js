import crypto from 'node:crypto';
import { generateAccessCode, hashAccessCode, verifyAccessCode } from './shared/accessCode.js';
import { createOrderPaymentIntent } from './orders/paymentIntentService.js';
import { canTransition } from './orders/statusMachine.js';
import { mercadoPagoProvider } from './payments/adapters/mercadoPagoProvider.js';
import { payPalProvider } from './payments/adapters/paypalProvider.js';

const providerStatusToOrderStatus = {
  approved: 'Paid',
  paid: 'Paid',
  pending: 'AwaitingPayment',
  in_process: 'AwaitingPayment',
  created: 'AwaitingPayment',
  expired: 'Expired',
  cancelled: 'Canceled',
  canceled: 'Canceled',
  refunded: 'Refunded',
  partially_refunded: 'Refunded',
  chargeback: 'Refunded',
};

class InMemoryPaymentEventsStore {
  constructor() {
    this._eventIds = new Set();
  }

  async has(providerEventId) {
    return this._eventIds.has(providerEventId);
  }

  async insert(providerEventId) {
    this._eventIds.add(providerEventId);
  }
}

const defaultPaymentEventsStore = new InMemoryPaymentEventsStore();

function buildExpiresAt(expirationDays) {
  return new Date(Date.now() + expirationDays * 86400000).toISOString();
}

export async function generateOrderAccessCode(orderId, expirationDays = 7) {
  const code = generateAccessCode();
  const hash = await hashAccessCode(code);
  const expiresAt = buildExpiresAt(expirationDays);
  return {
    orderId,
    code,
    access: {
      hash,
      expiresAt,
      version: 1,
      replacedAt: null,
    },
  };
}

export async function renewOrderAccessCode(previousAccess = {}, expirationDays = 7) {
  const code = generateAccessCode();
  const hash = await hashAccessCode(code);
  const expiresAt = buildExpiresAt(expirationDays);
  return {
    code,
    access: {
      hash,
      expiresAt,
      version: (previousAccess.version ?? 1) + 1,
      replacedAt: previousAccess.hash ? new Date().toISOString() : null,
    },
    invalidated: previousAccess.hash
      ? {
          hash: previousAccess.hash,
          version: previousAccess.version ?? 1,
          invalidatedAt: new Date().toISOString(),
        }
      : null,
  };
}

export async function validateOrderAccessCode(access, typedCode) {
  if (!access?.hash || !access?.expiresAt) {
    return { valid: false, reason: 'missing_code' };
  }
  if (new Date(access.expiresAt) < new Date()) return { valid: false, reason: 'expired' };
  const ok = await verifyAccessCode(access.hash, typedCode);
  return { valid: ok, reason: ok ? 'ok' : 'invalid_code' };
}

export async function validateAccessEndpoint(request, options = {}) {
  if (request?.method !== 'POST') {
    return {
      status: 405,
      body: { ok: false, reason: 'method_not_allowed' },
    };
  }

  const orderId = String(request?.body?.orderId ?? '').trim();
  const typedCode = String(request?.body?.code ?? '').trim();
  const assetPath = String(request?.body?.assetPath ?? '').trim();
  if (!orderId || !/^\d{6}$/.test(typedCode)) {
    return {
      status: 400,
      body: { ok: false, reason: 'invalid_payload' },
    };
  }

  const order = await options.ordersStore?.findById(orderId);
  if (!order?.delivery?.access) {
    return {
      status: 404,
      body: { ok: false, reason: 'order_not_found' },
    };
  }

  const validation = await validateOrderAccessCode(order.delivery.access, typedCode);
  if (!validation.valid) {
    return {
      status: validation.reason === 'expired' ? 410 : 401,
      body: {
        ok: false,
        reason: validation.reason,
        message:
          validation.reason === 'expired'
            ? 'Seu código expirou. Solicite um novo código.'
            : 'Código inválido. Verifique os 6 dígitos e tente novamente.',
      },
    };
  }

  const signedDownloadUrl = await options.signDownloadUrl?.({
    orderId,
    assetPath,
    expiresInSeconds: 300,
  });

  return {
    status: 200,
    body: {
      ok: true,
      orderId,
      galleryId: order.delivery.galleryId,
      signedDownloadUrl: signedDownloadUrl ?? null,
      downloadExpiresInSeconds: 300,
    },
  };
}

export async function webhookMercadoPago(event, options = {}) {
  return processWebhookEvent('mercadopago', event, {
    ...options,
    providerEventId: extractMercadoPagoProviderEventId(event),
    externalReference: extractExternalReference(event),
    providerStatus: extractProviderStatus(event),
  });
}

export async function webhookPayPal(event, options = {}) {
  return processWebhookEvent('paypal', event, {
    ...options,
    providerEventId: extractPayPalProviderEventId(event),
    externalReference: extractExternalReference(event),
    providerStatus: extractProviderStatus(event),
  });
}

async function processWebhookEvent(provider, event, options) {
  const {
    rawBody = JSON.stringify(event),
    signature,
    secret,
    paymentEventsStore = defaultPaymentEventsStore,
    ordersStore,
    providerEventId,
    externalReference,
    providerStatus,
  } = options;

  if (!validateWebhookSignature({ rawBody, signature, secret })) {
    return { accepted: false, reason: 'invalid_signature' };
  }

  if (!providerEventId) {
    return { accepted: false, reason: 'missing_provider_event_id' };
  }

  if (await paymentEventsStore.has(providerEventId)) {
    return {
      accepted: true,
      duplicate: true,
      provider,
      providerEventId,
      externalReference,
      status: 'ignored',
    };
  }

  await paymentEventsStore.insert(providerEventId);

  const statusResult = await updateOrderStatusByExternalReference({
    ordersStore,
    externalReference,
    providerStatus,
  });

  return {
    accepted: true,
    provider,
    providerEventId,
    externalReference,
    duplicate: false,
    ...statusResult,
  };
}

function validateWebhookSignature({ rawBody, signature, secret }) {
  if (!secret) {
    return true;
  }

  if (!signature) {
    return false;
  }

  const expectedSignature = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  const provided = Buffer.from(signature);
  const expected = Buffer.from(expectedSignature);

  if (provided.length !== expected.length) {
    return false;
  }

  return crypto.timingSafeEqual(provided, expected);
}

async function updateOrderStatusByExternalReference({ ordersStore, externalReference, providerStatus }) {
  if (!ordersStore || !externalReference) {
    return { status: 'no_order_update' };
  }

  const order = await ordersStore.findByExternalReference(externalReference);
  if (!order) {
    return { status: 'order_not_found' };
  }

  const nextStatus = providerStatusToOrderStatus[String(providerStatus ?? '').toLowerCase()];
  if (!nextStatus) {
    return { status: 'unknown_provider_status' };
  }

  if (order.status === nextStatus) {
    return { status: 'already_in_target_state', orderId: order.id, orderStatus: order.status };
  }

  if (!canTransition(order.status, nextStatus)) {
    return {
      status: 'ignored_invalid_transition',
      orderId: order.id,
      orderStatus: order.status,
      attemptedStatus: nextStatus,
    };
  }

  await ordersStore.updateStatus(order.id, nextStatus);
  return { status: 'order_updated', orderId: order.id, orderStatus: nextStatus };
}

function extractExternalReference(event) {
  return (
    event.external_reference ??
    event.data?.external_reference ??
    event.resource?.external_reference ??
    event.resource?.purchase_units?.[0]?.reference_id ??
    null
  );
}

function extractProviderStatus(event) {
  return event.status ?? event.data?.status ?? event.resource?.status ?? event.action ?? null;
}

function extractMercadoPagoProviderEventId(event) {
  return event.id ?? event.data?.id ?? null;
}

function extractPayPalProviderEventId(event) {
  return event.id ?? event.event_id ?? event.resource?.id ?? null;
}

export async function createMercadoPagoIntent(order) {
  return createOrderPaymentIntent(order, mercadoPagoProvider);
}

export async function createPayPalIntent(order) {
  return createOrderPaymentIntent(order, payPalProvider);
}
