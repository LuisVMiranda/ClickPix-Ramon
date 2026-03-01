import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/repositories/local_order_repository.dart';
import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalOrderRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalOrderRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('createOrder persists order items for selected assets', () async {
    await database.into(database.clients).insert(
          const ClientsCompanion.insert(
            id: 'client-1',
            name: 'Cliente 1',
            whatsapp: '+5511999999999',
          ),
        );

    for (final assetId in ['asset-1', 'asset-2']) {
      await database.into(database.photoAssets).insert(
            PhotoAssetsCompanion.insert(
              id: assetId,
              localPath: 'asset://$assetId',
              thumbnailKey: 'thumb_$assetId',
              capturedAt: DateTime(2026, 1, 10),
              checksum: 'checksum_$assetId',
              uploadStatus: 'local',
            ),
          );
    }

    await repository.createOrder(
      const Order(
        id: 'order-1',
        clientId: 'client-1',
        itemIds: ['asset-1', 'asset-2'],
        totalAmountCents: 3000,
        externalReference: 'order-1',
        status: OrderStatus.created,
        paymentMethod: PaymentMethod.pix,
      ),
    );

    final items = await (database.select(database.orderItems)
          ..where((tbl) => tbl.orderId.equals('order-1')))
        .get();

    expect(items, hasLength(2));
    expect(items.map((item) => item.photoAssetId), containsAll(['asset-1', 'asset-2']));
  });
}
