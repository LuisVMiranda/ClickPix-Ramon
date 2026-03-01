import 'dart:convert';

import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';

class LocalPhotoAssetRepository {
  LocalPhotoAssetRepository(this._database);

  final AppDatabase _database;

  Future<void> persistAssets(List<AssetEntity> assets) async {
    for (final asset in assets) {
      final capturedAt = asset.createDateTime;
      final checksum = _checksumForAsset(asset);

      await _database.into(_database.photoAssets).insert(
            PhotoAssetsCompanion.insert(
              id: _assetRowId(asset),
              localPath: _localPath(asset),
              thumbnailKey: 'thumb_${asset.id}',
              capturedAt: capturedAt,
              checksum: checksum,
              uploadStatus: 'local',
              storagePath: const Value.absent(),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  String _assetRowId(AssetEntity asset) => 'asset_${asset.id}';

  String _localPath(AssetEntity asset) => 'asset://${asset.id}';

  String _checksumForAsset(AssetEntity asset) {
    final payload = jsonEncode({
      'id': asset.id,
      'w': asset.width,
      'h': asset.height,
      'd': asset.duration,
      'c': asset.createDateSecond,
      'm': asset.modifiedDateSecond,
      't': asset.typeInt,
    });
    return base64Url.encode(utf8.encode(payload));
  }
}
