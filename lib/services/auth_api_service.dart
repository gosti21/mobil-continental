import 'dart:convert';

import 'package:crack/config/api_config.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  AuthResult({required this.token, required this.roles});

  final String token;
  final List<String> roles;
}

class AuthApiService {
  Future<AuthResult> login({required String email, required String password}) async {
    final response = await http.post(
      ApiConfig.authLoginUri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Credenciales invalidas o acceso denegado.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta invalido en login.');
    }

    final token = decoded['token'];
    final user = decoded['user'];

    if (token is! String || token.isEmpty) {
      throw Exception('No se recibio token de autenticacion.');
    }

    final rolesDynamic = user is Map<String, dynamic> ? user['roles'] : null;
    final roles = rolesDynamic is List
        ? rolesDynamic.whereType<String>().map((role) => role.toLowerCase()).toList(growable: false)
        : const <String>[];

    return AuthResult(token: token, roles: roles);
  }

  bool canAccessAdminArea(List<String> roles) {
    const allowedRoles = <String>{'admin', 'superusuario', 'superuser'};
    return roles.any(allowedRoles.contains);
  }
}
