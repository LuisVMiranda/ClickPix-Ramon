/** @type {import('../paymentProvider.js').PaymentProvider} */
export const mercadoPagoProvider = {
  name: 'mercadopago',
  async createPaymentIntent({ amountCents, currency, externalReference, orderId }) {
    return {
      provider: this.name,
      providerIntentId: `mp_${externalReference}`,
      status: 'pending',
      checkoutUrl: `https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=${orderId}`,
      externalReference,
      amountCents,
      currency,
    };
  },
};
