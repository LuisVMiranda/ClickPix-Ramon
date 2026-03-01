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

function mpHeaders(secret, event) {
  const ts = '1700000000';
  const requestId = 'req-abc';
  const manifest = `id:${event.data?.id ?? event.id};request-id:${requestId};ts:${ts};`;
  const v1 = crypto.createHmac('sha256', secret).update(manifest).digest('hex');
  return {
    'x-request-id': requestId,
    'x-signature': `ts=${ts},v1=${v1}`,
  };
}

test('webhook rejects duplicated providerEventId using payment_events collection semantics', async () => {
  const secret = 'very-secret';
  const event = {
    id: 'evt-dup-1',
    status: 'approved',
    external_reference: 'EXT-100',
  };

  const paymentEventsStore = new InMemoryPaymentEventsStore();
  const ordersStore = new InMemoryOrdersStore({
    id: 'order-100',
    externalReference: 'EXT-100',
    status: 'AwaitingPayment',
  });

  const headers = mpHeaders(secret, event);
  const first = await webhookMercadoPago(event, {
    secret,
    headers,
    paymentEventsStore,
    ordersStore,
  });

  const second = await webhookMercadoPago(event, {
    secret,
    headers,
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

  const paidResult = await webhookMercadoPago(paidEvent, {
    secret,
    headers: mpHeaders(secret, paidEvent),
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

  const lateResult = await webhookMercadoPago(latePendingEvent, {
    secret,
    headers: mpHeaders(secret, latePendingEvent),
    paymentEventsStore,
    ordersStore,
  });

  assert.equal(lateResult.accepted, true);
  assert.equal(lateResult.status, 'ignored_invalid_transition');
  assert.equal(lateResult.orderStatus, 'Paid');
  assert.equal(lateResult.attemptedStatus, 'AwaitingPayment');
  assert.equal(ordersStore.order.status, 'Paid');
});
