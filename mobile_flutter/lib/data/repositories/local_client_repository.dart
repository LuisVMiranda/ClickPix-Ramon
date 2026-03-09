import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/domain/repositories/client_repository.dart';
import 'package:drift/drift.dart';

class LocalClientRepository implements ClientRepository {
  final AppDatabase _database;

  LocalClientRepository(this._database);

  @override
  Future<void> createClient({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
  }) async {
    await _database.into(_database.clients).insert(
          ClientsCompanion.insert(
            id: id,
            name: name,
            whatsapp: whatsapp,
            email: email == null ? const Value.absent() : Value(email),
          ),
        );
  }

  Future<List<ClientSummary>> listClients() async {
    final rows = await (_database.select(_database.clients)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();

    return rows
        .map(
          (row) => ClientSummary(
            id: row.id,
            name: row.name,
            whatsapp: row.whatsapp,
            email: row.email,
          ),
        )
        .toList(growable: false);
  }

  Future<void> updateClient({
    required String id,
    required String name,
    required String whatsapp,
    String? email,
  }) async {
    await (_database.update(_database.clients)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      ClientsCompanion(
        name: Value(name),
        whatsapp: Value(whatsapp),
        email: Value(email),
      ),
    );
  }

  Future<void> deleteClient(String id) async {
    await (_database.delete(_database.clients)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  Future<void> deleteAllClients() async {
    await _database.delete(_database.clients).go();
  }
}

class ClientSummary {
  const ClientSummary({
    required this.id,
    required this.name,
    required this.whatsapp,
    this.email,
  });

  final String id;
  final String name;
  final String whatsapp;
  final String? email;
}
