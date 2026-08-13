class JsonNode {}

class Greden {
  Greden(this.successResolver);

  final bool Function(JsonNode root, int? statusCode)? successResolver;

  bool resolveSuccess(JsonNode root, int? statusCode) {
    /// Удобная проверка на null, сработает только если есть successResolver
    if (successResolver case final resolver?) {
      return resolver(root, statusCode);
    }

    return false;
  }
}
