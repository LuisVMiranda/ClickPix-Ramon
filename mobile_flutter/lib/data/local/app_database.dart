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
  List<Index> get indexes => [
    Index('photo_assets_captured_at_idx', [capturedAt]),
  ];

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
  List<Index> get indexes => [
    Index('orders_status_created_at_idx', [status, createdAt]),
  ];

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get photoAssetId => text().references(PhotoAssets, #id)();
  IntColumn get unitPriceCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get language => text().withDefault(const Constant('pt-BR'))();
  BoolColumn get wifiOnly => boolean().withDefault(const Constant(false))();
  IntColumn get accessCodeValidityDays => integer().withDefault(const Constant(7))();
  TextColumn get watermarkConfigJson =>
      text().withDefault(const Constant('{}'))();
  BoolColumn get highContrastEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Clients, PhotoAssets, Orders, OrderItems, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(orderItems);
        await m.createTable(appSettings);

        await m.customStatement(
          'CREATE INDEX IF NOT EXISTS orders_status_created_at_idx ON orders (status, created_at)',
        );
        await m.customStatement(
          'CREATE INDEX IF NOT EXISTS photo_assets_captured_at_idx ON photo_assets (captured_at)',
        );
      }
    },
  );
}
