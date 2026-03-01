/**
 * @typedef {Object} PaymentIntent
 * @property {string} provider
 * @property {string} providerIntentId
 * @property {string} status
 * @property {string|null} checkoutUrl
 * @property {string} externalReference
 * @property {number} amountCents
 * @property {string} currency
 */

/**
 * Contract for payment providers.
 * @typedef {Object} PaymentProvider
 * @property {'mercadopago'|'paypal'} name
 * @property {(params: {
 *   amountCents: number,
 *   currency: string,
 *   externalReference: string,
 *   description?: string,
 *   orderId: string
 * }) => Promise<PaymentIntent>} createPaymentIntent
 */

/**
 * Runtime guard for adapter contract.
 * @param {unknown} provider
 */
export function assertPaymentProvider(provider) {
  if (!provider || typeof provider !== 'object') {
    throw new Error('Payment provider must be an object');
  }

  if (typeof provider.name !== 'string' || provider.name.length === 0) {
    throw new Error('Payment provider must expose a non-empty name');
  }

  if (typeof provider.createPaymentIntent !== 'function') {
    throw new Error('Payment provider must implement createPaymentIntent(params)');
  }
}
