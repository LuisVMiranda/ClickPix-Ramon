import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get whatsapp => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'photo_assets_captured_at_idx', columns: {#capturedAt})
class PhotoAssets extends Table {
  TextColumn get id => text()();
  TextColumn get localPath => text()();
  TextColumn get thumbnailKey => text()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get checksum => text().unique()();
  TextColumn get uploadStatus => text()();
  TextColumn get storagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
    name: 'orders_status_created_at_idx', columns: {#status, #createdAt})
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
  Set<Column> get primaryKey => {id};
}

class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get photoAssetId => text().references(PhotoAssets, #id)();
  IntColumn get unitPriceCents => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get language => text().withDefault(const Constant('pt-BR'))();
  BoolColumn get wifiOnly => boolean().withDefault(const Constant(false))();
  IntColumn get accessCodeValidityDays =>
      integer().withDefault(const Constant(7))();
  TextColumn get watermarkConfigJson =>
      text().withDefault(const Constant('{}'))();
  BoolColumn get highContrastEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get solarLargeFontEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get themeMode => text().withDefault(const Constant('system'))();
  TextColumn get accentColorKey =>
      text().withDefault(const Constant('blue_mid'))();
  TextColumn get adminUsername => text().withDefault(const Constant('admin'))();
  TextColumn get adminPasswordHash => text().withDefault(const Constant(
      '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9'))();
  TextColumn get photographerName =>
      text().withDefault(const Constant('Fotógrafo'))();
  TextColumn get photographerWhatsapp =>
      text().withDefault(const Constant(''))();
  TextColumn get photographerEmail => text().withDefault(const Constant(''))();
  TextColumn get photographerPixKey => text().withDefault(const Constant(''))();
  TextColumn get photographerPaypal => text().withDefault(const Constant(''))();
  TextColumn get paymentProvider =>
      text().withDefault(const Constant('manual'))();
  TextColumn get paymentApiBaseUrl =>
      text().withDefault(const Constant(''))();
  TextColumn get paymentApiToken => text().withDefault(const Constant(''))();
  TextColumn get deliveryHistoryJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get preferredInputFolder =>
      text().withDefault(const Constant(''))();
  TextColumn get pictureCombosJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get lastSelectedPictureComboId =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
    name: 'upload_tasks_status_next_attempt_idx',
    columns: {#status, #nextAttemptAt})
@TableIndex(name: 'upload_tasks_order_id_idx', columns: {#orderId})
class UploadTasks extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Clients,
  PhotoAssets,
  Orders,
  OrderItems,
  AppSettings,
  UploadTasks
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(orderItems);
            await m.createTable(appSettings);

            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS orders_status_created_at_idx ON orders (status, created_at)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS photo_assets_captured_at_idx ON photo_assets (captured_at)',
            );
          }
          if (from >= 2 && from < 3) {
            await m.addColumn(appSettings, appSettings.solarLargeFontEnabled);
          }
          if (from >= 3 && from < 4) {
            await m.addColumn(appSettings, appSettings.themeMode);
          }
          if (from >= 2 && from < 7) {
            await m.addColumn(appSettings, appSettings.accentColorKey);
          }
          if (from < 5) {
            await m.createTable(uploadTasks);
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS upload_tasks_status_next_attempt_idx ON upload_tasks (status, next_attempt_at)',
            );
            await m.database.customStatement(
              'CREATE INDEX IF NOT EXISTS upload_tasks_order_id_idx ON upload_tasks (order_id)',
            );
          }
          if (from >= 2 && from < 6) {
            await m.addColumn(appSettings, appSettings.adminUsername);
            await m.addColumn(appSettings, appSettings.adminPasswordHash);
            await m.addColumn(appSettings, appSettings.photographerName);
            await m.addColumn(appSettings, appSettings.photographerWhatsapp);
            await m.addColumn(appSettings, appSettings.photographerEmail);
            await m.addColumn(appSettings, appSettings.photographerPixKey);
            await m.addColumn(appSettings, appSettings.deliveryHistoryJson);
            await m.addColumn(appSettings, appSettings.preferredInputFolder);
          }
          if (from >= 2 && from < 8) {
            await m.addColumn(appSettings, appSettings.pictureCombosJson);
          }
          if (from >= 2 && from < 9) {
            await m.addColumn(
              appSettings,
              appSettings.lastSelectedPictureComboId,
            );
          }
          if (from >= 2 && from < 10) {
            await m.addColumn(appSettings, appSettings.photographerPaypal);
          }
          if (from >= 2 && from < 11) {
            await m.addColumn(appSettings, appSettings.paymentProvider);
            await m.addColumn(appSettings, appSettings.paymentApiBaseUrl);
            await m.addColumn(appSettings, appSettings.paymentApiToken);
          }
        },
      );
}

