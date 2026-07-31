class Product {
  const Product({
    required this.id,
    required this.name,
    required this.model,
    required this.brand,
    required this.variantId,
    required this.sellingPrice,
    required this.stock,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String model;
  final String brand;
  final int? variantId;
  final num? sellingPrice;
  final int stock;
  final String? imageUrl;

  static num? _parseNum(dynamic value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final variant = json['variant'];
    final variantMap = variant is Map<String, dynamic> ? variant : null;

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Sin nombre',
      model: json['model']?.toString() ?? '-',
      brand: json['brand']?.toString() ?? '-',
      variantId: (variantMap?['id'] as num?)?.toInt(),
      sellingPrice: _parseNum(variantMap?['selling_price']),
      stock: (variantMap?['stock'] as num?)?.toInt() ?? 0,
      imageUrl: variantMap?['image']?.toString(),
    );
  }
}
