import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('aplica tema de alto contraste ao habilitar toggle', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final store = AppSettingsStore(database);

    await tester.pumpWidget(
      ClickPixApp(
        appSettingsStore: store,
        database: database,
      ),
    );
    await tester.pumpAndSettle();

    final materialBefore = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialBefore.theme?.colorScheme, isNot(const ColorScheme.highContrastLight()));

    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    final materialAfter = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialAfter.theme?.colorScheme, const ColorScheme.highContrastLight());

    final persisted = await store.loadVisualSettings();
    expect(persisted.highContrastEnabled, isTrue);

    await database.close();
  });
}
