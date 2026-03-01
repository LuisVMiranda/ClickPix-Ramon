import test from 'node:test';
import assert from 'node:assert/strict';
import { createOrderPaymentIntent } from '../src/orders/paymentIntentService.js';
import { mercadoPagoProvider } from '../src/payments/adapters/mercadoPagoProvider.js';
import { payPalProvider } from '../src/payments/adapters/paypalProvider.js';

function makeOrder(overrides = {}) {
  return {
    id: 'order-12345678',
    shortId: 'A1B2C3',
    status: 'Created',
    totalAmountCents: 15900,
    currency: 'BRL',
    ...overrides,
  };
}

test('creates Mercado Pago intent and moves order to AwaitingPayment', async () => {
  const order = makeOrder();

  const { order: updatedOrder, paymentIntent } = await createOrderPaymentIntent(order, mercadoPagoProvider);

  assert.equal(updatedOrder.status, 'AwaitingPayment');
  assert.equal(paymentIntent.provider, 'mercadopago');
  assert.match(paymentIntent.externalReference, /^PFBR-\d{8}-A1B2C3-[A-F0-9]{8}$/);
  assert.equal(paymentIntent.amountCents, 15900);

  const providerData = JSON.parse(updatedOrder.providerDataJson);
  assert.deepEqual(providerData, {
    provider: 'mercadopago',
    providerIntentId: paymentIntent.providerIntentId,
    externalReference: paymentIntent.externalReference,
    checkoutUrl: paymentIntent.checkoutUrl,
    status: 'pending',
  });
});

test('creates PayPal intent with convergent PaymentIntent contract', async () => {
  const order = makeOrder({ currency: 'USD' });
  const { paymentIntent } = await createOrderPaymentIntent(order, payPalProvider);

  assert.equal(paymentIntent.provider, 'paypal');
  assert.equal(paymentIntent.currency, 'USD');
  assert.equal(paymentIntent.status, 'pending');
  assert.equal(typeof paymentIntent.providerIntentId, 'string');
  assert.equal(typeof paymentIntent.checkoutUrl, 'string');
});

test('externalReference stays unique across consecutive intents', async () => {
  const order = makeOrder();
  const one = await createOrderPaymentIntent(order, mercadoPagoProvider);
  const two = await createOrderPaymentIntent(order, mercadoPagoProvider);

  assert.notEqual(one.paymentIntent.externalReference, two.paymentIntent.externalReference);
});

test('throws when AwaitingPayment transition is not allowed', async () => {
  const order = makeOrder({ status: 'Paid' });

  await assert.rejects(
    () => createOrderPaymentIntent(order, payPalProvider),
    /Order cannot transition from Paid to AwaitingPayment/,
  );
});
