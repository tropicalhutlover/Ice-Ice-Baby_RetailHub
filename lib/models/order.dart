class Order {
  final int id;
  final int userId;
  final int orderGroupId;
  final String itemName;
  final int qty;
  final double total;
  final String status;

  const Order({
    required this.id,
    required this.userId,
    required this.orderGroupId,
    required this.itemName,
    required this.qty,
    required this.total,
    required this.status,
  });

  Order copyWith({
    int? id,
    int? userId,
    int? orderGroupId,
    String? itemName,
    int? qty,
    double? total,
    String? status,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderGroupId: orderGroupId ?? this.orderGroupId,
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'orderGroupId': orderGroupId,
      'itemName': itemName,
      'qty': qty,
      'total': total,
      'status': status,
    };
  }

  static Order fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Order(
      id: parseInt(map['id']),
      userId: parseInt(map['userId']),
      orderGroupId: parseInt(map['orderGroupId']),
      itemName: (map['itemName'] ?? '').toString(),
      qty: parseInt(map['qty']),
      total: parseDouble(map['total']),
      status: (map['status'] ?? 'pending').toString(),
    );
  }
}
