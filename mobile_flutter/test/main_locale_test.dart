import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClickPix locale flow', () {
    late AppDatabase database;
    late AppSettingsStore store;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      store = AppSettingsStore(database);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('inicializa em PT-BR, troca EN/ES e persiste após restart', (
      tester,
    ) async {
      final initialLocale = await store.loadLocale();
      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
          initialLocale: initialLocale,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atendimento Rápido'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();

      expect(find.text('Quick Service'), findsOneWidget);

      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES').last);
      await tester.pumpAndSettle();

      expect(find.text('Atención Rápida'), findsOneWidget);

      final persistedLocale = await store.loadLocale();
      expect(persistedLocale.languageCode, 'es');

      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
          initialLocale: persistedLocale,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atención Rápida'), findsOneWidget);
    });
  });
}
