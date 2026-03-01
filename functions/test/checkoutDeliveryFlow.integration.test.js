import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { createOrderPaymentIntent } from '../src/orders/paymentIntentService.js';
import { finalizeOrderDelivery, validateAccessEndpoint, webhookMercadoPago } from '../src/index.js';

class InMemoryOrdersStore {
  constructor(order) {
    this.order = order;
  }

  async findById(orderId) {
    return this.order.id === orderId ? this.order : null;
  }

  async findByExternalReference(externalReference) {
    return this.order.externalReference === externalReference ? this.order : null;
  }

  async updateStatus(orderId, status) {
    if (this.order.id === orderId) {
      this.order = { ...this.order, status };
    }
  }

  async saveDelivery(orderId, delivery) {
    if (this.order.id === orderId) {
      this.order = { ...this.order, status: 'Delivered', delivery };
    }
  }
}

class InMemoryPaymentEventsStore {
  constructor() {
    this.providerEvents = new Set();
  }

  async has(providerEventId) {
    return this.providerEvents.has(providerEventId);
  }

  async insert(providerEventId) {
    this.providerEvents.add(providerEventId);
  }
}

function buildMercadoPagoHeaders(secret, event) {
  const ts = '1700000015';
  const requestId = 'req-flow-1';
  const manifest = `id:${event.data?.id ?? event.id};request-id:${requestId};ts:${ts};`;
  const v1 = crypto.createHmac('sha256', secret).update(manifest).digest('hex');

  return {
    'x-request-id': requestId,
    'x-signature': `ts=${ts},v1=${v1}`,
  };
}

test('fluxo integrado: checkout -> confirmação -> entrega -> portal valida -> download', async () => {
  const draftOrder = {
    id: 'order-flow-1',
    shortId: 'FLOW0001',
    status: 'Created',
    currency: 'BRL',
    totalAmountCents: 5000,
  };

  const paymentProvider = {
    name: 'mercadopago',
    async createPaymentIntent(payload) {
      return {
        provider: 'mercadopago',
        providerIntentId: 'pi-flow-1',
        externalReference: payload.externalReference,
        checkoutUrl: 'https://sandbox.mercadopago.com/checkout/flow-1',
        status: 'pending',
      };
    },
  };

  // Selecionar fotos e seguir para checkout: neste fluxo o pedido já reflete os itens selecionados
  // em totalAmountCents e entra no serviço de pagamento.
  const checkout = await createOrderPaymentIntent(draftOrder, paymentProvider);
  assert.equal(checkout.order.status, 'AwaitingPayment');
  assert.match(checkout.paymentIntent.checkoutUrl, /^https:\/\/sandbox\.mercadopago/);

  const orderWithCheckout = {
    ...checkout.order,
    externalReference: checkout.paymentIntent.externalReference,
  };

  const ordersStore = new InMemoryOrdersStore(orderWithCheckout);
  const paymentEventsStore = new InMemoryPaymentEventsStore();

  const secret = 'sandbox-secret';
  const paidEvent = {
    id: 'evt-flow-paid-1',
    status: 'approved',
    external_reference: orderWithCheckout.externalReference,
  };

  const paidResult = await webhookMercadoPago(paidEvent, {
    secret,
    headers: buildMercadoPagoHeaders(secret, paidEvent),
    paymentEventsStore,
    ordersStore,
  });

  assert.equal(paidResult.accepted, true);
  assert.equal(paidResult.status, 'order_updated');
  assert.equal(ordersStore.order.status, 'Paid');

  const delivered = await finalizeOrderDelivery({
    orderId: ordersStore.order.id,
    expirationDays: 7,
    assets: [{ fileName: 'photo-1.jpg', base64Data: Buffer.from('image-1').toString('base64') }],
    ordersStore,
    async uploadAssets() {
      return [{ fileName: 'photo-1.jpg', path: 'galleries/order-flow-1/photo-1.jpg' }];
    },
  });

  assert.equal(delivered.ok, true);
  assert.equal(ordersStore.order.status, 'Delivered');

  const portalValidation = await validateAccessEndpoint(
    {
      method: 'POST',
      body: {
        orderId: ordersStore.order.id,
        code: delivered.code,
      },
    },
    {
      ordersStore,
      async signDownloadUrl({ path, expiresInSeconds }) {
        return `https://sandbox.download/${path}?exp=${expiresInSeconds}`;
      },
    },
  );

  assert.equal(portalValidation.status, 200);
  assert.equal(portalValidation.body.ok, true);
  assert.equal(portalValidation.body.assets.length, 1);
  assert.match(portalValidation.body.assets[0].signedDownloadUrl, /^https:\/\/sandbox\.download\//);
});
