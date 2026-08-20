import 'package:crack/config/api_config.dart';
import 'package:crack/models/inventory_item.dart';
import 'package:crack/services/inventory_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum StockFilter { all, low, out, available }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.service});
  final InventoryApiService service;
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();
  List<InventoryItem> _items = const [];
  bool _loading = true;
  String? _error;
  StockFilter _filter = StockFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.service.fetchInventory();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<InventoryItem> get _visible {
    final query = _search.text.trim().toLowerCase();
    return _items
        .where((item) {
          final matches =
              query.isEmpty ||
              '${item.name} ${item.sku} ${item.brand} ${item.model} ${item.features.join(' ')}'
                  .toLowerCase()
                  .contains(query);
          final stockMatches = switch (_filter) {
            StockFilter.low => item.hasLowStock && !item.isOutOfStock,
            StockFilter.out => item.isOutOfStock,
            StockFilter.available => !item.hasLowStock,
            StockFilter.all => true,
          };
          return matches && stockMatches;
        })
        .toList(growable: false);
  }

  Future<void> _edit(InventoryItem item) async {
    final stock = TextEditingController(text: item.stock.toString());
    final price = TextEditingController(text: item.price.toStringAsFixed(2));
    final note = TextEditingController();
    bool saving = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE6D5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFFF45B0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EDITAR PRODUCTO',
                          style: TextStyle(
                            color: Color(0xFFF45B0B),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.sku,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Stock registrado'),
                    Text(
                      '${item.stock} unidades',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: price,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                ],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nuevo precio de venta',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: 'S/ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stock,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nuevo stock total',
                  prefixIcon: Icon(Icons.numbers),
                  suffixText: 'unidades',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLength: 180,
                decoration: const InputDecoration(
                  labelText: 'Motivo u observación',
                  hintText: 'Ej. Conteo físico de almacén',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final value = int.tryParse(stock.text.trim());
                        final priceValue = double.tryParse(
                          price.text.trim().replaceAll(',', '.'),
                        );
                        if (value == null || value < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingresa un stock válido (0 o mayor).',
                              ),
                            ),
                          );
                          return;
                        }
                        if (priceValue == null || priceValue <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingresa un precio válido mayor que cero.',
                              ),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => saving = true);
                        try {
                          await widget.service.setPrice(
                            item: item,
                            newPrice: priceValue,
                          );
                          await widget.service.setStock(
                            item: item,
                            newStock: value,
                            note: note.text,
                          );
                          if (!mounted || !context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Precio y stock actualizados correctamente.',
                              ),
                              backgroundColor: Color(0xFF187A3D),
                            ),
                          );
                          await _load();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red.shade800,
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) {
                            setSheetState(() => saving = false);
                          }
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'GUARDANDO...' : 'GUARDAR AJUSTE'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    stock.dispose();
    price.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final low = _items.where((e) => e.hasLowStock && !e.isOutOfStock).length;
    final out = _items.where((e) => e.isOutOfStock).length;
    final units = _items.fold<int>(0, (sum, item) => sum + item.stock);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Volver a bienvenida',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EL MUNDO DEL PERNO',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              'Inventario administrativo',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'El Mundo del Perno Admin',
              applicationVersion: '1.0.0',
              children: const [
                Text('Control móvil de productos y existencias.'),
              ],
            ),
            tooltip: 'Información',
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF171717),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFF292929),
                        hintText: 'Buscar producto, SKU, marca o medida…',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFF45B0B),
                        ),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'REFERENCIAS',
                            value: '${_items.length}',
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _Metric(
                            label: 'UNIDADES',
                            value: '$units',
                            icon: Icons.warehouse_outlined,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _Metric(
                            label: 'ALERTAS',
                            value: '${low + out}',
                            icon: Icons.warning_amber_rounded,
                            alert: low + out > 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  children: [
                    _Filter(
                      label: 'Todos (${_items.length})',
                      selected: _filter == StockFilter.all,
                      onTap: () => setState(() => _filter = StockFilter.all),
                    ),
                    _Filter(
                      label: 'Stock bajo ($low)',
                      selected: _filter == StockFilter.low,
                      onTap: () => setState(() => _filter = StockFilter.low),
                    ),
                    _Filter(
                      label: 'Agotados ($out)',
                      selected: _filter == StockFilter.out,
                      onTap: () => setState(() => _filter = StockFilter.out),
                    ),
                    _Filter(
                      label: 'Disponibles',
                      selected: _filter == StockFilter.available,
                      onTap: () =>
                          setState(() => _filter = StockFilter.available),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: _ErrorState(message: _error!, retry: _load),
              )
            else if (_visible.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No hay productos que coincidan con el filtro.'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 28),
                sliver: SliverList.builder(
                  itemCount: _visible.length,
                  itemBuilder: (_, index) => _InventoryCard(
                    item: _visible[index],
                    onEdit: () => _edit(_visible[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
  });
  final String label, value;
  final IconData icon;
  final bool alert;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: alert ? const Color(0xFFFFA726) : Colors.white54,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onEdit});
  final InventoryItem item;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final color = item.isOutOfStock
        ? Colors.red.shade700
        : item.hasLowStock
        ? const Color(0xFFE98618)
        : const Color(0xFF187A3D);
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 68,
                  height: 68,
                  color: const Color(0xFFF1EFEC),
                  child: item.imageUrl == null
                      ? const Icon(
                          Icons.hexagon_outlined,
                          size: 36,
                          color: Color(0xFFF45B0B),
                        )
                      : Image.network(
                          ApiConfig.toAbsoluteUrl(item.imageUrl!).toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.hexagon_outlined,
                            size: 36,
                            color: Color(0xFFF45B0B),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.brand} · ${item.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      item.features.isEmpty
                          ? item.sku
                          : '${item.sku} · ${item.features.join(' / ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.isOutOfStock
                                ? 'AGOTADO'
                                : item.hasLowStock
                                ? 'STOCK BAJO'
                                : 'DISPONIBLE',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'S/ ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  Text(
                    '${item.stock}',
                    style: TextStyle(
                      color: color,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'unid.',
                    style: TextStyle(color: Colors.black38, fontSize: 10),
                  ),
                  const SizedBox(height: 7),
                  const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFFF45B0B),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(30),
    children: [
      const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.black26),
      const SizedBox(height: 14),
      const Text(
        'No pudimos conectar con el inventario',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('REINTENTAR'),
      ),
    ],
  );
}
