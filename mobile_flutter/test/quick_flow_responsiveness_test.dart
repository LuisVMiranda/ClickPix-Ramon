import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickFlow responsividade', () {
    late AppDatabase database;
    late AppSettingsStore store;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      store = AppSettingsStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('não apresenta overflow em telas pequenas', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where(
            (error) => error.exceptionAsString().contains('A RenderFlex overflowed'),
          )
          .toList();

      expect(overflowErrors, isEmpty);
    });

    testWidgets('não apresenta overflow em landscape compacto', (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.binding.setSurfaceSize(const Size(568, 320));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      final overflowErrors = errors
          .where(
            (error) => error.exceptionAsString().contains('A RenderFlex overflowed'),
          )
          .toList();

      expect(overflowErrors, isEmpty);
    });
  });
}
