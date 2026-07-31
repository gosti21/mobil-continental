import 'dart:convert';

import 'package:crack/config/api_config.dart';
import 'package:crack/models/product.dart';
import 'package:http/http.dart' as http;

class ProductsApiService {
  Future<List<Product>> fetchProducts() async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (ApiConfig.accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ApiConfig.accessToken}';
    }

    final response = await http.get(ApiConfig.productsUri, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Error HTTP ${response.statusCode}: no se pudo obtener productos.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;

    if (data is! List) {
      throw Exception('Formato de respuesta invalido en productos.');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList(growable: false);
  }
}
