class JsonNode {}

class Greden {
  Greden(this.successResolver);

  final bool Function(JsonNode root, int? statusCode)? successResolver;

  bool resolveSuccess(JsonNode root, int? statusCode) {
    /// Проверка на Null (если successResolver != null) присвоить его в resolver
    if (successResolver case final resolver?) {
      return resolver(root, statusCode);
    }

    return false;
  }
}
