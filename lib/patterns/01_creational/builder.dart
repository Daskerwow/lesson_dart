/// ============================================================================
/// ПАТТЕРН: BUILDER (Строитель)
/// Категория: Порождающий (Creational) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Отделяет конструирование сложного объекта от его представления, позволяя
/// использовать один и тот же процесс пошагового построения для создания
/// разных представлений объекта. Решает проблему "телескопических
/// конструкторов" (constructor с 10+ опциональными параметрами).
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Объект имеет много опциональных полей и должен собираться пошагово
///   (HTTP-запрос, диалоговое окно, сложный SQL-запрос, PDF-документ).
/// - Нужна fluent-цепочка вызовов (method chaining) для читаемости.
/// - Итоговый объект должен быть иммутабельным после сборки.
library;

/// Продукт — иммутабельный HTTP-запрос. Иммутабельность важна:
/// собранный запрос нельзя случайно изменить после отправки.
class HttpRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final Object? body;
  final Duration timeout;

  const HttpRequest._({
    required this.method,
    required this.url,
    required this.headers,
    required this.queryParams,
    required this.body,
    required this.timeout,
  });

  @override
  String toString() =>
      '$method ${url.toString()}\n'
      'Headers: $headers\n'
      'Query: $queryParams\n'
      'Body: $body\n'
      'Timeout: ${timeout.inSeconds}s';
}

/// СТРОИТЕЛЬ: пошагово накапливает состояние и в конце возвращает
/// готовый иммутабельный объект через build().
///
/// Каждый setter возвращает `this` — это позволяет использовать
/// fluent-интерфейс: builder.setX().setY().build().
class HttpRequestBuilder(String baseUrl) {
  String _method = 'GET';
  late Uri _baseUrl;
  final Map<String, String> _headers = {};
  final Map<String, String> _queryParams = {};
  Object? _body;
  Duration _timeout = const Duration(seconds: 30);

  this : _baseUrl = Uri.parse(baseUrl);

  HttpRequestBuilder method(String method) {
    _method = method;
    return this;
  }

  HttpRequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  HttpRequestBuilder bearerToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
    return this;
  }

  HttpRequestBuilder query(String key, String value) {
    _queryParams[key] = value;
    return this;
  }

  HttpRequestBuilder jsonBody(Map<String, dynamic> body) {
    _headers['Content-Type'] = 'application/json';
    _body = body;
    return this;
  }

  HttpRequestBuilder timeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// Финальный шаг: валидирует накопленное состояние и создаёт
  /// иммутабельный объект. Валидация здесь — важное преимущество
  /// Builder перед "голым" конструктором с именованными параметрами.
  HttpRequest build() {
    if (_method == 'GET' && _body != null) {
      throw StateError('GET-запрос не может содержать тело (body)');
    }
    final urlWithQuery = _baseUrl.replace(
      queryParameters: {..._baseUrl.queryParameters, ..._queryParams},
    );
    return HttpRequest._(
      method: _method,
      url: urlWithQuery,
      headers: Map.unmodifiable(_headers),
      queryParams: Map.unmodifiable(_queryParams),
      body: _body,
      timeout: _timeout,
    );
  }
}

void main() {
  // Fluent-цепочка читается почти как естественный язык —
  // главное преимущество Builder перед конструктором с 8 параметрами.
  final request = HttpRequestBuilder('https://api.example.com/users')
      .method('POST')
      .bearerToken('eyJhbGciOiJIUzI1NiIs...')
      .header('X-Request-Id', 'req-42')
      .query('notify', 'true')
      .jsonBody({'name': 'Иван', 'age': 30})
      .timeout(const Duration(seconds: 10))
      .build();

  print(request);

  // Попытка собрать невалидный запрос (GET с телом) упадёт при build(),
  // а не в рантайме где-то далеко от места создания.
  try {
    HttpRequestBuilder('https://api.example.com/x').jsonBody({'a': 1}).build();
  } on StateError catch (e) {
    print('Ошибка валидации: $e');
  }
}
