import crypto from 'node:crypto';
import argon2 from 'argon2';

const blocked = new Set(['000000', '123456', '111111', '999999']);

export function generateAccessCode() {
  while (true) {
    const num = crypto.randomInt(0, 1000000);
    const code = String(num).padStart(6, '0');
    if (!blocked.has(code)) return code;
  }
}

export async function hashAccessCode(code) {
  return argon2.hash(code);
}

export async function verifyAccessCode(hash, code) {
  return argon2.verify(hash, code);
}
