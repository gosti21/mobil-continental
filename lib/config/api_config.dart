import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlFromEnv = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://iccontinental.onrender.com',
  );

  static const String productsPath = String.fromEnvironment(
    'API_PRODUCTS_PATH',
    defaultValue: '/api/v1/products',
  );

  static const String token = String.fromEnvironment(
    'API_TOKEN',
    defaultValue: '',
  );

  static const String authLoginPath = String.fromEnvironment(
    'API_AUTH_LOGIN_PATH',
    defaultValue: '/api/v1/auth/login',
  );

  static String accessToken = token;

  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) {
      return _baseUrlFromEnv;
    }

    if (kIsWeb) {
      return 'https://iccontinental.onrender.com';
    }

    if (Platform.isAndroid) {
      return 'https://iccontinental.onrender.com';
    }

    return 'https://iccontinental.onrender.com';
  }

  static Uri get productsUri => Uri.parse('$baseUrl$productsPath');

  static Uri get authLoginUri => Uri.parse('$baseUrl$authLoginPath');

  static void setAccessToken(String value) {
    accessToken = value;
  }

  static Uri toAbsoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }

    return Uri.parse(baseUrl).resolve(path);
  }
}
