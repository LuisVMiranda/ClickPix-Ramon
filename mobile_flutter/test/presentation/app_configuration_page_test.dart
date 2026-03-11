import 'package:clickpix_ramon/core/settings/app_settings_store.dart';
import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfigurationPage', () {
    late AppDatabase database;
    late AppSettingsStore store;
    late AppVisualSettings lastVisualSettings;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      store = AppSettingsStore(database);
      lastVisualSettings = const AppVisualSettings();
    });

    tearDown(() async {
      await database.close();
    });

    Future<void> pumpConfigurationPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppConfigurationPage(
            settingsStore: store,
            locale: const Locale('pt', 'BR'),
            visualSettings: const AppVisualSettings(),
            backgroundSettings: const AppBackgroundSettings(),
            onLocaleChanged: (_) async {},
            onVisualSettingsChanged: (settings) async {
              lastVisualSettings = settings;
            },
            onBackgroundSettingsChanged: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> addCombo(
      WidgetTester tester, {
      required String name,
      required String minimumPhotos,
      required String unitPrice,
    }) async {
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Adicionar combo'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Adicionar combo'));
      await tester.pumpAndSettle();

      final editorScaffold = find.ancestor(
        of: find.text('Novo combo'),
        matching: find.byType(Scaffold),
      );
      final editorFields = find.descendant(
        of: editorScaffold,
        matching: find.byType(TextField),
      );

      await tester.enterText(editorFields.at(0), name);
      await tester.enterText(editorFields.at(1), minimumPhotos);
      await tester.enterText(editorFields.at(2), unitPrice);
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();
    }

    testWidgets('adds two combos and edits one without exceptions',
        (tester) async {
      await pumpConfigurationPage(tester);

      await addCombo(
        tester,
        name: 'Combo 1',
        minimumPhotos: '5',
        unitPrice: '5.00',
      );
      expect(find.text('Combo 1'), findsOneWidget);

      await addCombo(
        tester,
        name: 'Combo 2',
        minimumPhotos: '10',
        unitPrice: '4.50',
      );
      expect(find.text('Combo 2'), findsOneWidget);

      final combo2Tile = find.ancestor(
        of: find.text('Combo 2'),
        matching: find.byType(ListTile),
      );
      final editButton = find.descendant(
        of: combo2Tile,
        matching: find.byIcon(Icons.edit),
      );

      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      final editorScaffold = find.ancestor(
        of: find.text('Editar combo'),
        matching: find.byType(Scaffold),
      );
      final editorFields = find.descendant(
        of: editorScaffold,
        matching: find.byType(TextField),
      );
      await tester.enterText(editorFields.at(0), 'Combo 2 VIP');
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(find.text('Combo 2 VIP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows new color families without shade chips', (tester) async {
      await pumpConfigurationPage(tester);

      expect(find.text('Cinza'), findsOneWidget);
      expect(find.text('Vermelho'), findsOneWidget);
      expect(find.text('Marrom'), findsOneWidget);
      expect(find.text('Turquesa'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Cinza'));
      await tester.pumpAndSettle();
      expect(lastVisualSettings.accentColorKey, 'gray_mid');
      expect(find.widgetWithText(ChoiceChip, 'Claro'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Médio'), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'Escuro'), findsNothing);
    });
  });
}
