import { FieldValue } from 'firebase-admin/firestore';

export class FirestoreOrdersStore {
  constructor(firestore) {
    this.firestore = firestore;
  }

  async findById(orderId) {
    const snap = await this.firestore.collection('orders').doc(orderId).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
  }

  async findByExternalReference(externalReference) {
    const querySnap = await this.firestore
      .collection('orders')
      .where('externalReference', '==', externalReference)
      .limit(1)
      .get();

    if (querySnap.empty) {
      return null;
    }

    const doc = querySnap.docs[0];
    return { id: doc.id, ...doc.data() };
  }

  async updateStatus(orderId, status, { providerStatus } = {}) {
    const payload = {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (providerStatus) {
      payload.payment = {
        status: providerStatus,
      };
    }

    await this.firestore.collection('orders').doc(orderId).set(payload, {
      merge: true,
    });
  }

  async savePaymentIntent(orderId, paymentIntent) {
    await this.firestore.collection('orders').doc(orderId).set(
      {
        externalReference: paymentIntent.externalReference,
        payment: {
          provider: paymentIntent.provider,
          providerIntentId: paymentIntent.providerIntentId,
          checkoutUrl: paymentIntent.checkoutUrl ?? null,
          qrCodeBase64: paymentIntent.qrCodeBase64 ?? null,
          qrCodeText: paymentIntent.qrCodeText ?? null,
          status: paymentIntent.status,
        },
        status: 'AwaitingPayment',
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  async saveSyncedOrder(orderId, orderPayload) {
    const payload = {
      ...orderPayload,
      updatedAt: FieldValue.serverTimestamp(),
    };

    await this.firestore.collection('orders').doc(orderId).set(payload, {
      merge: true,
    });
  }

  async saveDelivery(orderId, delivery) {
    await this.firestore.collection('orders').doc(orderId).set(
      {
        delivery,
        status: 'Delivered',
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}

export class FirestorePaymentEventsStore {
  constructor(firestore) {
    this.firestore = firestore;
  }

  async has(providerEventId) {
    const snap = await this.firestore.collection('payment_events').doc(providerEventId).get();
    return snap.exists;
  }

  async insert(providerEventId, payload = {}) {
    await this.firestore.collection('payment_events').doc(providerEventId).create({
      providerEventId,
      receivedAt: FieldValue.serverTimestamp(),
      ...payload,
    });
  }
}
