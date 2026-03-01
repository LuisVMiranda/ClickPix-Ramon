import test from 'node:test';
import assert from 'node:assert/strict';
import { generateAccessCode, hashAccessCode, verifyAccessCode } from '../src/shared/accessCode.js';

test('generateAccessCode returns 6 digits and avoids trivial patterns', () => {
  for (let i = 0; i < 500; i += 1) {
    const code = generateAccessCode();
    assert.match(code, /^\d{6}$/);
    assert.notEqual(code, '000000');
    assert.notEqual(code, '123456');
    assert.notEqual(code, '654321');
    assert.notEqual(code.slice(0, 3), code.slice(3));
  }
});

test('hash and verify access code', async () => {
  const code = generateAccessCode();
  const hash = await hashAccessCode(code);
  assert.equal(await verifyAccessCode(hash, code), true);
  assert.equal(await verifyAccessCode(hash, '999998'), false);
});
