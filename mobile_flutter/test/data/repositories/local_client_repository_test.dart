import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_client_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalClientRepository', () {
    late AppDatabase database;
    late LocalClientRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = LocalClientRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('creates and lists clients', () async {
      await repository.createClient(
        id: 'client_1',
        name: 'Ana',
        whatsapp: '+5511999999999',
        email: 'ana@email.com',
      );

      final clients = await repository.listClients();
      expect(clients, hasLength(1));
      expect(clients.first.name, 'Ana');
      expect(clients.first.email, 'ana@email.com');
    });

    test('updates a client', () async {
      await repository.createClient(
        id: 'client_1',
        name: 'Ana',
        whatsapp: '+5511999999999',
      );

      await repository.updateClient(
        id: 'client_1',
        name: 'Ana Paula',
        whatsapp: '+5511888888888',
        email: 'ana.paula@email.com',
      );

      final clients = await repository.listClients();
      expect(clients, hasLength(1));
      expect(clients.first.name, 'Ana Paula');
      expect(clients.first.whatsapp, '+5511888888888');
      expect(clients.first.email, 'ana.paula@email.com');
    });

    test('deletes one client and can clear all', () async {
      await repository.createClient(
        id: 'client_1',
        name: 'Ana',
        whatsapp: '+5511999999999',
      );
      await repository.createClient(
        id: 'client_2',
        name: 'Bruno',
        whatsapp: '+5511777777777',
      );

      await repository.deleteClient('client_1');
      var clients = await repository.listClients();
      expect(clients, hasLength(1));
      expect(clients.first.id, 'client_2');

      await repository.deleteAllClients();
      clients = await repository.listClients();
      expect(clients, isEmpty);
    });
  });
}
