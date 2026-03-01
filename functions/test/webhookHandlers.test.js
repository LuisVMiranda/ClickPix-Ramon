import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { webhookMercadoPago } from '../src/index.js';

class InMemoryPaymentEventsStore {
  constructor() {
    this.events = new Set();
  }

  async has(providerEventId) {
    return this.events.has(providerEventId);
  }

  async insert(providerEventId) {
    this.events.add(providerEventId);
  }
}

class InMemoryOrdersStore {
  constructor(order) {
    this.order = order;
  }

  async findByExternalReference(externalReference) {
    return this.order.externalReference === externalReference ? this.order : null;
  }

  async updateStatus(orderId, status) {
    if (this.order.id === orderId) {
      this.order = { ...this.order, status };
    }
  }
}

test('webhook rejects duplicated providerEventId using payment_events collection semantics', async () => {
  const secret = 'very-secret';
  const event = {
    id: 'evt-dup-1',
    status: 'approved',
    external_reference: 'EXT-100',
  };
  const rawBody = JSON.stringify(event);
  const signature = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');

  const paymentEventsStore = new InMemoryPaymentEventsStore();
  const ordersStore = new InMemoryOrdersStore({
    id: 'order-100',
    externalReference: 'EXT-100',
    status: 'AwaitingPayment',
  });

  const first = await webhookMercadoPago(event, {
    rawBody,
    signature,
    secret,
    paymentEventsStore,
    ordersStore,
  });

  const second = await webhookMercadoPago(event, {
    rawBody,
    signature,
    secret,
    paymentEventsStore,
    ordersStore,
  });

  assert.equal(first.accepted, true);
  assert.equal(first.duplicate, false);
  assert.equal(first.status, 'order_updated');
  assert.equal(ordersStore.order.status, 'Paid');

  assert.equal(second.accepted, true);
  assert.equal(second.duplicate, true);
  assert.equal(second.status, 'ignored');
  assert.equal(ordersStore.order.status, 'Paid');
});

test('webhook out of order does not break state machine transitions', async () => {
  const secret = 'very-secret';
  const paymentEventsStore = new InMemoryPaymentEventsStore();
  const ordersStore = new InMemoryOrdersStore({
    id: 'order-200',
    externalReference: 'EXT-200',
    status: 'AwaitingPayment',
  });

  const paidEvent = {
    id: 'evt-paid-200',
    status: 'approved',
    external_reference: 'EXT-200',
  };
  const paidRawBody = JSON.stringify(paidEvent);
  const paidSignature = crypto.createHmac('sha256', secret).update(paidRawBody).digest('hex');

  const paidResult = await webhookMercadoPago(paidEvent, {
    rawBody: paidRawBody,
    signature: paidSignature,
    secret,
    paymentEventsStore,
    ordersStore,
  });

  assert.equal(paidResult.status, 'order_updated');
  assert.equal(ordersStore.order.status, 'Paid');

  const latePendingEvent = {
    id: 'evt-pending-200',
    status: 'pending',
    external_reference: 'EXT-200',
  };
  const lateRawBody = JSON.stringify(latePendingEvent);
  const lateSignature = crypto.createHmac('sha256', secret).update(lateRawBody).digest('hex');

  const lateResult = await webhookMercadoPago(latePendingEvent, {
    rawBody: lateRawBody,
    signature: lateSignature,
    secret,
    paymentEventsStore,
    ordersStore,
  });

  assert.equal(lateResult.accepted, true);
  assert.equal(lateResult.status, 'ignored_invalid_transition');
  assert.equal(lateResult.orderStatus, 'Paid');
  assert.equal(lateResult.attemptedStatus, 'AwaitingPayment');
  assert.equal(ordersStore.order.status, 'Paid');
});
