import 'package:clickpix_ramon/domain/entities/order.dart';
import 'package:clickpix_ramon/domain/repositories/order_repository.dart';

class ListRecentOrders {
  final OrderRepository _orderRepository;

  ListRecentOrders(this._orderRepository);

  Future<List<Order>> call({int limit = 20}) {
    return _orderRepository.listRecentOrders(limit: limit);
  }
}
