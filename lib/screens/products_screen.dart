import 'dart:typed_data';

import 'package:crack/config/api_config.dart';
import 'package:crack/models/product.dart';
import 'package:crack/screens/login_screen.dart';
import 'package:crack/services/products_api_service.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.service});

  final ProductsApiService service;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _productsFuture;
  String _selectedBrand = 'Todas';
  String _stockFilter = 'Todos';
  String _priceFilter = 'Todos';
  bool _isExportingPdf = false;

  void _goBackToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _logout() {
    ApiConfig.setAccessToken('');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesion cerrada correctamente.')),
    );
  }

  String _formatMoney(num? value) {
    if (value == null) {
      return 'S/ --';
    }
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  @override
  void initState() {
    super.initState();
    _productsFuture = widget.service.fetchProducts();
  }

  Future<void> _reload() async {
    setState(() {
      _productsFuture = widget.service.fetchProducts();
    });

    await _productsFuture;
  }

  List<String> _buildBrandOptions(List<Product> products) {
    final brands = products
        .map((p) => p.brand.trim())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['Todas', ...brands];
  }

  bool _matchesStock(Product product) {
    switch (_stockFilter) {
      case 'Bajo (< 20)':
        return product.stock < 20;
      case 'Medio (20 - 50)':
        return product.stock >= 20 && product.stock <= 50;
      case 'Alto (> 50)':
        return product.stock > 50;
      default:
        return true;
    }
  }

  bool _matchesPrice(Product product) {
    final price = product.sellingPrice ?? 0;
    switch (_priceFilter) {
      case 'Económico (< 100)':
        return price < 100;
      case 'Intermedio (100 - 500)':
        return price >= 100 && price <= 500;
      case 'Alto (> 500)':
        return price > 500;
      default:
        return true;
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    return products.where((product) {
      final brandMatch = _selectedBrand == 'Todas' || product.brand == _selectedBrand;
      return brandMatch && _matchesStock(product) && _matchesPrice(product);
    }).toList(growable: false);
  }

  Future<void> _exportFilteredReportToPdf(List<Product> products) async {
    if (_isExportingPdf) {
      return;
    }

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos para exportar con estos filtros.')),
      );
      return;
    }

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final totalStock = products.fold<int>(0, (sum, product) => sum + product.stock);
      final totalInventoryValue = products.fold<num>(0, (sum, product) {
        final unitPrice = product.sellingPrice ?? 0;
        return sum + (unitPrice * product.stock);
      });

      final now = DateTime.now();
      final doc = pw.Document();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Text(
                'Reporte de productos - FERREBOM',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Fecha: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
              ),
              pw.SizedBox(height: 4),
              pw.Text('Filtros aplicados: Marca=$_selectedBrand, Stock=$_stockFilter, Precio=$_priceFilter'),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Productos: ${products.length}'),
                    pw.Text('Stock total: $totalStock'),
                    pw.Text('Valor inventario: ${_formatMoney(totalInventoryValue)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                headers: const [
                  'ID',
                  'Nombre',
                  'Marca',
                  'Modelo',
                  'Precio',
                  'Stock',
                  'Total',
                ],
                data: products
                    .map(
                      (p) => [
                        '${p.id}',
                        p.name,
                        p.brand,
                        p.model,
                        _formatMoney(p.sellingPrice),
                        '${p.stock}',
                        _formatMoney((p.sellingPrice ?? 0) * p.stock),
                      ],
                    )
                    .toList(growable: false),
              ),
            ];
          },
        ),
      );

      final bytes = await doc.save();
      await Printing.layoutPdf(onLayout: (_) => _buildPdfBytes(bytes));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generado correctamente.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  Future<Uint8List> _buildPdfBytes(Uint8List bytes) async {
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos FERREBOM'),
        leading: IconButton(
          onPressed: _goBackToLogin,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No se pudo cargar productos.\n\n${snapshot.error}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Base URL: ${ApiConfig.baseUrl}\nPath: ${ApiConfig.productsPath}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('No hay productos para mostrar.')),
                ],
              ),
            );
          }

          final brandOptions = _buildBrandOptions(products);
          if (!brandOptions.contains(_selectedBrand)) {
            _selectedBrand = 'Todas';
          }

          final filteredProducts = _applyFilters(products);

          final totalStock = filteredProducts.fold<int>(
            0,
            (sum, product) => sum + product.stock,
          );
          final totalInventoryValue = filteredProducts.fold<num>(0, (sum, product) {
            final unitPrice = product.sellingPrice ?? 0;
            return sum + (unitPrice * product.stock);
          });

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: (filteredProducts.isEmpty ? 1 : filteredProducts.length) + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportSummaryCard(
                      totalProducts: filteredProducts.length,
                      totalStock: totalStock,
                      totalInventoryValue: _formatMoney(totalInventoryValue),
                    ),
                  );
                }

                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportFiltersCard(
                      brandOptions: brandOptions,
                      selectedBrand: _selectedBrand,
                      selectedStockFilter: _stockFilter,
                      selectedPriceFilter: _priceFilter,
                      isExportingPdf: _isExportingPdf,
                      onBrandChanged: (value) {
                        setState(() {
                          _selectedBrand = value;
                        });
                      },
                      onStockChanged: (value) {
                        setState(() {
                          _stockFilter = value;
                        });
                      },
                      onPriceChanged: (value) {
                        setState(() {
                          _priceFilter = value;
                        });
                      },
                      onClearFilters: () {
                        setState(() {
                          _selectedBrand = 'Todas';
                          _stockFilter = 'Todos';
                          _priceFilter = 'Todos';
                        });
                      },
                      onExportPdf: () => _exportFilteredReportToPdf(filteredProducts),
                    ),
                  );
                }

                if (filteredProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text('No hay resultados con esos filtros.'),
                    ),
                  );
                }

                final p = filteredProducts[index - 2];
                final lineTotal = (p.sellingPrice ?? 0) * p.stock;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 1,
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _ProductDetailScreen(product: p),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.all(12),
                      leading: _ProductImage(url: p.imageUrl),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.brand} • Modelo: ${p.model}\nValor total: ${_formatMoney(lineTotal)}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatMoney(p.sellingPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                          Text('Stock: ${p.stock}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
    required this.totalProducts,
    required this.totalStock,
    required this.totalInventoryValue,
  });

  final int totalProducts;
  final int totalStock;
  final String totalInventoryValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFDDEAF5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reporte de inventario',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F4C81),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReportStat(
                icon: Icons.inventory_2_outlined,
                label: 'Productos',
                value: '$totalProducts',
              ),
              _ReportStat(
                icon: Icons.stacked_bar_chart_outlined,
                label: 'Stock total',
                value: '$totalStock',
              ),
              _ReportStat(
                icon: Icons.payments_outlined,
                label: 'Valor inventario',
                value: totalInventoryValue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportFiltersCard extends StatelessWidget {
  const _ReportFiltersCard({
    required this.brandOptions,
    required this.selectedBrand,
    required this.selectedStockFilter,
    required this.selectedPriceFilter,
    required this.isExportingPdf,
    required this.onBrandChanged,
    required this.onStockChanged,
    required this.onPriceChanged,
    required this.onClearFilters,
    required this.onExportPdf,
  });

  final List<String> brandOptions;
  final String selectedBrand;
  final String selectedStockFilter;
  final String selectedPriceFilter;
  final bool isExportingPdf;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onStockChanged;
  final ValueChanged<String> onPriceChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros del reporte',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Limpiar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isExportingPdf ? null : onExportPdf,
                      icon: isExportingPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(isExportingPdf ? 'Generando...' : 'Exportar PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedBrand,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              items: brandOptions
                  .map(
                    (brand) => DropdownMenuItem<String>(
                      value: brand,
                      child: Text(brand),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  onBrandChanged(value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedStockFilter,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Bajo (< 20)', child: Text('Bajo (< 20)')),
                DropdownMenuItem(
                  value: 'Medio (20 - 50)',
                  child: Text('Medio (20 - 50)'),
                ),
                DropdownMenuItem(value: 'Alto (> 50)', child: Text('Alto (> 50)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onStockChanged(value);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPriceFilter,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(
                  value: 'Económico (< 100)',
                  child: Text('Económico (< 100)'),
                ),
                DropdownMenuItem(
                  value: 'Intermedio (100 - 500)',
                  child: Text('Intermedio (100 - 500)'),
                ),
                DropdownMenuItem(value: 'Alto (> 500)', child: Text('Alto (> 500)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPriceChanged(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F4C81)),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailScreen extends StatelessWidget {
  const _ProductDetailScreen({required this.product});

  final Product product;

  String _formatMoney(num? value) {
    if (value == null) {
      return 'S/ --';
    }
    return 'S/ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = product.sellingPrice;
    final lineTotal = (unitPrice ?? 0) * product.stock;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de producto'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: _ProductImage(url: product.imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'ID Producto', value: '${product.id}'),
                  _DetailRow(label: 'Marca', value: product.brand),
                  _DetailRow(label: 'Modelo', value: product.model),
                  _DetailRow(
                    label: 'ID Variante',
                    value: product.variantId?.toString() ?? '-',
                  ),
                  _DetailRow(
                    label: 'Precio unitario',
                    value: _formatMoney(unitPrice),
                  ),
                  _DetailRow(label: 'Stock', value: '${product.stock}'),
                  _DetailRow(
                    label: 'Valor de stock',
                    value: _formatMoney(lineTotal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
    }

    final imageUrl = ApiConfig.toAbsoluteUrl(url!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl.toString(),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const SizedBox(
            width: 56,
            height: 56,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          );
        },
      ),
    );
  }
}
