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

    testWidgets('inicializa em PT-BR e persiste mudancas EN/ES apos restart',
        (tester) async {
      final initialLocale = await store.loadLocale();
      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
          initialLocale: initialLocale,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'admin');
      await tester.enterText(find.byType(TextField).at(1), 'admin123');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings).first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(DropdownButton<Locale>));
      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();

      final persistedEn = await store.loadLocale();
      expect(persistedEn.languageCode, 'en');

      await tester.ensureVisible(find.byType(DropdownButton<Locale>));
      await tester.tap(find.byType(DropdownButton<Locale>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES').last);
      await tester.pumpAndSettle();

      final persistedEs = await store.loadLocale();
      expect(persistedEs.languageCode, 'es');

      await tester.pumpWidget(
        ClickPixApp(
          appSettingsStore: store,
          database: database,
          initialLocale: persistedEs,
        ),
      );
      await tester.pumpAndSettle();

      final restartedLocale = await store.loadLocale();
      expect(restartedLocale.languageCode, 'es');
    });
  });
}
