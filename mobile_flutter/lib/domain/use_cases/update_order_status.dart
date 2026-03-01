import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/repositories/order_repository.dart';
import 'package:clickpix_ramon/domain/value_objects/order_status_transition.dart';

class UpdateOrderStatus {
  final OrderRepository _orderRepository;

  UpdateOrderStatus(this._orderRepository);

  Future<void> call({required String orderId, required OrderStatus newStatus}) async {
    final order = await _orderRepository.findById(orderId);

    if (order == null) {
      throw StateError('Order not found: $orderId');
    }

    if (!OrderStatusTransition.canTransition(order.status, newStatus)) {
      throw StateError(
        'Invalid transition: ${order.status.name} -> ${newStatus.name}',
      );
    }

    await _orderRepository.updateOrderStatus(orderId, newStatus);
  }
}
