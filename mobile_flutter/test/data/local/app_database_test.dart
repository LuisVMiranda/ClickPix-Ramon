import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('AppDatabase migration', () {
    test('migrates schema v1 to v5 preserving existing data', () async {
      final sqliteDb = sqlite.sqlite3.openInMemory();
      sqliteDb.execute('''
        CREATE TABLE clients (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          whatsapp TEXT NOT NULL,
          email TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
      ''');
      sqliteDb.execute('''
        CREATE TABLE photo_assets (
          id TEXT NOT NULL PRIMARY KEY,
          local_path TEXT NOT NULL,
          thumbnail_key TEXT NOT NULL,
          captured_at INTEGER NOT NULL,
          checksum TEXT NOT NULL UNIQUE,
          upload_status TEXT NOT NULL,
          storage_path TEXT
        );
      ''');
      sqliteDb.execute('''
        CREATE TABLE orders (
          id TEXT NOT NULL PRIMARY KEY,
          client_id TEXT NOT NULL,
          total_amount_cents INTEGER NOT NULL,
          currency TEXT NOT NULL DEFAULT 'BRL',
          status TEXT NOT NULL,
          payment_method TEXT NOT NULL,
          external_reference TEXT NOT NULL UNIQUE,
          provider_data_json TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        );
      ''');

      sqliteDb.execute(
        "INSERT INTO orders (id, client_id, total_amount_cents, currency, status, payment_method, external_reference, provider_data_json, created_at) "
        "VALUES ('order-1', 'client-1', 1200, 'BRL', 'AwaitingPayment', 'pix', 'PFBR-20260101-ABCD-1234', NULL, strftime('%s', 'now'));",
      );
      sqliteDb.execute('PRAGMA user_version = 1;');

      final database = AppDatabase(NativeDatabase.opened(sqliteDb));

      expect(database.schemaVersion, 5);

      final orders = await database.select(database.orders).get();
      expect(orders, hasLength(1));
      expect(orders.single.externalReference, 'PFBR-20260101-ABCD-1234');

      final orderItemsTableExists = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'order_items';",
      ).getSingleOrNull();
      final appSettingsTableExists = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'app_settings';",
      ).getSingleOrNull();
      final uploadTasksTableExists = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'upload_tasks';",
      ).getSingleOrNull();

      expect(orderItemsTableExists, isNotNull);
      expect(appSettingsTableExists, isNotNull);
      expect(uploadTasksTableExists, isNotNull);

      final ordersIndexes = await database.customSelect(
        "PRAGMA index_list('orders');",
      ).get();
      final photoAssetsIndexes = await database.customSelect(
        "PRAGMA index_list('photo_assets');",
      ).get();
      final uploadTaskIndexes = await database.customSelect(
        "PRAGMA index_list('upload_tasks');",
      ).get();

      final orderIndexNames = ordersIndexes
          .map((row) => row.read<String>('name'))
          .toSet();
      final photoIndexNames = photoAssetsIndexes
          .map((row) => row.read<String>('name'))
          .toSet();
      final uploadTaskIndexNames = uploadTaskIndexes
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(orderIndexNames, contains('orders_status_created_at_idx'));
      expect(photoIndexNames, contains('photo_assets_captured_at_idx'));
      expect(orderIndexNames, contains('orders_external_reference'));
      expect(uploadTaskIndexNames, contains('upload_tasks_status_next_attempt_idx'));

      await database.close();
    });
  });

  group('AppDatabase CRUD', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts and reads app settings singleton fields', () async {
      await database.into(database.appSettings).insert(
            const AppSettingsCompanion.insert(
              language: 'en',
              wifiOnly: true,
              accessCodeValidityDays: 3,
              watermarkConfigJson: '{"enabled":true}',
              highContrastEnabled: true,
              solarLargeFontEnabled: true,
              themeMode: 'dark',
            ),
          );

      final settings = await database.select(database.appSettings).getSingle();

      expect(settings.id, 1);
      expect(settings.language, 'en');
      expect(settings.wifiOnly, isTrue);
      expect(settings.accessCodeValidityDays, 3);
      expect(settings.watermarkConfigJson, '{"enabled":true}');
      expect(settings.highContrastEnabled, isTrue);
      expect(settings.solarLargeFontEnabled, isTrue);
      expect(settings.themeMode, 'dark');
    });

    test('creates order items linked to order and photo asset', () async {
      await database.into(database.clients).insert(
            const ClientsCompanion.insert(
              id: 'client-1',
              name: 'Cliente 1',
              whatsapp: '+5511999999999',
            ),
          );

      await database.into(database.photoAssets).insert(
            PhotoAssetsCompanion.insert(
              id: 'asset-1',
              localPath: '/tmp/image.jpg',
              thumbnailKey: 'thumb-1',
              capturedAt: DateTime(2026, 1, 1),
              checksum: 'checksum-1',
              uploadStatus: 'pending',
            ),
          );

      await database.into(database.orders).insert(
            const OrdersCompanion.insert(
              id: 'order-1',
              clientId: 'client-1',
              totalAmountCents: 1500,
              status: 'Created',
              paymentMethod: 'pix',
              externalReference: 'PFBR-20260101-ORDER-XYZ',
            ),
          );

      await database.into(database.orderItems).insert(
            const OrderItemsCompanion.insert(
              id: 'item-1',
              orderId: 'order-1',
              photoAssetId: 'asset-1',
              unitPriceCents: 1500,
            ),
          );

      final orderItems = await database.select(database.orderItems).get();

      expect(orderItems, hasLength(1));
      expect(orderItems.single.orderId, 'order-1');
      expect(orderItems.single.photoAssetId, 'asset-1');
      expect(orderItems.single.unitPriceCents, 1500);
    });
  });
}
