class CircleApiConfig {
  CircleApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'CIRCLES_API_BASE_URL',
    defaultValue: 'https://blueviolet-viper-439935.hostingersite.com',
  );
  static const apiPrefix = '/api/v1';
}

class CircleApiException implements Exception {
  const CircleApiException(
    this.statusCode,
    this.message, {
    this.validationErrors,
    this.isUnauthenticatedBug = false,
  });

  final int statusCode;
  final String message;
  final Map<String, dynamic>? validationErrors;
  final bool isUnauthenticatedBug;

  @override
  String toString() => message;
}
