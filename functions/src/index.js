import { generateAccessCode, hashAccessCode, verifyAccessCode } from './shared/accessCode.js';

export async function generateOrderAccessCode(orderId, expirationDays = 7) {
  const code = generateAccessCode();
  const hash = await hashAccessCode(code);
  const expiresAt = new Date(Date.now() + expirationDays * 86400000).toISOString();
  return { orderId, code, hash, expiresAt };
}

export async function validateOrderAccessCode(storedHash, typedCode, expiresAtISO) {
  if (new Date(expiresAtISO) < new Date()) return { valid: false, reason: 'expired' };
  const ok = await verifyAccessCode(storedHash, typedCode);
  return { valid: ok, reason: ok ? 'ok' : 'invalid_code' };
}

export async function webhookMercadoPago(event) {
  return { accepted: true, externalReference: event.external_reference ?? null };
}
