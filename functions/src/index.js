import crypto from 'node:crypto';
import { onRequest } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { generateAccessCode, hashAccessCode, verifyAccessCode } from './shared/accessCode.js';
import { createOrderPaymentIntent } from './orders/paymentIntentService.js';
import { canTransition } from './orders/statusMachine.js';
import { mercadoPagoProvider } from './payments/adapters/mercadoPagoProvider.js';
import { payPalProvider, verifyPayPalWebhook } from './payments/adapters/paypalProvider.js';
import { FirestoreOrdersStore, FirestorePaymentEventsStore } from './firestoreStores.js';

initializeApp();
const firestore = getFirestore();

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
  completed: 'Paid',
};

const defaultPaymentEventsStore = new FirestorePaymentEventsStore(firestore);
const defaultOrdersStore = new FirestoreOrdersStore(firestore);

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
    return { status: 405, body: { ok: false, reason: 'method_not_allowed' } };
  }

  const orderId = String(request?.body?.orderId ?? '').trim();
  const typedCode = String(request?.body?.code ?? '').trim();
  const assetPath = String(request?.body?.assetPath ?? '').trim();
  if (!orderId || !/^\d{6}$/.test(typedCode)) {
    return { status: 400, body: { ok: false, reason: 'invalid_payload' } };
  }

  const order = await (options.ordersStore ?? defaultOrdersStore).findById(orderId);
  if (!order?.delivery?.access) {
    return { status: 404, body: { ok: false, reason: 'order_not_found' } };
  }

  const validation = await validateOrderAccessCode(order.delivery.access, typedCode);
  if (!validation.valid) {
    return {
      status: validation.reason === 'expired' ? 410 : 401,
      body: { ok: false, reason: validation.reason },
    };
  }

  const signedDownloadUrl = await options.signDownloadUrl?.({ orderId, assetPath, expiresInSeconds: 300 });

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

function getHeader(headers, name) {
  if (!headers) return undefined;
  const value = headers[name] ?? headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] : value;
}

export async function webhookMercadoPago(event, options = {}) {
  const rawBody = options.rawBody ?? JSON.stringify(event);
  const headers = options.headers ?? {};
  const signature = options.signature ?? getHeader(headers, 'x-signature');
  const requestId = getHeader(headers, 'x-request-id');

  const isValid = validateMercadoPagoSignature({
    rawBody,
    signature,
    requestId,
    secret: options.secret ?? process.env.MERCADOPAGO_WEBHOOK_SECRET,
    dataId: event.data?.id ?? event.id,
  });

  if (!isValid) {
    return { accepted: false, reason: 'invalid_signature' };
  }

  return processWebhookEvent('mercadopago', event, {
    ...options,
    skipSignatureValidation: true,
    providerEventId: extractMercadoPagoProviderEventId(event),
    externalReference: extractExternalReference(event),
    providerStatus: extractProviderStatus(event),
  });
}

export async function webhookPayPal(event, options = {}) {
  const rawBody = options.rawBody ?? JSON.stringify(event);
  const headers = options.headers ?? {};

  const verified = options.skipSignatureValidation
    ? true
    : await verifyPayPalWebhook(rawBody, normalizeHeaders(headers));

  if (!verified) {
    return { accepted: false, reason: 'invalid_signature' };
  }

  return processWebhookEvent('paypal', event, {
    ...options,
    skipSignatureValidation: true,
    providerEventId: extractPayPalProviderEventId(event),
    externalReference: extractExternalReference(event),
    providerStatus: extractProviderStatus(event),
  });
}

function normalizeHeaders(headers) {
  return Object.fromEntries(Object.entries(headers).map(([key, value]) => [key.toLowerCase(), value]));
}

export function validateMercadoPagoSignature({ rawBody, signature, requestId, secret, dataId }) {
  if (!secret) {
    return true;
  }

  if (!signature || !requestId || !dataId) {
    return false;
  }

  const parts = Object.fromEntries(
    String(signature)
      .split(',')
      .map((part) => part.trim().split('=')),
  );

  const ts = parts.ts;
  const hash = parts.v1;
  if (!ts || !hash) {
    return false;
  }

  const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
  const expected = crypto.createHmac('sha256', secret).update(manifest).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(expected));
}

async function processWebhookEvent(provider, event, options) {
  const { paymentEventsStore = defaultPaymentEventsStore, ordersStore = defaultOrdersStore, providerEventId } =
    options;

  if (!providerEventId) {
    return { accepted: false, reason: 'missing_provider_event_id' };
  }

  if (await paymentEventsStore.has(providerEventId)) {
    return { accepted: true, duplicate: true, provider, providerEventId, status: 'ignored' };
  }

  await paymentEventsStore.insert(providerEventId, { provider });

  const statusResult = await updateOrderStatusByExternalReference({
    ordersStore,
    externalReference: options.externalReference,
    providerStatus: options.providerStatus,
  });

  return { accepted: true, provider, providerEventId, duplicate: false, ...statusResult };
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

export const createPaymentIntent = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, reason: 'method_not_allowed' });
    return;
  }

  const orderId = String(req.path.split('/')[2] ?? req.body?.orderId ?? '').trim();
  const provider = String(req.query.provider ?? req.body?.provider ?? '').toLowerCase();
  if (!orderId || !['mercadopago', 'paypal'].includes(provider)) {
    res.status(400).json({ ok: false, reason: 'invalid_payload' });
    return;
  }

  const order = await defaultOrdersStore.findById(orderId);
  if (!order) {
    res.status(404).json({ ok: false, reason: 'order_not_found' });
    return;
  }

  const selectedProvider = provider === 'mercadopago' ? mercadoPagoProvider : payPalProvider;
  const { paymentIntent } = await createOrderPaymentIntent(order, selectedProvider, req.body ?? {});
  await defaultOrdersStore.savePaymentIntent(orderId, paymentIntent);

  res.status(201).json({ ok: true, paymentIntent });
});

export const mercadoPagoWebhook = onRequest(async (req, res) => {
  const result = await webhookMercadoPago(req.body, {
    rawBody: req.rawBody?.toString() ?? JSON.stringify(req.body),
    headers: req.headers,
  });
  res.status(result.accepted ? 200 : 400).json(result);
});

export const payPalWebhook = onRequest(async (req, res) => {
  const result = await webhookPayPal(req.body, {
    rawBody: req.rawBody?.toString() ?? JSON.stringify(req.body),
    headers: req.headers,
  });
  res.status(result.accepted ? 200 : 400).json(result);
});

export const validateAccess = onRequest(async (req, res) => {
  const result = await validateAccessEndpoint(req, { ordersStore: defaultOrdersStore });
  res.status(result.status).json(result.body);
});
