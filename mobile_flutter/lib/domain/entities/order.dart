enum OrderStatus { created, awaitingPayment, paid, delivering, delivered, expired, refunded, canceled }

enum PaymentMethod { pix, card, paypal }

class Order {
  final String id;
  final String clientId;
  final List<String> itemIds;
  final int totalAmountCents;
  final String externalReference;
  final OrderStatus status;
  final PaymentMethod paymentMethod;

  const Order({
    required this.id,
    required this.clientId,
    required this.itemIds,
    required this.totalAmountCents,
    required this.externalReference,
    required this.status,
    required this.paymentMethod,
  });

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        clientId: clientId,
        itemIds: itemIds,
        totalAmountCents: totalAmountCents,
        externalReference: externalReference,
        status: status ?? this.status,
        paymentMethod: paymentMethod,
      );
}
