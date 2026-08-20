class DashboardData {
  const DashboardData({
    required this.today,
    required this.inventory,
    required this.week,
    required this.month,
    required this.dailySales,
    required this.topProducts,
  });

  final TodayMetrics today;
  final InventoryMetrics inventory;
  final ComparisonMetrics week;
  final ComparisonMetrics month;
  final List<DailySale> dailySales;
  final List<TopProduct> topProducts;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final comparisons = _map(json['comparisons']);
    return DashboardData(
      today: TodayMetrics.fromJson(_map(json['today'])),
      inventory: InventoryMetrics.fromJson(_map(json['inventory'])),
      week: ComparisonMetrics.fromJson(_map(comparisons['week'])),
      month: ComparisonMetrics.fromJson(_map(comparisons['month'])),
      dailySales: _list(json['daily_sales'])
          .map((item) => DailySale.fromJson(_map(item)))
          .toList(growable: false),
      topProducts: _list(json['top_products'])
          .map((item) => TopProduct.fromJson(_map(item)))
          .toList(growable: false),
    );
  }
}

class TodayMetrics {
  const TodayMetrics({
    required this.sales,
    required this.orders,
    required this.itemsSold,
  });
  final double sales;
  final int orders;
  final int itemsSold;

  factory TodayMetrics.fromJson(Map<String, dynamic> json) => TodayMetrics(
    sales: _double(json['sales']),
    orders: _int(json['orders']),
    itemsSold: _int(json['items_sold']),
  );
}

class InventoryMetrics {
  const InventoryMetrics({
    required this.totalUnits,
    required this.lowStock,
    required this.outOfStock,
    required this.estimatedValue,
  });
  final int totalUnits;
  final int lowStock;
  final int outOfStock;
  final double estimatedValue;

  factory InventoryMetrics.fromJson(Map<String, dynamic> json) =>
      InventoryMetrics(
        totalUnits: _int(json['total_units']),
        lowStock: _int(json['low_stock']),
        outOfStock: _int(json['out_of_stock']),
        estimatedValue: _double(json['estimated_value']),
      );
}

class ComparisonMetrics {
  const ComparisonMetrics({
    required this.current,
    required this.previous,
    required this.percentageChange,
  });
  final double current;
  final double previous;
  final double percentageChange;

  factory ComparisonMetrics.fromJson(Map<String, dynamic> json) =>
      ComparisonMetrics(
        current: _double(json['current']),
        previous: _double(json['previous']),
        percentageChange: _double(json['percentage_change']),
      );
}

class DailySale {
  const DailySale({required this.label, required this.sales});
  final String label;
  final double sales;

  factory DailySale.fromJson(Map<String, dynamic> json) => DailySale(
    label: json['label']?.toString().toUpperCase() ?? '',
    sales: _double(json['sales']),
  );
}

class TopProduct {
  const TopProduct({
    required this.name,
    required this.quantity,
    required this.sales,
  });
  final String name;
  final int quantity;
  final double sales;

  factory TopProduct.fromJson(Map<String, dynamic> json) => TopProduct(
    name: json['name']?.toString() ?? 'Producto',
    quantity: _int(json['quantity']),
    sales: _double(json['sales']),
  );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};
List<dynamic> _list(dynamic value) => value is List ? value : const [];
int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
