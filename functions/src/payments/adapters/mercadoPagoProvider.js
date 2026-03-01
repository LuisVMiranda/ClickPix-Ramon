const mercadoPagoApiBase = process.env.MERCADOPAGO_API_BASE ?? 'https://api.mercadopago.com';

function authHeaders() {
  const token = process.env.MERCADOPAGO_ACCESS_TOKEN;
  if (!token) {
    throw new Error('MERCADOPAGO_ACCESS_TOKEN not configured');
  }

  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

/** @type {import('../paymentProvider.js').PaymentProvider} */
export const mercadoPagoProvider = {
  name: 'mercadopago',
  async createPaymentIntent({ amountCents, currency, externalReference, description, payer, methodData = {} }) {
    const paymentMethod = methodData.method ?? 'pix';
    const amount = Number((amountCents / 100).toFixed(2));

    const body = {
      transaction_amount: amount,
      description,
      external_reference: externalReference,
      payment_method_id: paymentMethod,
      payer: {
        email: payer?.email ?? process.env.MERCADOPAGO_DEFAULT_PAYER_EMAIL ?? 'buyer@clickpix.app',
        first_name: payer?.firstName ?? 'ClickPix',
        last_name: payer?.lastName ?? 'Buyer',
      },
    };

    if (paymentMethod !== 'pix') {
      body.token = methodData.cardToken;
      body.issuer_id = methodData.issuerId;
      body.installments = methodData.installments ?? 1;
    }

    const response = await fetch(`${mercadoPagoApiBase}/v1/payments`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Mercado Pago payment creation failed: ${response.status} ${errorText}`);
    }

    const result = await response.json();

    return {
      provider: this.name,
      providerIntentId: String(result.id),
      status: String(result.status ?? 'pending'),
      checkoutUrl: result.point_of_interaction?.transaction_data?.ticket_url ?? null,
      externalReference,
      amountCents,
      currency,
      qrCodeText: result.point_of_interaction?.transaction_data?.qr_code ?? null,
      qrCodeBase64: result.point_of_interaction?.transaction_data?.qr_code_base64 ?? null,
    };
  },
};
