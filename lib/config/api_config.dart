class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://iccontinental-lico.onrender.com',
  );

  static String accessToken = '';
  static Uri uri(String path) => Uri.parse('$baseUrl$path');
  static void setAccessToken(String value) => accessToken = value;
  static bool get hasAccessToken => accessToken.trim().isNotEmpty;

  static Uri toAbsoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    return Uri.parse(baseUrl).resolve(path);
  }
}
