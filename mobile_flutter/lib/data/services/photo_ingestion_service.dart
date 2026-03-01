import 'dart:io';

import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PhotoIngestionService {
  PhotoIngestionService({
    required AppDatabase database,
    ImagePicker? imagePicker,
  })  : _database = database,
        _imagePicker = imagePicker ?? ImagePicker();

  final AppDatabase _database;
  final ImagePicker _imagePicker;

  static const Set<String> _supportedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.heic',
    '.webp',
  };

  Future<PhotoIngestionResult> ingestFromFolder({
    required Directory directory,
    DateTime? sinceCapturedAt,
  }) async {
    if (!await directory.exists()) {
      return const PhotoIngestionResult();
    }

    final existingChecksums = await _loadChecksums();
    final candidates = <IngestionCandidate>[];

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !_isSupported(entity.path)) {
        continue;
      }

      final stat = await entity.stat();
      final capturedAt = stat.modified;
      if (sinceCapturedAt != null && !capturedAt.isAfter(sinceCapturedAt)) {
        continue;
      }

      final checksum = await _checksumForFile(entity);
      if (existingChecksums.contains(checksum)) {
        continue;
      }

      existingChecksums.add(checksum);
      candidates.add(
        IngestionCandidate(
          file: entity,
          capturedAt: capturedAt,
          checksum: checksum,
        ),
      );
    }

    return _persistCandidates(candidates);
  }

  Future<PhotoIngestionResult> ingestFromManualPicker() async {
    final picked = await _imagePicker.pickMultipleMedia(
      imageQuality: 95,
      requestFullMetadata: true,
    );

    if (picked.isEmpty) {
      return const PhotoIngestionResult();
    }

    return ingestExternalFiles(
      picked.map((xfile) => File(xfile.path)).toList(growable: false),
    );
  }

  Future<PhotoIngestionResult> ingestExternalFiles(List<File> sharedFiles) async {
    final existingChecksums = await _loadChecksums();
    final candidates = <IngestionCandidate>[];

    for (final file in sharedFiles) {
      if (!await file.exists() || !_isSupported(file.path)) {
        continue;
      }

      final checksum = await _checksumForFile(file);
      if (existingChecksums.contains(checksum)) {
        continue;
      }

      final stat = await file.stat();
      existingChecksums.add(checksum);
      candidates.add(
        IngestionCandidate(
          file: file,
          capturedAt: stat.modified,
          checksum: checksum,
        ),
      );
    }

    return _persistCandidates(candidates);
  }

  @visibleForTesting
  static List<IngestionCandidate> deduplicateAndSortCandidates(
    List<IngestionCandidate> candidates,
  ) {
    final byChecksum = <String, IngestionCandidate>{};

    for (final candidate in candidates) {
      final current = byChecksum[candidate.checksum];
      if (current == null || candidate.capturedAt.isAfter(current.capturedAt)) {
        byChecksum[candidate.checksum] = candidate;
      }
    }

    final sorted = byChecksum.values.toList(growable: false)
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return sorted;
  }

  Future<PhotoIngestionResult> _persistCandidates(
    List<IngestionCandidate> rawCandidates,
  ) async {
    final candidates = PhotoIngestionService.deduplicateAndSortCandidates(rawCandidates);
    var inserted = 0;

    for (final candidate in candidates) {
      final id = _assetIdFor(candidate.capturedAt, candidate.checksum);

      final insertResult = await _database.into(_database.photoAssets).insert(
            PhotoAssetsCompanion.insert(
              id: id,
              localPath: candidate.file.path,
              thumbnailKey: _thumbnailKeyFor(candidate.file, candidate.checksum),
              capturedAt: candidate.capturedAt,
              checksum: candidate.checksum,
              uploadStatus: 'pending',
              storagePath: const Value.absent(),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      if (insertResult > 0) {
        inserted += 1;
      }
    }

    return PhotoIngestionResult(insertedCount: inserted);
  }

  Future<Set<String>> _loadChecksums() async {
    final rows = await (_database.selectOnly(_database.photoAssets)
          ..addColumns([_database.photoAssets.checksum]))
        .get();

    return rows
        .map((row) => row.read(_database.photoAssets.checksum) ?? '')
        .where((checksum) => checksum.isNotEmpty)
        .toSet();
  }

  Future<String> _checksumForFile(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  bool _isSupported(String path) {
    final lowercase = path.toLowerCase();
    return _supportedExtensions.any(lowercase.endsWith);
  }

  String _assetIdFor(DateTime capturedAt, String checksum) {
    final safe = checksum.substring(0, 12);
    return 'asset_${capturedAt.microsecondsSinceEpoch}_$safe';
  }

  String _thumbnailKeyFor(File file, String checksum) {
    final ext = file.path.split('.').last.toLowerCase();
    return 'thumb_${checksum.substring(0, 12)}.$ext';
  }
}

class PhotoIngestionResult {
  const PhotoIngestionResult({this.insertedCount = 0});

  final int insertedCount;
}

@visibleForTesting
class IngestionCandidate {
  const IngestionCandidate({
    required this.file,
    required this.capturedAt,
    required this.checksum,
  });

  final File file;
  final DateTime capturedAt;
  final String checksum;
}
