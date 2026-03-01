import test from 'node:test';
import assert from 'node:assert/strict';
import {
  finalizeOrderDelivery,
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

test('validateAccessEndpoint returns signed temporary download URLs when code is valid', async () => {
  const created = await generateOrderAccessCode('order-3', 2);
  const response = await validateAccessEndpoint(
    {
      method: 'POST',
      body: {
        orderId: 'order-3',
        code: created.code,
      },
    },
    {
      ordersStore: {
        async findById(id) {
          if (id !== 'order-3') {
            return null;
          }
          return {
            delivery: {
              galleryId: 'gallery-3',
              access: created.access,
              assets: [{ fileName: 'photo.jpg', path: 'galleries/order-3/photo.jpg' }],
            },
          };
        },
      },
      async signDownloadUrl({ path, expiresInSeconds }) {
        return `https://download.test/${path}?ttl=${expiresInSeconds}`;
      },
    },
  );

  assert.equal(response.status, 200);
  assert.equal(response.body.ok, true);
  assert.equal(response.body.galleryId, 'gallery-3');
  assert.equal(response.body.assets.length, 1);
  assert.match(response.body.assets[0].signedDownloadUrl, /^https:\/\/download\.test/);
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
      body: { orderId: 'order-4', code: '999999' },
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
      body: { orderId: 'order-4', code: created.code },
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

test('finalizeOrderDelivery persists hash metadata, storage prefix and uploaded assets', async () => {
  const saved = [];

  const result = await finalizeOrderDelivery({
    orderId: 'order-55',
    expirationDays: 5,
    assets: [{ fileName: 'x.jpg', base64Data: Buffer.from('img').toString('base64') }],
    ordersStore: {
      async findById() {
        return { id: 'order-55', delivery: { galleryId: 'gallery-55' } };
      },
      async saveDelivery(orderId, delivery) {
        saved.push({ orderId, delivery });
      },
    },
    async uploadAssets() {
      return [{ fileName: 'x.jpg', path: 'galleries/order-55/x.jpg' }];
    },
  });

  assert.equal(result.ok, true);
  assert.match(result.code, /^\d{6}$/);
  assert.equal(result.storagePrefix, 'galleries/order-55/');
  assert.equal(saved.length, 1);
  assert.equal(saved[0].delivery.storagePrefix, 'galleries/order-55/');
  assert.ok(saved[0].delivery.access.hash);
  assert.ok(saved[0].delivery.access.expiresAt);
  assert.equal(saved[0].delivery.access.version, 1);
});
