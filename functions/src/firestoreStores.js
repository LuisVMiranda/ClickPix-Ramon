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

  async updateStatus(orderId, status) {
    await this.firestore.collection('orders').doc(orderId).set(
      {
        status,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
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
