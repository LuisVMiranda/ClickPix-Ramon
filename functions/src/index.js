import crypto from 'node:crypto';
import { onRequest } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import {
  buildGalleryDownloadItems,
  createStoragePrefix,
  deliverOrderAssets,
  listGalleryAssets,
  signDownloadUrl,
} from './storage/deliveryStorage.js';
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
const accessUnlockedStatuses = new Set(['Paid', 'Delivering', 'Delivered']);

function normalizeRequestPath(pathname = '') {
  const segments = String(pathname)
    .split('/')
    .map((segment) => segment.trim())
    .filter(Boolean);

  return segments[0] === 'orders' ? segments.slice(1) : segments;
}

function toStringKeyedMap(rawValue) {
  if (!rawValue || typeof rawValue !== 'object' || Array.isArray(rawValue)) {
    return {};
  }

  return Object.fromEntries(Object.entries(rawValue).map(([key, value]) => [String(key), value]));
}

function normalizeItems(rawItems = []) {
  if (!Array.isArray(rawItems)) {
    return [];
  }

  return rawItems
    .map((item) => toStringKeyedMap(item))
    .filter((item) => String(item.photoAssetId ?? '').trim())
    .map((item) => ({
      photoAssetId: String(item.photoAssetId).trim(),
      unitPriceCents: Number(item.unitPriceCents ?? 0),
    }));
}

function normalizeAssets(rawAssets = []) {
  if (!Array.isArray(rawAssets)) {
    return [];
  }

  return rawAssets
    .map((asset, index) => {
      const map = toStringKeyedMap(asset);
      const sourceId = String(map.sourceId ?? map.photoAssetId ?? `asset-${index + 1}`).trim();
      const fileName = String(map.fileName ?? '').trim();
      const base64Data = String(map.base64Data ?? '').trim();
      const downloadUrl = String(map.downloadUrl ?? '').trim();
      const contentType = String(map.contentType ?? '').trim();

      if (!sourceId || (!base64Data && !downloadUrl)) {
        return null;
      }

      return {
        sourceId,
        fileName,
        base64Data,
        downloadUrl,
        contentType: contentType || 'image/jpeg',
      };
    })
    .filter(Boolean);
}

function canAccessDelivery(order = {}) {
  const totalAmountCents = Number(order.totalAmountCents ?? 0);
  if (totalAmountCents <= 0) {
    return true;
  }

  return accessUnlockedStatuses.has(String(order.status ?? '').trim());
}

function buildPaymentStatusSummary(order = {}) {
  const payment = toStringKeyedMap(order.payment);
  const orderStatus = String(order.status ?? '').trim();
  const paymentStatus = String(payment.status ?? orderStatus ?? 'pending').trim();

  return {
    ok: true,
    orderId: order.id,
    orderStatus,
    provider: payment.provider ?? null,
    status: paymentStatus,
    paid: canAccessDelivery(order),
    externalReference: order.externalReference ?? payment.externalReference ?? null,
    checkoutUrl: payment.checkoutUrl ?? null,
    qrCodeText: payment.qrCodeText ?? null,
    qrCodeBase64: payment.qrCodeBase64 ?? null,
    deliveryLocked: !canAccessDelivery(order),
  };
}

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

export async function finalizeOrderDelivery({
  orderId,
  expirationDays = 7,
  assets = [],
  ordersStore = defaultOrdersStore,
  uploadAssets = deliverOrderAssets,
}) {
  const order = await ordersStore.findById(orderId);
  if (!order) {
    return { ok: false, reason: 'order_not_found' };
  }

  const generated = await generateOrderAccessCode(orderId, expirationDays);
  const storagePrefix = createStoragePrefix(orderId);
  const uploadedAssets = await uploadAssets({ orderId, storagePrefix, assets });

  await ordersStore.saveDelivery(orderId, {
    storagePrefix,
    galleryId: order.delivery?.galleryId ?? orderId,
    access: generated.access,
    assets: uploadedAssets,
    deliveredAt: new Date().toISOString(),
  });

  return {
    ok: true,
    orderId,
    code: generated.code,
    storagePrefix,
    assets: uploadedAssets,
    expiresAt: generated.access.expiresAt,
  };
}

export async function validateAccessEndpoint(request, options = {}) {
  if (request?.method !== 'POST') {
    return { status: 405, body: { ok: false, reason: 'method_not_allowed' } };
  }

  const orderId = String(request?.body?.orderId ?? '').trim();
  const typedCode = String(request?.body?.code ?? '').trim();
  if (!orderId || !/^\d{6}$/.test(typedCode)) {
    return { status: 400, body: { ok: false, reason: 'invalid_payload' } };
  }

  const order = await (options.ordersStore ?? defaultOrdersStore).findById(orderId);
  if (!order?.delivery?.access) {
    return { status: 404, body: { ok: false, reason: 'order_not_found' } };
  }

  if (!canAccessDelivery(order)) {
    return {
      status: 423,
      body: { ok: false, reason: 'payment_pending' },
    };
  }

  const validation = await validateOrderAccessCode(order.delivery.access, typedCode);
  if (!validation.valid) {
    return {
      status: validation.reason === 'expired' ? 410 : 401,
      body: { ok: false, reason: validation.reason },
    };
  }

  const assets = await (options.listGalleryAssets ?? listGalleryAssets)({
    orderId,
    storagePrefix: order.delivery.storagePrefix,
    fallbackAssets: order.delivery.assets,
  });

  const downloads = await buildGalleryDownloadItems({
    orderId,
    assets,
    expiresInSeconds: 300,
    signDownloadUrl: options.signDownloadUrl ?? signDownloadUrl,
  });

  return {
    status: 200,
    body: {
      ok: true,
      orderId,
      galleryId: order.delivery.galleryId,
      assets: downloads,
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

  await ordersStore.updateStatus(order.id, nextStatus, { providerStatus });
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

export async function syncOrderToCloud(payload, options = {}) {
  const order = toStringKeyedMap(payload?.order);
  const client = toStringKeyedMap(payload?.client);
  const orderId = String(order.id ?? '').trim();
  const clientId = String(client.id ?? order.clientId ?? '').trim();
  const totalAmountCents = Number(order.totalAmountCents ?? 0);
  const expirationDays = Number(payload?.expirationDays ?? 7);
  const currency = String(order.currency ?? 'BRL').trim() || 'BRL';
  const paymentMethod = String(order.paymentMethod ?? 'pix').trim() || 'pix';
  const externalReference = String(order.externalReference ?? orderId).trim() || orderId;
  const items = normalizeItems(payload?.items);
  const assets = normalizeAssets(payload?.assets);

  if (
    !orderId ||
    !clientId ||
    Number.isNaN(totalAmountCents) ||
    Number.isNaN(expirationDays) ||
    expirationDays <= 0
  ) {
    return { status: 400, body: { ok: false, reason: 'invalid_payload' } };
  }

  const ordersStore = options.ordersStore ?? defaultOrdersStore;
  const uploadAssets = options.uploadAssets ?? deliverOrderAssets;
  const existingOrder = await ordersStore.findById(orderId);
  const storagePrefix = existingOrder?.delivery?.storagePrefix ?? createStoragePrefix(orderId);

  const uploadedAssets =
    Array.isArray(existingOrder?.delivery?.assets) && existingOrder.delivery.assets.length > 0
      ? existingOrder.delivery.assets
      : await uploadAssets({
          orderId,
          storagePrefix,
          assets,
        });

  let access = existingOrder?.delivery?.access;
  let accessCode = null;
  if (!access?.hash || !access?.expiresAt) {
    const generated = await generateOrderAccessCode(orderId, expirationDays);
    access = generated.access;
    accessCode = generated.code;
  }

  const nextStatus = String(order.status ?? existingOrder?.status ?? 'Created').trim() || 'Created';
  const createdAt = String(order.createdAt ?? existingOrder?.createdAt ?? '').trim() || new Date().toISOString();

  await ordersStore.saveSyncedOrder(orderId, {
    clientId,
    client: {
      id: clientId,
      name: String(client.name ?? '').trim(),
      whatsapp: String(client.whatsapp ?? '').trim(),
      email: String(client.email ?? '').trim() || null,
    },
    totalAmountCents,
    currency,
    paymentMethod,
    externalReference,
    status: nextStatus,
    source: 'mobile',
    photoCount: items.length,
    items,
    createdAt,
    delivery: {
      galleryId: existingOrder?.delivery?.galleryId ?? orderId,
      storagePrefix,
      access,
      assets: uploadedAssets,
      lockedUntilPaid: totalAmountCents > 0,
      syncedAt: new Date().toISOString(),
    },
  });

  return {
    status: 201,
    body: {
      ok: true,
      orderId,
      orderStatus: nextStatus,
      accessCode,
      delivery: {
        expiresAt: access.expiresAt,
        storagePrefix,
        lockedUntilPaid: !canAccessDelivery({
          totalAmountCents,
          status: nextStatus,
        }),
        assets: uploadedAssets,
      },
    },
  };
}

export async function createPaymentIntentForOrder({
  orderId,
  provider,
  payload = {},
  ordersStore = defaultOrdersStore,
}) {
  if (!orderId || !['mercadopago', 'paypal'].includes(provider)) {
    return { status: 400, body: { ok: false, reason: 'invalid_payload' } };
  }

  const order = await ordersStore.findById(orderId);
  if (!order) {
    return { status: 404, body: { ok: false, reason: 'order_not_found' } };
  }

  try {
    const selectedProvider = provider === 'mercadopago' ? mercadoPagoProvider : payPalProvider;
    const { paymentIntent } = await createOrderPaymentIntent(order, selectedProvider, payload);
    await ordersStore.savePaymentIntent(orderId, paymentIntent);
    return { status: 201, body: { ok: true, paymentIntent } };
  } catch (error) {
    return {
      status: 409,
      body: {
        ok: false,
        reason: 'payment_intent_error',
        message: error instanceof Error ? error.message : String(error),
      },
    };
  }
}

export async function getOrderPaymentStatus(orderId, options = {}) {
  const normalizedOrderId = String(orderId ?? '').trim();
  if (!normalizedOrderId) {
    return { status: 400, body: { ok: false, reason: 'invalid_payload' } };
  }

  const order = await (options.ordersStore ?? defaultOrdersStore).findById(normalizedOrderId);
  if (!order) {
    return { status: 404, body: { ok: false, reason: 'order_not_found' } };
  }

  return {
    status: 200,
    body: buildPaymentStatusSummary(order),
  };
}

export const createPaymentIntent = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, reason: 'method_not_allowed' });
    return;
  }

  const pathSegments = normalizeRequestPath(req.path);
  const orderId = String(pathSegments[0] ?? req.body?.orderId ?? '').trim();
  const provider = String(req.query.provider ?? req.body?.provider ?? '').toLowerCase();
  const result = await createPaymentIntentForOrder({
    orderId,
    provider,
    payload: req.body ?? {},
  });
  res.status(result.status).json(result.body);
});

export const confirmOrderDelivery = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ ok: false, reason: 'method_not_allowed' });
    return;
  }

  const orderId = String(req.path.split('/')[2] ?? req.body?.orderId ?? '').trim();
  const expirationDays = Number(req.body?.expirationDays ?? 7);
  if (!orderId || Number.isNaN(expirationDays) || expirationDays <= 0) {
    res.status(400).json({ ok: false, reason: 'invalid_payload' });
    return;
  }

  const result = await finalizeOrderDelivery({
    orderId,
    expirationDays,
    assets: Array.isArray(req.body?.assets) ? req.body.assets : [],
  });

  if (!result.ok) {
    res.status(404).json(result);
    return;
  }

  res.status(200).json(result);
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

export const ordersApi = onRequest(async (req, res) => {
  const pathSegments = normalizeRequestPath(req.path);

  if (req.method === 'POST' && pathSegments.length === 1 && pathSegments[0] === 'sync') {
    const result = await syncOrderToCloud(req.body, {});
    res.status(result.status).json(result.body);
    return;
  }

  if (req.method === 'POST' && pathSegments.length === 2 && pathSegments[1] === 'payment-intents') {
    const result = await createPaymentIntentForOrder({
      orderId: pathSegments[0],
      provider: String(req.query.provider ?? req.body?.provider ?? '').toLowerCase(),
      payload: req.body ?? {},
    });
    res.status(result.status).json(result.body);
    return;
  }

  if (req.method === 'GET' && pathSegments.length === 2 && pathSegments[1] === 'payment-status') {
    const result = await getOrderPaymentStatus(pathSegments[0], {});
    res.status(result.status).json(result.body);
    return;
  }

  res.status(404).json({ ok: false, reason: 'not_found' });
});

export const validateAccess = onRequest(async (req, res) => {
  const result = await validateAccessEndpoint(req, { ordersStore: defaultOrdersStore });
  res.status(result.status).json(result.body);
});
