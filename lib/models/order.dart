class OrderItemSummary {
  final String id;
  final String name;
  final int qty;
  final double price; // unit price

  const OrderItemSummary({
    required this.id,
    required this.name,
    required this.qty,
    required this.price,
  });

  double get lineTotal => price * qty;
}

class OrderStatusStepInfo {
  final String name;
  final DateTime? at;
  const OrderStatusStepInfo({required this.name, required this.at});
}

class OrderSummary {
  final String orderId;
  final String status;
  final double total;
  final int? etaMinutes;
  final DateTime createdAt;
  final List<OrderItemSummary> items;
  final List<OrderStatusStepInfo> steps;
  final String? restaurantName;

  const OrderSummary({
    required this.orderId,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    required this.steps,
    this.etaMinutes,
    this.restaurantName,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final stepsJson = (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return OrderSummary(
      orderId: (json['orderId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse('${json['total']}') ?? 0.0,
      etaMinutes: json['etaMinutes'] is num
          ? (json['etaMinutes'] as num).round()
          : int.tryParse('${json['etaMinutes']}'),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      items: itemsJson
          .map(
            (item) => OrderItemSummary(
              id: (item['id'] ?? '').toString(),
              name: (item['name'] ?? '').toString(),
              qty: item['qty'] is num
                  ? (item['qty'] as num).round()
                  : int.tryParse('${item['qty']}') ?? 0,
              price: item['price'] is num
                  ? (item['price'] as num).toDouble()
                  : double.tryParse('${item['price']}') ?? 0.0,
            ),
          )
          .toList(),
      steps: stepsJson
          .map(
            (step) => OrderStatusStepInfo(
              name: (step['name'] ?? '').toString(),
              at: DateTime.tryParse(step['at']?.toString() ?? ''),
            ),
          )
          .toList(),
      restaurantName: (json['restaurantName'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'status': status,
    'total': total,
    'etaMinutes': etaMinutes,
    'createdAt': createdAt.toIso8601String(),
    'items': items
        .map(
          (item) => {
            'id': item.id,
            'name': item.name,
            'qty': item.qty,
            'price': item.price,
          },
        )
        .toList(),
    'steps': steps
        .map((step) => {'name': step.name, 'at': step.at?.toIso8601String()})
        .toList(),
    'restaurantName': restaurantName,
  };
}
