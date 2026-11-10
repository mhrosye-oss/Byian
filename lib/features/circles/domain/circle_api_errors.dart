class CircleApiException implements Exception {
  const CircleApiException(this.statusCode, this.message,
      {this.validationErrors});

  final int statusCode;
  final String message;
  final Map<String, dynamic>? validationErrors;

  @override
  String toString() => message;
}
