import '../entities/order.dart';

class OrderStatusTransition {
  static const Map<OrderStatus, String> contractStateByStatus = {
    OrderStatus.created: 'Created',
    OrderStatus.awaitingPayment: 'AwaitingPayment',
    OrderStatus.paid: 'Paid',
    OrderStatus.delivering: 'Delivering',
    OrderStatus.delivered: 'Delivered',
    OrderStatus.expired: 'Expired',
    OrderStatus.refunded: 'Refunded',
    OrderStatus.canceled: 'Canceled',
  };

  static final Map<String, OrderStatus> statusByContractState = {
    for (final entry in contractStateByStatus.entries) entry.value: entry.key,
  };

  static final Map<OrderStatus, Set<OrderStatus>> _transitions = {
    OrderStatus.created: {OrderStatus.awaitingPayment, OrderStatus.canceled},
    OrderStatus.awaitingPayment: {OrderStatus.paid, OrderStatus.expired, OrderStatus.canceled},
    OrderStatus.paid: {OrderStatus.delivering, OrderStatus.refunded},
    OrderStatus.delivering: {OrderStatus.delivered, OrderStatus.refunded},
    OrderStatus.delivered: {OrderStatus.refunded},
    OrderStatus.expired: {OrderStatus.awaitingPayment},
    OrderStatus.refunded: <OrderStatus>{},
    OrderStatus.canceled: <OrderStatus>{},
  };

  static bool canTransition(OrderStatus from, OrderStatus to) {
    return _transitions[from]?.contains(to) ?? false;
  }

  static Map<OrderStatus, Set<OrderStatus>> get transitions => _transitions;
}
