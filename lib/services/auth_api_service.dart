import 'dart:convert';
import 'package:crack/config/api_config.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  const AuthResult({
    required this.token,
    required this.name,
    required this.roles,
  });
  final String token, name;
  final List<String> roles;
}

class AuthApiService {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      ApiConfig.uri('/api/v1/auth/login'),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _json(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body['message']?.toString() ?? 'Correo o contraseña incorrectos.',
      );
    }
    final user = body['user'] is Map<String, dynamic>
        ? body['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    final roles = (user['roles'] is List ? user['roles'] as List : const [])
        .map((role) => role.toString().toLowerCase())
        .toList(growable: false);
    if (!roles.any({'admin', 'superusuario', 'superuser'}.contains)) {
      throw Exception('Esta aplicación es exclusiva para administradores.');
    }
    final token = body['token']?.toString() ?? '';
    if (token.isEmpty) {
      throw Exception('El servidor no devolvió un token de acceso.');
    }
    ApiConfig.setAccessToken(token);
    return AuthResult(
      token: token,
      name: user['name']?.toString() ?? 'Administrador',
      roles: roles,
    );
  }

  Future<void> logout() async {
    if (ApiConfig.accessToken.isNotEmpty) {
      await http.post(
        ApiConfig.uri('/api/v1/auth/logout'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.accessToken}',
        },
      );
    }
    ApiConfig.setAccessToken('');
  }

  Map<String, dynamic> _json(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }
}
