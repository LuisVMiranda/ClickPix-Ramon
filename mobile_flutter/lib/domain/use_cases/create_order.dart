import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/repositories/order_repository.dart';

class CreateOrder {
  final OrderRepository _orderRepository;

  CreateOrder(this._orderRepository);

  Future<void> call(Order order) {
    if (order.externalReference.trim().isEmpty) {
      throw ArgumentError('externalReference is required');
    }

    if (order.totalAmountCents < 0) {
      throw ArgumentError('totalAmountCents must be >= 0');
    }

    return _orderRepository.createOrder(order);
  }
}
