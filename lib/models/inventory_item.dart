class InventoryItem {
  const InventoryItem({
    required this.branchVariantId,
    required this.variantId,
    required this.productId,
    required this.name,
    required this.model,
    required this.brand,
    required this.sku,
    required this.stock,
    required this.minimumStock,
    required this.price,
    required this.features,
    this.imageUrl,
  });

  final int branchVariantId, variantId, productId, stock, minimumStock;
  final String name, model, brand, sku;
  final double price;
  final List<String> features;
  final String? imageUrl;
  bool get hasLowStock => stock <= minimumStock;
  bool get isOutOfStock => stock <= 0;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawFeatures = json['features'] is List
        ? json['features'] as List
        : const [];
    return InventoryItem(
      branchVariantId: _integer(json['id']),
      variantId: _integer(product['variant_id']),
      productId: _integer(product['id']),
      name: product['name']?.toString() ?? 'Producto sin nombre',
      model: product['model']?.toString() ?? 'Sin modelo',
      brand: product['brand']?.toString() ?? 'Sin marca',
      sku: json['sku']?.toString() ?? 'SIN-SKU',
      stock: _integer(json['stock']),
      minimumStock: _integer(json['stock_min']),
      price: double.tryParse(json['selling_price']?.toString() ?? '') ?? 0,
      features: rawFeatures
          .whereType<Map<String, dynamic>>()
          .map((value) => value['description']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      imageUrl: json['image']?.toString(),
    );
  }

  static int _integer(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}
