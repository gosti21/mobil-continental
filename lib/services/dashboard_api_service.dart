import 'dart:convert';

import 'package:crack/config/api_config.dart';
import 'package:crack/models/dashboard_data.dart';
import 'package:http/http.dart' as http;

class DashboardApiService {
  Future<DashboardData> fetchDashboard() async {
    final response = await http.get(
      ApiConfig.uri('/api/v1/mobile/dashboard'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${ApiConfig.accessToken}',
      },
    );

    final body = _decode(response.body);
    if (response.statusCode == 401) {
      throw Exception('Tu sesión venció. Vuelve a iniciar sesión.');
    }
    if (response.statusCode == 403) {
      throw Exception('Tu cuenta no tiene acceso al dashboard.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ?? 'No se pudo cargar el dashboard.',
      );
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('El servidor devolvió métricas inválidas.');
    }
    return DashboardData.fromJson(data);
  }

  Map<String, dynamic> _decode(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
