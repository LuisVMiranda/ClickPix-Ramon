import '../entities/order.dart';

class OrderStatusTransition {
  static bool canTransition(OrderStatus from, OrderStatus to) {
    const map = {
      OrderStatus.created: [OrderStatus.awaitingPayment, OrderStatus.canceled],
      OrderStatus.awaitingPayment: [OrderStatus.paid, OrderStatus.canceled, OrderStatus.expired],
      OrderStatus.paid: [OrderStatus.delivering, OrderStatus.refunded],
      OrderStatus.delivering: [OrderStatus.delivered, OrderStatus.refunded],
      OrderStatus.delivered: [OrderStatus.refunded],
      OrderStatus.expired: [OrderStatus.awaitingPayment],
      OrderStatus.refunded: <OrderStatus>[],
      OrderStatus.canceled: <OrderStatus>[],
    };

    return map[from]?.contains(to) ?? false;
  }
}
