import test from 'node:test';
import assert from 'node:assert/strict';
import { generateAccessCode, hashAccessCode, verifyAccessCode } from '../src/shared/accessCode.js';

test('generateAccessCode returns 6 digits and avoids trivial', () => {
  const code = generateAccessCode();
  assert.equal(code.length, 6);
  assert.notEqual(code, '000000');
  assert.notEqual(code, '123456');
});

test('hash and verify access code', async () => {
  const code = generateAccessCode();
  const hash = await hashAccessCode(code);
  assert.equal(await verifyAccessCode(hash, code), true);
  assert.equal(await verifyAccessCode(hash, '999998'), false);
});
