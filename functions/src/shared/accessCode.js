import crypto from 'node:crypto';
import argon2 from 'argon2';

const blocked = new Set([
  '000000',
  '123456',
  '111111',
  '222222',
  '333333',
  '444444',
  '555555',
  '666666',
  '777777',
  '888888',
  '999999',
  '121212',
  '101010',
  '112233',
  '654321',
]);

function isSequentialPattern(code) {
  let ascending = true;
  let descending = true;
  for (let i = 1; i < code.length; i += 1) {
    const prev = Number(code[i - 1]);
    const current = Number(code[i]);
    if (current !== (prev + 1) % 10) {
      ascending = false;
    }
    if (current !== (prev + 9) % 10) {
      descending = false;
    }
  }
  return ascending || descending;
}

function isMirroredPattern(code) {
  return code.slice(0, 3) === code.slice(3);
}

function isTrivialCode(code) {
  return blocked.has(code) || isSequentialPattern(code) || isMirroredPattern(code);
}

export function generateAccessCode() {
  while (true) {
    const num = crypto.randomInt(0, 1000000);
    const code = String(num).padStart(6, '0');
    if (!isTrivialCode(code)) return code;
  }
}

export async function hashAccessCode(code) {
  return argon2.hash(code);
}

export async function verifyAccessCode(hash, code) {
  return argon2.verify(hash, code);
}
