import crypto from 'node:crypto';

function formatDateYYYYMMDD(date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, '0');
  const day = String(date.getUTCDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

function normalizeOrderShortId(orderShortId) {
  if (typeof orderShortId !== 'string' || orderShortId.trim().length === 0) {
    throw new Error('orderShortId must be a non-empty string');
  }
  return orderShortId.trim().replace(/[^a-zA-Z0-9]/g, '').slice(0, 12).toUpperCase();
}

function randomToken(size = 4) {
  return crypto.randomBytes(size).toString('hex').toUpperCase();
}

export function buildExternalReference(orderShortId, now = new Date()) {
  const normalizedShortId = normalizeOrderShortId(orderShortId);
  if (normalizedShortId.length === 0) {
    throw new Error('orderShortId must contain at least one alphanumeric character');
  }

  return `PFBR-${formatDateYYYYMMDD(now)}-${normalizedShortId}-${randomToken(4)}`;
}
