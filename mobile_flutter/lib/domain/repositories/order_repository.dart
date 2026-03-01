import '../entities/order.dart';

abstract class OrderRepository {
  Future<void> createOrder(Order order);
  Future<List<Order>> listRecentOrders({int limit = 20});
  Future<Order?> findById(String orderId);
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus);
}
