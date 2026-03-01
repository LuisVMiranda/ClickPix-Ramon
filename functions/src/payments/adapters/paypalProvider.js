const payPalApiBase = process.env.PAYPAL_API_BASE ?? 'https://api-m.paypal.com';

async function getAccessToken() {
  const clientId = process.env.PAYPAL_CLIENT_ID;
  const clientSecret = process.env.PAYPAL_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error('PAYPAL_CLIENT_ID/PAYPAL_CLIENT_SECRET not configured');
  }

  const basic = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const response = await fetch(`${payPalApiBase}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${basic}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!response.ok) {
    throw new Error(`PayPal OAuth failed with status ${response.status}`);
  }

  const result = await response.json();
  return result.access_token;
}

/** @type {import('../paymentProvider.js').PaymentProvider} */
export const payPalProvider = {
  name: 'paypal',
  async createPaymentIntent({ amountCents, currency, externalReference, description }) {
    const accessToken = await getAccessToken();
    const amount = Number((amountCents / 100).toFixed(2)).toFixed(2);

    const response = await fetch(`${payPalApiBase}/v2/checkout/orders`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        intent: 'CAPTURE',
        purchase_units: [
          {
            reference_id: externalReference,
            description,
            amount: {
              currency_code: currency,
              value: amount,
            },
          },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`PayPal order creation failed: ${response.status} ${errorText}`);
    }

    const result = await response.json();
    const approveLink = result.links?.find((link) => link.rel === 'approve')?.href ?? null;

    return {
      provider: this.name,
      providerIntentId: String(result.id),
      status: String(result.status ?? 'CREATED').toLowerCase(),
      checkoutUrl: approveLink,
      externalReference,
      amountCents,
      currency,
    };
  },
};

export async function verifyPayPalWebhook(rawBody, headers) {
  const accessToken = await getAccessToken();
  const webhookId = process.env.PAYPAL_WEBHOOK_ID;

  if (!webhookId) {
    throw new Error('PAYPAL_WEBHOOK_ID not configured');
  }

  const response = await fetch(`${payPalApiBase}/v1/notifications/verify-webhook-signature`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      transmission_id: headers['paypal-transmission-id'],
      transmission_time: headers['paypal-transmission-time'],
      cert_url: headers['paypal-cert-url'],
      auth_algo: headers['paypal-auth-algo'],
      transmission_sig: headers['paypal-transmission-sig'],
      webhook_id: webhookId,
      webhook_event: JSON.parse(rawBody),
    }),
  });

  if (!response.ok) {
    return false;
  }

  const result = await response.json();
  return result.verification_status === 'SUCCESS';
}
