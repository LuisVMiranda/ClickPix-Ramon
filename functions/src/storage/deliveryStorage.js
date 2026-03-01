import crypto from 'node:crypto';
import { getStorage } from 'firebase-admin/storage';

function normalizeAssetName(asset = {}, index = 0) {
  const explicit = String(asset.fileName ?? '').trim();
  if (explicit) {
    return explicit;
  }

  const downloadUrl = String(asset.downloadUrl ?? '').trim();
  if (downloadUrl) {
    const parsed = new URL(downloadUrl);
    const raw = decodeURIComponent(parsed.pathname.split('/').pop() ?? '').trim();
    if (raw) {
      return raw;
    }
  }

  return `photo-${String(index + 1).padStart(3, '0')}.jpg`;
}

function toBuffer(asset = {}) {
  const base64Data = String(asset.base64Data ?? '').trim();
  if (!base64Data) {
    return null;
  }

  const withoutPrefix = base64Data.includes(',') ? base64Data.split(',').pop() : base64Data;
  return Buffer.from(withoutPrefix, 'base64');
}

export function createStoragePrefix(orderId) {
  return `galleries/${orderId}/`;
}

export async function deliverOrderAssets({
  orderId,
  storagePrefix,
  assets = [],
  bucketName = process.env.FIREBASE_STORAGE_BUCKET,
  uploadFromUrl = async (asset) => {
    const response = await fetch(asset.downloadUrl);
    if (!response.ok) {
      throw new Error(`download_failed:${response.status}`);
    }
    return Buffer.from(await response.arrayBuffer());
  },
}) {
  if (!assets.length) {
    return [];
  }

  const bucket = getStorage().bucket(bucketName);
  const uploaded = [];

  for (const [index, asset] of assets.entries()) {
    const fileName = normalizeAssetName(asset, index);
    const fullPath = `${storagePrefix}${fileName}`;

    let content = toBuffer(asset);
    if (!content && asset.downloadUrl) {
      content = await uploadFromUrl(asset);
    }
    if (!content) {
      continue;
    }

    const checksum = crypto.createHash('sha1').update(content).digest('hex');
    const file = bucket.file(fullPath);
    await file.save(content, {
      resumable: false,
      metadata: {
        contentType: asset.contentType ?? 'image/jpeg',
      },
    });

    uploaded.push({
      fileName,
      path: fullPath,
      checksum,
      size: content.length,
    });
  }

  return uploaded;
}

export async function listGalleryAssets({
  storagePrefix,
  fallbackAssets = [],
  bucketName = process.env.FIREBASE_STORAGE_BUCKET,
}) {
  if (!storagePrefix) {
    return fallbackAssets ?? [];
  }

  try {
    const bucket = getStorage().bucket(bucketName);
    const [files] = await bucket.getFiles({ prefix: storagePrefix });
    const filtered = files.filter((file) => file.name !== storagePrefix);
    if (!filtered.length) {
      return fallbackAssets ?? [];
    }

    return filtered.map((file) => ({
      fileName: file.name.replace(storagePrefix, ''),
      path: file.name,
    }));
  } catch {
    return fallbackAssets ?? [];
  }
}

export async function signDownloadUrl({ path, expiresInSeconds }) {
  const bucket = getStorage().bucket(process.env.FIREBASE_STORAGE_BUCKET);
  const [url] = await bucket.file(path).getSignedUrl({
    action: 'read',
    expires: Date.now() + expiresInSeconds * 1000,
  });
  return url;
}

export async function buildGalleryDownloadItems({
  orderId,
  assets = [],
  expiresInSeconds = 300,
  signDownloadUrl: sign,
}) {
  return Promise.all(
    assets.map(async (asset) => ({
      fileName: asset.fileName,
      path: asset.path,
      signedDownloadUrl: await sign({
        orderId,
        assetPath: asset.path,
        path: asset.path,
        expiresInSeconds,
      }),
    })),
  );
}
