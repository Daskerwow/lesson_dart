/// ============================================================================
/// ПАТТЕРН: CHAIN OF RESPONSIBILITY (Цепочка обязанностей)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет передавать запрос по цепочке обработчиков, пока один из них
/// не обработает его. Отправитель запроса не знает, какой именно обработчик
/// в итоге его обработает — обработчики связаны в цепочку, и каждый решает
/// сам: обработать запрос или передать дальше.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - HTTP middleware pipeline (аутентификация -> авторизация -> валидация
///   -> rate limiting -> обработчик запроса).
/// - Многоуровневая система обработки заявок на поддержку (L1 -> L2 -> L3).
/// - Валидация форм с цепочкой независимых правил.
library;

/// Контекст запроса, который проходит по цепочке middleware.
class HttpContext {
  final String path;
  final Map<String, String> headers;
  String? userId; // заполняется в процессе прохождения по цепочке
  int statusCode = 200;
  String? responseBody;
  bool _handled = false;

  HttpContext(this.path, this.headers);

  void shortCircuit(int code, String body) {
    statusCode = code;
    responseBody = body;
    _handled = true;
  }

  bool get isHandled => _handled;
}

/// Абстрактный обработчик — хранит ссылку на следующего в цепочке.
abstract class Middleware {
  Middleware? _next;

  /// Связывает текущий обработчик со следующим, возвращая его —
  /// это позволяет строить цепочку fluent-синтаксисом: a.setNext(b).setNext(c).
  Middleware setNext(Middleware next) {
    _next = next;
    return next;
  }

  /// Шаблонный метод: выполняет свою проверку, и если запрос не был
  /// "коротко замкнут" (отклонён) — передаёт дальше по цепочке.
  void handle(HttpContext ctx) {
    process(ctx);
    if (!ctx.isHandled && _next != null) {
      _next!.handle(ctx);
    }
  }

  /// Конкретная логика обработчика — переопределяется в наследниках.
  void process(HttpContext ctx);
}

class AuthMiddleware extends Middleware {
  @override
  void process(HttpContext ctx) {
    final token = ctx.headers['Authorization'];
    if (token == null) {
      ctx.shortCircuit(401, 'Unauthorized: токен отсутствует');
      return;
    }
    // Имитация валидации токена и извлечения userId.
    ctx.userId = 'user_from_token_${token.hashCode}';
    print('[Auth] Пользователь ${ctx.userId} аутентифицирован');
  }
}

class RateLimitMiddleware extends Middleware {
  final Map<String, int> _requestCounts = {};
  final int limit;
  RateLimitMiddleware(this.limit);

  @override
  void process(HttpContext ctx) {
    final userId = ctx.userId ?? 'anonymous';
    final count = (_requestCounts[userId] ?? 0) + 1;
    _requestCounts[userId] = count;
    if (count > limit) {
      ctx.shortCircuit(429, 'Too Many Requests');
      return;
    }
    print('[RateLimit] Запрос $count/$limit для $userId');
  }
}

class ValidationMiddleware extends Middleware {
  @override
  void process(HttpContext ctx) {
    if (ctx.path.isEmpty) {
      ctx.shortCircuit(400, 'Bad Request: пустой путь');
      return;
    }
    print('[Validation] Путь "${ctx.path}" прошёл валидацию');
  }
}

class RequestHandler extends Middleware {
  @override
  void process(HttpContext ctx) {
    ctx.shortCircuit(200, 'OK: обработан запрос ${ctx.path} для ${ctx.userId}');
  }
}

void main() {
  // Собираем цепочку в нужном порядке.
  final auth = AuthMiddleware();
  final rateLimit = RateLimitMiddleware(2);
  final validation = ValidationMiddleware();
  final handler = RequestHandler();

  auth.setNext(rateLimit).setNext(validation).setNext(handler);

  final ctx1 = HttpContext('/api/users', {'Authorization': 'Bearer xyz'});
  auth.handle(ctx1);
  print('Результат: ${ctx1.statusCode} ${ctx1.responseBody}\n');

  // Без заголовка авторизации цепочка остановится на первом же звене.
  final ctx2 = HttpContext('/api/users', {});
  auth.handle(ctx2);
  print('Результат: ${ctx2.statusCode} ${ctx2.responseBody}');
}
