import 'package:clickpix_ramon/data/local/app_database.dart';
import 'package:clickpix_ramon/data/services/upload_queue_service.dart';
import 'package:clickpix_ramon/domain/entities/order.dart' as domain;
import 'package:clickpix_ramon/domain/repositories/order_repository.dart';
import 'package:clickpix_ramon/domain/value_objects/order_status_transition.dart';
import 'package:drift/drift.dart';

class LocalOrderRepository implements OrderRepository {
  final AppDatabase _database;
  final UploadQueueService? _uploadQueueService;

  LocalOrderRepository(this._database, {UploadQueueService? uploadQueueService})
      : _uploadQueueService = uploadQueueService;

  @override
  Future<void> createOrder(domain.Order order) async {
    await _database.transaction(() async {
      await _database.into(_database.orders).insert(
            OrdersCompanion.insert(
              id: order.id,
              clientId: order.clientId,
              totalAmountCents: order.totalAmountCents,
              status: OrderStatusTransition.contractStateByStatus[order.status]!,
              paymentMethod: order.paymentMethod.name,
              externalReference: order.externalReference,
            ),
          );

      for (final itemId in order.itemIds) {
        await _database.into(_database.orderItems).insert(
              OrderItemsCompanion.insert(
                id: '${order.id}_$itemId',
                orderId: order.id,
                photoAssetId: itemId,
                unitPriceCents: _itemUnitPrice(order, order.itemIds.length),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });

    await _uploadQueueService?.enqueueOrderUpload(order.id);
  }

  int _itemUnitPrice(domain.Order order, int itemCount) {
    if (itemCount == 0) {
      return 0;
    }
    return (order.totalAmountCents / itemCount).round();
  }

  @override
  Future<domain.Order?> findById(String orderId) async {
    final row = await (_database.select(
      _database.orders,
    )..where((tbl) => tbl.id.equals(orderId))).getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toEntity(row);
  }

  @override
  Future<List<domain.Order>> listRecentOrders({int limit = 20}) async {
    final rows = await (_database.select(_database.orders)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit))
        .get();

    return Future.wait(rows.map(_toEntity));
  }

  @override
  Future<void> updateOrderStatus(String orderId, domain.OrderStatus newStatus) async {
    await (_database.update(_database.orders)
          ..where((tbl) => tbl.id.equals(orderId)))
        .write(
      OrdersCompanion(
        status: Value(OrderStatusTransition.contractStateByStatus[newStatus]!),
      ),
    );
  }

  Future<domain.Order> _toEntity(Order row) async {
    final itemRows = await (_database.select(_database.orderItems)
          ..where((tbl) => tbl.orderId.equals(row.id)))
        .get();

    return domain.Order(
      id: row.id,
      clientId: row.clientId,
      itemIds: itemRows.map((item) => item.photoAssetId).toList(),
      totalAmountCents: row.totalAmountCents,
      externalReference: row.externalReference,
      status: OrderStatusTransition.statusByContractState[row.status] ??
          domain.OrderStatus.created,
      paymentMethod: domain.PaymentMethod.values.firstWhere(
        (method) => method.name == row.paymentMethod,
      ),
    );
  }
}
