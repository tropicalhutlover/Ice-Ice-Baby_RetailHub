class Product {
  final int? id;
  final String name;
  final String sku;
  final String category;
  final double basePrice;
  final double discountedPrice;
  final int stockQty;
  final String description;
  final String supplier;
  final String imageUrl;
  final String dateAdded;

  const Product({
    this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.basePrice,
    required this.discountedPrice,
    required this.stockQty,
    required this.description,
    required this.supplier,
    required this.imageUrl,
    required this.dateAdded,
  });

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    double? basePrice,
    double? discountedPrice,
    int? stockQty,
    String? description,
    String? supplier,
    String? imageUrl,
    String? dateAdded,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      stockQty: stockQty ?? this.stockQty,
      description: description ?? this.description,
      supplier: supplier ?? this.supplier,
      imageUrl: imageUrl ?? this.imageUrl,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      // keep numeric fields as strings for current DB rules compatibility!!!!!!
      'basePrice': basePrice.toString(),
      'discountedPrice': discountedPrice.toString(),
      'stockQty': stockQty.toString(),
      'description': description,
      'supplier': supplier,
      'imageUrl': imageUrl,
      'dateAdded': dateAdded,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return Product(
      id: parseInt(map['id']),
      name: (map['name'] ?? '').toString(),
      sku: (map['sku'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      basePrice: parseDouble(map['basePrice']),
      discountedPrice: parseDouble(map['discountedPrice']),
      stockQty: parseInt(map['stockQty']),
      description: (map['description'] ?? '').toString(),
      supplier: (map['supplier'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      dateAdded: (map['dateAdded'] ?? '').toString(),
    );
  }
}
