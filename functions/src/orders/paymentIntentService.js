import { canTransition } from './statusMachine.js';
import { buildExternalReference } from '../payments/externalReference.js';
import { assertPaymentProvider } from '../payments/paymentProvider.js';

function toProviderMetadata(intent) {
  return {
    provider: intent.provider,
    providerIntentId: intent.providerIntentId,
    externalReference: intent.externalReference,
    checkoutUrl: intent.checkoutUrl,
    status: intent.status,
    qrCodeText: intent.qrCodeText,
    qrCodeBase64: intent.qrCodeBase64,
  };
}

function resolveOrderShortId(order) {
  if (typeof order.shortId === 'string' && order.shortId.length > 0) return order.shortId;
  if (typeof order.id === 'string' && order.id.length > 0) return order.id.slice(0, 8);
  throw new Error('Order must provide id or shortId');
}

export async function createOrderPaymentIntent(order, provider, payload = {}) {
  assertPaymentProvider(provider);

  if (!canTransition(order.status, 'AwaitingPayment')) {
    throw new Error(`Order cannot transition from ${order.status} to AwaitingPayment`);
  }

  const externalReference = buildExternalReference(resolveOrderShortId(order));

  const intent = await provider.createPaymentIntent({
    amountCents: order.totalAmountCents,
    currency: order.currency,
    externalReference,
    description: `Order ${order.id}`,
    orderId: order.id,
    payer: payload.payer,
    methodData: payload.methodData,
  });

  const nextOrder = {
    ...order,
    status: 'AwaitingPayment',
    providerDataJson: JSON.stringify(toProviderMetadata(intent)),
  };

  return { order: nextOrder, paymentIntent: intent };
}
