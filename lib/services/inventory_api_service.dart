import 'dart:convert';
import 'package:crack/config/api_config.dart';
import 'package:crack/models/inventory_item.dart';
import 'package:http/http.dart' as http;

class InventoryApiService {
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${ApiConfig.accessToken}',
  };

  Future<List<InventoryItem>> fetchInventory() async {
    final response = await http.get(
      ApiConfig.uri('/api/v1/admin/branch-variants/list'),
      headers: _headers,
    );
    final body = _decode(response.body);
    _ensureSuccess(
      response.statusCode,
      body,
      'No se pudo cargar el inventario.',
    );
    final data = body['data'];
    if (data is! List) {
      throw Exception('El servidor devolvió un inventario inválido.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(InventoryItem.fromJson)
        .toList(growable: false);
  }

  Future<void> setStock({
    required InventoryItem item,
    required int newStock,
    String? note,
  }) async {
    if (newStock < 0) throw Exception('El stock no puede ser negativo.');
    final difference = newStock - item.stock;
    if (difference == 0) return;
    final response = await http.post(
      ApiConfig.uri('/api/v1/admin/movements'),
      headers: _headers,
      body: jsonEncode({
        'type': difference > 0 ? 'inflow' : 'outflow',
        'reason': 'adjustment',
        'detail_transaction': note?.trim().isNotEmpty == true
            ? note!.trim()
            : 'Ajuste desde aplicación móvil administrativa',
        'variants': [
          {
            'branch_variant_id': item.branchVariantId,
            'quantity': difference.abs(),
          },
        ],
      }),
    );
    _ensureSuccess(
      response.statusCode,
      _decode(response.body),
      'No se pudo actualizar el stock.',
    );
  }

  Future<void> setPrice({
    required InventoryItem item,
    required double newPrice,
  }) async {
    if (newPrice <= 0) {
      throw Exception('El precio debe ser mayor que cero.');
    }
    if ((newPrice - item.price).abs() < 0.001) return;

    // Se construye el número con dos decimales para cumplir la validación
    // `decimal:2` del backend sin convertirlo en texto.
    final response = await http.put(
      ApiConfig.uri('/api/v1/admin/variants/${item.variantId}'),
      headers: _headers,
      body: '{"selling_price":${newPrice.toStringAsFixed(2)}}',
    );
    _ensureSuccess(
      response.statusCode,
      _decode(response.body),
      'No se pudo actualizar el precio.',
    );
  }

  Map<String, dynamic> _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  void _ensureSuccess(int status, Map<String, dynamic> body, String fallback) {
    if (status >= 200 && status < 300) return;
    if (status == 401) {
      throw Exception('Tu sesión venció. Vuelve a iniciar sesión.');
    }
    if (status == 403) {
      throw Exception('Tu cuenta no tiene permisos de administrador.');
    }
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      throw Exception(
        first is List && first.isNotEmpty
            ? first.first.toString()
            : first.toString(),
      );
    }
    throw Exception(body['message']?.toString() ?? fallback);
  }
}
