import 'dart:io';

import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DeliveryShareService {
  DeliveryShareService(
    this._database, {
    DeliveryPlatformShareBridge? platformBridge,
  }) : _platformBridge = platformBridge ?? const DeliveryPlatformShareBridge();

  static const String emailSubject = 'Entrega de fotos - ClickPix';
  static const String _shareExportsDirectoryName = 'clickpix_share_exports';
  static const String _contactSpreadsheetPrefix = 'clickpix_contatos_';
  static const Duration defaultTemporaryFilesMaxAge = Duration(days: 3);

  final AppDatabase _database;
  final DeliveryPlatformShareBridge _platformBridge;

  Future<ResolvedDeliveryShareFiles> resolveOrderFiles(String orderId) async {
    await cleanupExpiredTemporaryFiles();

    final orderItems = await (_database.select(
      _database.orderItems,
    )..where((tbl) => tbl.orderId.equals(orderId)))
        .get();
    if (orderItems.isEmpty) {
      return const ResolvedDeliveryShareFiles(
        files: [],
        requestedCount: 0,
      );
    }

    final assetIds = orderItems.map((item) => item.photoAssetId).toSet();
    final assetRows = await (_database.select(
      _database.photoAssets,
    )..where((tbl) => tbl.id.isIn(assetIds)))
        .get();
    final assetsById = <String, PhotoAsset>{
      for (final row in assetRows) row.id: row,
    };

    var galleryPermissionState = PermissionState.notDetermined;
    var galleryPermissionChecked = false;
    final resolvedFiles = <XFile>[];
    final exportDirectory = await _createShareExportDirectory(orderId);
    var exportIndex = 1;

    for (final item in orderItems) {
      final assetRow = assetsById[item.photoAssetId];
      if (assetRow == null) {
        continue;
      }
      final file = await _resolveFileForAssetRow(
        assetRow,
        shouldCheckPermission: () async {
          if (galleryPermissionChecked) {
            return galleryPermissionState;
          }
          galleryPermissionChecked = true;
          try {
            galleryPermissionState =
                await PhotoManager.requestPermissionExtend();
          } on MissingPluginException {
            galleryPermissionState = PermissionState.denied;
          } on Object {
            galleryPermissionState = PermissionState.denied;
          }
          return galleryPermissionState;
        },
      );
      if (file == null) {
        continue;
      }
      final exportedFile = await _exportFileCopy(
        originalFile: file,
        exportDirectory: exportDirectory,
        exportIndex: exportIndex,
        fallbackId: assetRow.id,
      );
      exportIndex += 1;
      resolvedFiles.add(
        XFile(
          exportedFile.path,
          name: p.basename(exportedFile.path),
        ),
      );
    }

    return ResolvedDeliveryShareFiles(
      files: resolvedFiles,
      requestedCount: orderItems.length,
    );
  }

  Future<DeliveryTemporaryFilesSummary> inspectTemporaryFiles() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final shareExportsRoot = await _shareExportsRootDirectory();

    var fileCount = 0;
    var totalBytes = 0;

    if (await shareExportsRoot.exists()) {
      final stats = await _collectDirectoryStats(shareExportsRoot);
      fileCount += stats.fileCount;
      totalBytes += stats.totalBytes;
    }

    final spreadsheetStats = await _collectTempSpreadsheetStats(
      temporaryDirectory,
    );
    fileCount += spreadsheetStats.fileCount;
    totalBytes += spreadsheetStats.totalBytes;

    return DeliveryTemporaryFilesSummary(
      fileCount: fileCount,
      totalBytes: totalBytes,
    );
  }

  Future<DeliveryTemporaryFilesCleanupResult> clearTemporaryFiles() async {
    final summary = await inspectTemporaryFiles();
    final temporaryDirectory = await getTemporaryDirectory();
    final shareExportsRoot = await _shareExportsRootDirectory();

    if (await shareExportsRoot.exists()) {
      await shareExportsRoot.delete(recursive: true);
    }
    await _deleteTempSpreadsheets(temporaryDirectory);

    return DeliveryTemporaryFilesCleanupResult(
      deletedFileCount: summary.fileCount,
      deletedTotalBytes: summary.totalBytes,
    );
  }

  Future<void> cleanupExpiredTemporaryFiles({
    Duration maxAge = defaultTemporaryFilesMaxAge,
  }) async {
    final now = DateTime.now();
    final temporaryDirectory = await getTemporaryDirectory();
    final shareExportsRoot = await _shareExportsRootDirectory();

    if (await shareExportsRoot.exists()) {
      await for (final entity in shareExportsRoot.list(followLinks: false)) {
        final lastModified = await _lastModifiedOrNull(entity);
        if (lastModified == null || now.difference(lastModified) < maxAge) {
          continue;
        }
        await _deleteEntity(entity);
      }
    }

    await _deleteTempSpreadsheets(
      temporaryDirectory,
      olderThan: maxAge,
      now: now,
    );
  }

  Future<ResolvedDeliveryShareFiles> shareOrderViaWhatsApp({
    required String orderId,
    required String message,
  }) async {
    final resolved = await resolveOrderFiles(orderId);
    _ensureFilesAvailable(resolved);

    final openedNativeWhatsApp = await _platformBridge.shareToWhatsApp(
      filePaths: resolved.filePaths,
      text: message,
    );
    if (!openedNativeWhatsApp) {
      await Share.shareXFiles(
        resolved.files,
        subject: emailSubject,
        text: message,
      );
    }
    return resolved;
  }

  Future<ResolvedDeliveryShareFiles> shareOrderViaEmail({
    required String orderId,
    required String email,
    required String message,
  }) async {
    final resolved = await resolveOrderFiles(orderId);
    _ensureFilesAvailable(resolved);

    final openedNativeEmail = await _platformBridge.composeEmail(
      recipients: [email],
      subject: emailSubject,
      body: message,
      filePaths: resolved.filePaths,
    );
    if (!openedNativeEmail) {
      await Share.shareXFiles(
        resolved.files,
        subject: emailSubject,
        text: message,
      );
    }
    return resolved;
  }

  Future<ResolvedDeliveryShareFiles> shareOrderGenerically({
    required String orderId,
    required String message,
  }) async {
    final resolved = await resolveOrderFiles(orderId);
    _ensureFilesAvailable(resolved);
    await Share.shareXFiles(
      resolved.files,
      subject: emailSubject,
      text: message,
    );
    return resolved;
  }

  void _ensureFilesAvailable(ResolvedDeliveryShareFiles resolved) {
    if (resolved.files.isEmpty) {
      throw const DeliveryShareException(
        'No shareable files were found for this order.',
      );
    }
  }

  Future<File?> _resolveFileForAssetRow(
    PhotoAsset row, {
    required Future<PermissionState> Function() shouldCheckPermission,
  }) async {
    final localPath = row.localPath.trim();
    if (localPath.isEmpty) {
      return null;
    }
    if (!localPath.startsWith('asset://')) {
      final file = File(localPath);
      return await file.exists() ? file : null;
    }

    final permission = await shouldCheckPermission();
    if (!permission.isAuth) {
      return null;
    }

    final assetId = localPath.substring('asset://'.length).trim();
    if (assetId.isEmpty) {
      return null;
    }
    final entity = await AssetEntity.fromId(assetId);
    if (entity == null) {
      return null;
    }
    File? file;
    try {
      file = await entity.file;
    } on MissingPluginException {
      file = null;
    } on Object {
      file = null;
    }
    if (file == null) {
      return null;
    }
    return await file.exists() ? file : null;
  }

  Future<Directory> _shareExportsRootDirectory() async {
    final temporaryDirectory = await getTemporaryDirectory();
    return Directory(
      p.join(temporaryDirectory.path, _shareExportsDirectoryName),
    );
  }

  Future<Directory> _createShareExportDirectory(String orderId) async {
    final root = await _shareExportsRootDirectory();
    await root.create(recursive: true);
    final safeOrderId = _sanitizePathSegment(orderId);
    final exportDirectory = Directory(
      p.join(
          root.path, '${safeOrderId}_${DateTime.now().millisecondsSinceEpoch}'),
    );
    await exportDirectory.create(recursive: true);
    return exportDirectory;
  }

  Future<File> _exportFileCopy({
    required File originalFile,
    required Directory exportDirectory,
    required int exportIndex,
    required String fallbackId,
  }) async {
    final originalName = p.basename(originalFile.path).trim();
    final extension = p.extension(originalName).trim();
    final baseName = originalName.isEmpty
        ? 'foto_${exportIndex.toString().padLeft(3, '0')}'
        : p.basenameWithoutExtension(originalName);
    final safeBaseName = _sanitizePathSegment(
      baseName.isEmpty ? fallbackId : baseName,
    );
    final fileName =
        '${exportIndex.toString().padLeft(3, '0')}_$safeBaseName${extension.isEmpty ? '.jpg' : extension}';
    final targetFile = File(p.join(exportDirectory.path, fileName));
    return originalFile.copy(targetFile.path);
  }

  String _sanitizePathSegment(String rawValue) {
    final sanitized = rawValue
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
    if (sanitized.isEmpty) {
      return 'arquivo';
    }
    return sanitized;
  }

  Future<_DirectoryStats> _collectDirectoryStats(Directory directory) async {
    var fileCount = 0;
    var totalBytes = 0;

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      fileCount += 1;
      totalBytes += await entity.length();
    }

    return _DirectoryStats(fileCount: fileCount, totalBytes: totalBytes);
  }

  Future<_DirectoryStats> _collectTempSpreadsheetStats(
    Directory temporaryDirectory,
  ) async {
    var fileCount = 0;
    var totalBytes = 0;

    await for (final entity in temporaryDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final fileName = p.basename(entity.path);
      if (!fileName.startsWith(_contactSpreadsheetPrefix)) {
        continue;
      }
      fileCount += 1;
      totalBytes += await entity.length();
    }

    return _DirectoryStats(fileCount: fileCount, totalBytes: totalBytes);
  }

  Future<void> _deleteTempSpreadsheets(
    Directory temporaryDirectory, {
    Duration? olderThan,
    DateTime? now,
  }) async {
    await for (final entity in temporaryDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final fileName = p.basename(entity.path);
      if (!fileName.startsWith(_contactSpreadsheetPrefix)) {
        continue;
      }
      if (olderThan != null) {
        final lastModified = await _lastModifiedOrNull(entity);
        if (lastModified == null ||
            (now ?? DateTime.now()).difference(lastModified) < olderThan) {
          continue;
        }
      }
      await _deleteEntity(entity);
    }
  }

  Future<void> _deleteEntity(FileSystemEntity entity) async {
    try {
      await entity.delete(recursive: true);
    } on FileSystemException {
      // Ignore cleanup failures so sharing is never blocked by stale files.
    }
  }

  Future<DateTime?> _lastModifiedOrNull(FileSystemEntity entity) async {
    try {
      final stat = await entity.stat();
      return stat.modified;
    } on FileSystemException {
      return null;
    }
  }
}

class ResolvedDeliveryShareFiles {
  const ResolvedDeliveryShareFiles({
    required this.files,
    required this.requestedCount,
  });

  final List<XFile> files;
  final int requestedCount;

  int get resolvedCount => files.length;

  int get missingCount {
    final difference = requestedCount - resolvedCount;
    return difference < 0 ? 0 : difference;
  }

  List<String> get filePaths =>
      files.map((file) => file.path).toList(growable: false);
}

class DeliveryShareException implements Exception {
  const DeliveryShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeliveryTemporaryFilesSummary {
  const DeliveryTemporaryFilesSummary({
    required this.fileCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int totalBytes;

  bool get hasFiles => fileCount > 0;
}

class DeliveryTemporaryFilesCleanupResult {
  const DeliveryTemporaryFilesCleanupResult({
    required this.deletedFileCount,
    required this.deletedTotalBytes,
  });

  final int deletedFileCount;
  final int deletedTotalBytes;
}

class _DirectoryStats {
  const _DirectoryStats({
    required this.fileCount,
    required this.totalBytes,
  });

  final int fileCount;
  final int totalBytes;
}

class DeliveryPlatformShareBridge {
  const DeliveryPlatformShareBridge();

  static const MethodChannel _channel = MethodChannel(
    'clickpix_ramon/delivery_share',
  );

  Future<bool> shareToWhatsApp({
    required List<String> filePaths,
    required String text,
  }) async {
    if (!Platform.isAndroid || filePaths.isEmpty) {
      return false;
    }
    try {
      final opened = await _channel.invokeMethod<bool>('shareToWhatsApp', {
        'filePaths': filePaths,
        'text': text,
      });
      return opened == true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> composeEmail({
    required List<String> recipients,
    required String subject,
    required String body,
    required List<String> filePaths,
  }) async {
    if (!Platform.isAndroid || recipients.isEmpty || filePaths.isEmpty) {
      return false;
    }
    try {
      final opened = await _channel.invokeMethod<bool>('composeEmail', {
        'recipients': recipients,
        'subject': subject,
        'body': body,
        'filePaths': filePaths,
      });
      return opened == true;
    } on PlatformException {
      return false;
    }
  }
}
