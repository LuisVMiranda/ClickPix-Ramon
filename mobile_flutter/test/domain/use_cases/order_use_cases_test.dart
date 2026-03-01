import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/repositories/order_repository.dart';
import 'package:clickpix_ramon/domain/use_cases/create_order.dart';
import 'package:clickpix_ramon/domain/use_cases/list_recent_orders.dart';
import 'package:clickpix_ramon/domain/use_cases/update_order_status.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};

  @override
  Future<void> createOrder(Order order) async {
    _orders[order.id] = order;
  }

  @override
  Future<Order?> findById(String orderId) async => _orders[orderId];

  @override
  Future<List<Order>> listRecentOrders({int limit = 20}) async {
    return _orders.values.take(limit).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final order = _orders[orderId];
    if (order != null) {
      _orders[orderId] = order.copyWith(status: newStatus);
    }
  }
}

void main() {
  Order makeOrder({
    String id = 'order-1',
    String externalReference = 'EXT-1',
    int totalAmountCents = 1000,
    OrderStatus status = OrderStatus.created,
  }) {
    return Order(
      id: id,
      clientId: 'client-1',
      itemIds: const ['item-1'],
      totalAmountCents: totalAmountCents,
      externalReference: externalReference,
      status: status,
      paymentMethod: PaymentMethod.pix,
    );
  }

  group('CreateOrder', () {
    test('creates order when input is valid', () async {
      final repository = FakeOrderRepository();
      final useCase = CreateOrder(repository);
      final order = makeOrder();

      await useCase(order);

      final stored = await repository.findById(order.id);
      expect(stored, isNotNull);
      expect(stored!.externalReference, 'EXT-1');
    });

    test('throws when externalReference is empty', () async {
      final repository = FakeOrderRepository();
      final useCase = CreateOrder(repository);
      final order = makeOrder(externalReference: '   ');

      expect(() => useCase(order), throwsArgumentError);
    });

    test('throws when totalAmountCents is negative', () async {
      final repository = FakeOrderRepository();
      final useCase = CreateOrder(repository);
      final order = makeOrder(totalAmountCents: -1);

      expect(() => useCase(order), throwsArgumentError);
    });
  });

  group('ListRecentOrders', () {
    test('returns orders from repository respecting limit', () async {
      final repository = FakeOrderRepository();
      await repository.createOrder(makeOrder(id: 'o1'));
      await repository.createOrder(makeOrder(id: 'o2'));
      await repository.createOrder(makeOrder(id: 'o3'));

      final useCase = ListRecentOrders(repository);
      final orders = await useCase(limit: 2);

      expect(orders, hasLength(2));
    });
  });

  group('UpdateOrderStatus', () {
    test('updates status when transition is valid', () async {
      final repository = FakeOrderRepository();
      await repository.createOrder(makeOrder(status: OrderStatus.created));
      final useCase = UpdateOrderStatus(repository);

      await useCase(
        orderId: 'order-1',
        newStatus: OrderStatus.awaitingPayment,
      );

      final updated = await repository.findById('order-1');
      expect(updated!.status, OrderStatus.awaitingPayment);
    });

    test('throws when order does not exist', () async {
      final repository = FakeOrderRepository();
      final useCase = UpdateOrderStatus(repository);

      expect(
        () => useCase(orderId: 'missing', newStatus: OrderStatus.awaitingPayment),
        throwsStateError,
      );
    });

    test('throws when transition is invalid', () async {
      final repository = FakeOrderRepository();
      await repository.createOrder(makeOrder(status: OrderStatus.created));
      final useCase = UpdateOrderStatus(repository);

      expect(
        () => useCase(orderId: 'order-1', newStatus: OrderStatus.delivered),
        throwsStateError,
      );
    });
  });
}
