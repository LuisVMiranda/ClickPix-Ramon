import 'package:flutter_test/flutter_test.dart';
import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/value_objects/order_status_transition.dart';

void main() {
  test('deve permitir awaitingPayment -> paid', () {
    expect(OrderStatusTransition.canTransition(OrderStatus.awaitingPayment, OrderStatus.paid), isTrue);
  });

  test('não deve permitir delivered -> created', () {
    expect(OrderStatusTransition.canTransition(OrderStatus.delivered, OrderStatus.created), isFalse);
  });
}
