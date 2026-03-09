import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_client_repository.dart';
import 'package:clickpix_ramon/presentation/manage_contacts_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManageContactsPage', () {
    late AppDatabase database;
    late LocalClientRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = LocalClientRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('adds a contact and returns to the list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManageContactsPage(database: database),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar'));
      await tester.pumpAndSettle();

      final editorScaffold = find.ancestor(
        of: find.text('Novo contato'),
        matching: find.byType(Scaffold),
      );
      final editorFields = find.descendant(
        of: editorScaffold,
        matching: find.byType(TextField),
      );

      await tester.enterText(editorFields.at(0), 'Maria Silva');
      await tester.enterText(editorFields.at(1), '+5511999999999');
      await tester.enterText(editorFields.at(2), 'maria@email.com');

      await tester.tap(find.widgetWithText(FilledButton, 'Adicionar contato'));
      await tester.pumpAndSettle();

      expect(find.text('Maria Silva'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edits a contact and keeps accented save label',
        (tester) async {
      await repository.createClient(
        id: 'client_1',
        name: 'Carlos',
        whatsapp: '+5511888888888',
        email: 'carlos@email.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ManageContactsPage(database: database),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      expect(find.text('Salvar alterações'), findsOneWidget);

      final editorScaffold = find.ancestor(
        of: find.text('Editar contato'),
        matching: find.byType(Scaffold),
      );
      final editorFields = find.descendant(
        of: editorScaffold,
        matching: find.byType(TextField),
      );
      await tester.enterText(editorFields.at(0), 'Carlos Almeida');

      await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Almeida'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
