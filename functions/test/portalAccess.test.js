import test from 'node:test';
import assert from 'node:assert/strict';
import {
  generateOrderAccessCode,
  renewOrderAccessCode,
  validateAccessEndpoint,
  validateOrderAccessCode,
} from '../src/index.js';

test('generateOrderAccessCode returns raw code plus stored access metadata only', async () => {
  const result = await generateOrderAccessCode('order-1', 3);

  assert.equal(result.orderId, 'order-1');
  assert.match(result.code, /^\d{6}$/);
  assert.ok(result.access.hash);
  assert.ok(result.access.expiresAt);
  assert.equal(result.access.version, 1);
  assert.equal('hash' in result, false);
  assert.equal('expiresAt' in result, false);
});

test('renewOrderAccessCode invalidates previous code and rotates hash', async () => {
  const created = await generateOrderAccessCode('order-2', 2);
  const renewed = await renewOrderAccessCode(created.access, 2);

  assert.notEqual(renewed.access.hash, created.access.hash);
  assert.equal(renewed.access.version, 2);
  assert.equal(Boolean(renewed.invalidated), true);

  const previousValidation = await validateOrderAccessCode(created.access, created.code);
  assert.equal(previousValidation.valid, true);

  const newValidation = await validateOrderAccessCode(renewed.access, renewed.code);
  assert.equal(newValidation.valid, true);

  const oldCodeAgainstNewHash = await validateOrderAccessCode(renewed.access, created.code);
  assert.equal(oldCodeAgainstNewHash.valid, false);
  assert.equal(oldCodeAgainstNewHash.reason, 'invalid_code');
});

test('validateAccessEndpoint returns signed temporary download URL when code is valid', async () => {
  const created = await generateOrderAccessCode('order-3', 2);
  const response = await validateAccessEndpoint(
    {
      method: 'POST',
      body: {
        orderId: 'order-3',
        code: created.code,
        assetPath: 'galleries/order-3/photo.jpg',
      },
    },
    {
      ordersStore: {
        async findById(id) {
          if (id !== 'order-3') {
            return null;
          }
          return { delivery: { galleryId: 'gallery-3', access: created.access } };
        },
      },
      async signDownloadUrl({ orderId, assetPath, expiresInSeconds }) {
        return `https://download.test/${orderId}/${assetPath}?ttl=${expiresInSeconds}`;
      },
    },
  );

  assert.equal(response.status, 200);
  assert.equal(response.body.ok, true);
  assert.equal(response.body.galleryId, 'gallery-3');
  assert.match(response.body.signedDownloadUrl, /^https:\/\/download\.test/);
});

test('validateAccessEndpoint distinguishes invalid code and expired code', async () => {
  const created = await generateOrderAccessCode('order-4', 2);
  const now = Date.now();
  const expired = {
    ...created.access,
    expiresAt: new Date(now - 1000).toISOString(),
  };

  const invalidCodeResponse = await validateAccessEndpoint(
    {
      method: 'POST',
      body: { orderId: 'order-4', code: '999999', assetPath: 'a.jpg' },
    },
    {
      ordersStore: {
        async findById() {
          return { delivery: { galleryId: 'gallery-4', access: created.access } };
        },
      },
    },
  );

  assert.equal(invalidCodeResponse.status, 401);
  assert.equal(invalidCodeResponse.body.reason, 'invalid_code');

  const expiredCodeResponse = await validateAccessEndpoint(
    {
      method: 'POST',
      body: { orderId: 'order-4', code: created.code, assetPath: 'a.jpg' },
    },
    {
      ordersStore: {
        async findById() {
          return { delivery: { galleryId: 'gallery-4', access: expired } };
        },
      },
    },
  );

  assert.equal(expiredCodeResponse.status, 410);
  assert.equal(expiredCodeResponse.body.reason, 'expired');
});
