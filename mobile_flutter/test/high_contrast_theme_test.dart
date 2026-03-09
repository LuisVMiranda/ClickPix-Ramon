import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('aplica tema de alto contraste ao habilitar toggle',
      (tester) async {
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
    expect(materialBefore.theme?.colorScheme,
        isNot(const ColorScheme.highContrastLight()));

    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'admin123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Alto contraste'));
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    final materialAfter = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialAfter.theme?.colorScheme.primary,
        const ColorScheme.highContrastLight().primary);

    final persisted = await store.loadVisualSettings();
    expect(persisted.highContrastEnabled, isTrue);

    await database.close();
  });
}
