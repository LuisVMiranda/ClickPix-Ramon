/**
 * @typedef {Object} PaymentIntent
 * @property {string} provider
 * @property {string} providerIntentId
 * @property {string} status
 * @property {string|null} checkoutUrl
 * @property {string} externalReference
 * @property {number} amountCents
 * @property {string} currency
 * @property {string|null} [qrCodeText]
 * @property {string|null} [qrCodeBase64]
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
 *   orderId: string,
 *   payer?: {email?: string, firstName?: string, lastName?: string},
 *   methodData?: Record<string, unknown>
 * }) => Promise<PaymentIntent>} createPaymentIntent
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
