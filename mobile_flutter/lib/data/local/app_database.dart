import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get whatsapp => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PhotoAssets extends Table {
  TextColumn get id => text()();
  TextColumn get localPath => text()();
  TextColumn get thumbnailKey => text()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get checksum => text().unique()();
  TextColumn get uploadStatus => text()();
  TextColumn get storagePath => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  IntColumn get totalAmountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('BRL'))();
  TextColumn get status => text()();
  TextColumn get paymentMethod => text()();
  TextColumn get externalReference => text().unique()();
  TextColumn get providerDataJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Clients, PhotoAssets, Orders])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
