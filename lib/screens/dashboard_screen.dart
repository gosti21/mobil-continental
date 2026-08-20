import 'dart:math' as math;

import 'package:crack/models/dashboard_data.dart';
import 'package:crack/screens/inventory_screen.dart';
import 'package:crack/services/dashboard_api_service.dart';
import 'package:crack/services/inventory_api_service.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = DashboardApiService();
  DashboardData? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchDashboard();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openInventory() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => InventoryScreen(service: InventoryApiService()),
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              'Resumen administrativo',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            ),
          const _SectionTitle(title: 'HOY', icon: Icons.today_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _MetricCard(
                  title: 'Ventas',
                  value: _money(data.today.sales),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFF45B0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Pedidos',
                  value: '${data.today.orders}',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF2767B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricCard(
            title: 'Unidades vendidas hoy',
            value: '${data.today.itemsSold}',
            icon: Icons.shopping_cart_checkout_rounded,
            color: const Color(0xFF187A3D),
            horizontal: true,
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'INVENTARIO', icon: Icons.inventory_2_outlined),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _MetricCard(
                title: 'Unidades',
                value: '${data.inventory.totalUnits}',
                icon: Icons.inventory_outlined,
                color: const Color(0xFF2767B2),
              ),
              _MetricCard(
                title: 'Valor estimado',
                value: _money(data.inventory.estimatedValue),
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF187A3D),
              ),
              _MetricCard(
                title: 'Stock bajo',
                value: '${data.inventory.lowStock}',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFE78B00),
                onTap: _openInventory,
              ),
              _MetricCard(
                title: 'Agotados',
                value: '${data.inventory.outOfStock}',
                icon: Icons.remove_shopping_cart_outlined,
                color: const Color(0xFFB3261E),
                onTap: _openInventory,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'COMPARACIÓN', icon: Icons.trending_up_rounded),
          const SizedBox(height: 10),
          _ComparisonCard(title: 'Esta semana', metrics: data.week),
          const SizedBox(height: 10),
          _ComparisonCard(title: 'Este mes', metrics: data.month),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'ÚLTIMOS 7 DÍAS', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 10),
          _SalesChart(days: data.dailySales),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'MÁS VENDIDOS · 30 DÍAS',
            icon: Icons.workspace_premium_outlined,
          ),
          const SizedBox(height: 10),
          _TopProducts(products: data.topProducts),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _openInventory,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('ABRIR INVENTARIO'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: const Color(0xFFF45B0B)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .6)),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.horizontal = false,
    this.onTap,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool horizontal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: horizontal
            ? Row(children: [
                _icon(),
                const SizedBox(width: 13),
                Expanded(child: _labels()),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_icon(), const SizedBox(height: 9), _labels()],
              ),
      ),
    ),
  );

  Widget _icon() => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: color, size: 21),
  );

  Widget _labels() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
      ),
    ],
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.title, required this.metrics});
  final String title;
  final ComparisonMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final positive = metrics.percentageChange >= 0;
    final color = positive ? const Color(0xFF187A3D) : const Color(0xFFB3261E);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(_money(metrics.current), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                Text('Anterior: ${_money(metrics.previous)}', style: const TextStyle(color: Colors.black45, fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 17),
                Text('${metrics.percentageChange.abs().toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.days});
  final List<DailySale> days;

  @override
  Widget build(BuildContext context) {
    final maximum = days.fold<double>(0, (value, day) => math.max(value, day.sales));
    return Card(
      child: SizedBox(
        height: 190,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((day) {
              final ratio = maximum == 0 ? 0.04 : math.max(.04, day.sales / maximum);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(day.sales > 0 ? day.sales.toStringAsFixed(0) : '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: ratio,
                          child: Container(decoration: BoxDecoration(color: const Color(0xFFF45B0B), borderRadius: BorderRadius.circular(7))),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(day.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.products});
  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Todavía no hay ventas pagadas en este periodo.')));
    }
    return Card(
      child: Column(
        children: products.indexed.map((entry) {
          final index = entry.$1;
          final product = entry.$2;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFE4D2),
              foregroundColor: const Color(0xFFF45B0B),
              child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${product.quantity} unidades'),
            trailing: Text(_money(product.sales), style: const TextStyle(fontWeight: FontWeight.w800)),
          );
        }).toList(),
      ),
    );
  }
}

String _money(double value) => 'S/ ${value.toStringAsFixed(2)}';
