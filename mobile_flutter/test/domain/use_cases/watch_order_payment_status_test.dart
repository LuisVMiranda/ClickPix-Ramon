import 'dart:async';

import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/use_cases/watch_order_payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioritizes snapshot as main status source', () async {
    final snapshotController = StreamController<OrderStatus>();
    var pollCalls = 0;

    final useCase = WatchOrderPaymentStatus(
      snapshotSource: (_) => snapshotController.stream,
      pollSource: (_) async {
        pollCalls += 1;
        return OrderStatus.awaitingPayment;
      },
      snapshotGracePeriod: const Duration(milliseconds: 20),
      initialBackoff: const Duration(milliseconds: 10),
      maxBackoff: const Duration(milliseconds: 20),
    );

    final statuses = <OrderStatus>[];
    final subscription = useCase('order-1').listen(statuses.add);

    snapshotController.add(OrderStatus.awaitingPayment);
    snapshotController.add(OrderStatus.paid);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(statuses, [OrderStatus.awaitingPayment, OrderStatus.paid]);
    expect(pollCalls, 0);

    await subscription.cancel();
    await snapshotController.close();
  });

  test('falls back to polling with backoff when snapshot does not emit', () async {
    final snapshotController = StreamController<OrderStatus>();
    var pollCalls = 0;

    final useCase = WatchOrderPaymentStatus(
      snapshotSource: (_) => snapshotController.stream,
      pollSource: (_) async {
        pollCalls += 1;
        if (pollCalls == 1) {
          return OrderStatus.awaitingPayment;
        }
        return OrderStatus.paid;
      },
      snapshotGracePeriod: const Duration(milliseconds: 15),
      initialBackoff: const Duration(milliseconds: 10),
      maxBackoff: const Duration(milliseconds: 20),
    );

    final statuses = <OrderStatus>[];
    final subscription = useCase('order-2').listen(statuses.add);

    await Future<void>.delayed(const Duration(milliseconds: 55));

    expect(statuses, [OrderStatus.awaitingPayment, OrderStatus.paid]);
    expect(pollCalls, greaterThanOrEqualTo(2));

    await subscription.cancel();
    await snapshotController.close();
  });
}
