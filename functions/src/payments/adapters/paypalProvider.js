/** @type {import('../paymentProvider.js').PaymentProvider} */
export const payPalProvider = {
  name: 'paypal',
  async createPaymentIntent({ amountCents, currency, externalReference, orderId }) {
    return {
      provider: this.name,
      providerIntentId: `pp_${externalReference}`,
      status: 'pending',
      checkoutUrl: `https://www.paypal.com/checkoutnow?token=${orderId}`,
      externalReference,
      amountCents,
      currency,
    };
  },
};
