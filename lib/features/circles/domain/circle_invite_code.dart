String? parseCircleInviteCode(String value) {
  final rawValue = value.trim();
  if (rawValue.isEmpty) return null;

  final uri = Uri.tryParse(rawValue);
  final String code;
  if (uri != null && uri.hasScheme) {
    if (uri.scheme.toLowerCase() != 'itqan' ||
        uri.host.toLowerCase() != 'circle' ||
        uri.path != '/invite') {
      return null;
    }
    code = uri.queryParameters['code']?.trim() ?? '';
  } else {
    code = rawValue;
  }

  if (code.isEmpty || code.length > 32) return null;
  return code;
}
