import 'dart:io';

import 'package:clickpix_ramon/data/services/photo_ingestion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoIngestionService.deduplicateAndSortCandidates', () {
    test('mantém apenas o item mais novo por checksum', () {
      final older = IngestionCandidate(
        file: File('a.jpg'),
        capturedAt: DateTime(2026, 1, 1, 10),
        checksum: 'dup',
      );
      final newest = IngestionCandidate(
        file: File('b.jpg'),
        capturedAt: DateTime(2026, 1, 1, 11),
        checksum: 'dup',
      );

      final result = PhotoIngestionService.deduplicateAndSortCandidates([
        older,
        newest,
      ]);

      expect(result, hasLength(1));
      expect(result.single.file.path, 'b.jpg');
    });

    test('ordena por capturedAt em ordem decrescente', () {
      final oldest = IngestionCandidate(
        file: File('old.jpg'),
        capturedAt: DateTime(2026, 1, 1, 9),
        checksum: 'a',
      );
      final middle = IngestionCandidate(
        file: File('mid.jpg'),
        capturedAt: DateTime(2026, 1, 1, 10),
        checksum: 'b',
      );
      final newest = IngestionCandidate(
        file: File('new.jpg'),
        capturedAt: DateTime(2026, 1, 1, 11),
        checksum: 'c',
      );

      final result = PhotoIngestionService.deduplicateAndSortCandidates([
        middle,
        oldest,
        newest,
      ]);

      expect(result.map((item) => item.file.path).toList(), [
        'new.jpg',
        'mid.jpg',
        'old.jpg',
      ]);
    });
  });
}
