/// ============================================================================
/// ПАТТЕРН: DECORATOR (Декоратор)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Динамически добавляет объекту новые обязанности, оборачивая его в объекты
/// декораторов с тем же интерфейсом. Гибкая альтернатива наследованию —
/// позволяет комбинировать поведения в рантайме в любом порядке.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Middleware-цепочки HTTP-клиентов (логирование, retry, кэш, авторизация).
/// - UI-компоненты Flutter (Padding, Border, Container — по сути декораторы).
/// - Когда комбинаций опций так много, что наследование дало бы
///   комбинаторный взрыв подклассов.
library;

abstract class DataFetcher {
  Future<String> fetch(String url);
}

/// Базовый компонент (Concrete Component).
class HttpDataFetcher implements DataFetcher {
  @override
  Future<String> fetch(String url) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'Данные с $url';
  }
}

/// Базовый класс декоратора: хранит "обёрнутый" компонент.
abstract class const DataFetcherDecorator(final DataFetcher wrapped)
    implements DataFetcher {}

class const LoggingDecorator(super.wrapped) extends DataFetcherDecorator {
  @override
  Future<String> fetch(String url) async {
    print('[LOG] -> Запрос: $url');
    final stopwatch = Stopwatch()..start();
    final result = await wrapped.fetch(url);
    stopwatch.stop();
    print('[LOG] <- Ответ за ${stopwatch.elapsedMilliseconds}мс');
    return result;
  }
}

class CachingDecorator(super.wrapped) extends DataFetcherDecorator {
  final Map<String, String> _cache = {};

  @override
  Future<String> fetch(String url) async {
    /// Смотрим есть ли в кеше ответ
    if (_cache.containsKey(url)) {
      print('[CACHE] Попадание в кэш для $url');
      return _cache[url]!;
    }

    /// Если нету то получаем ответ по url
    final result = await wrapped.fetch(url);

    /// ложим его в кеш
    _cache[url] = result;

    /// Отдаем
    return result;
  }
}

class const RetryDecorator(super.wrapped, {final int maxAttempts = 3})
    extends DataFetcherDecorator {
  @override
  Future<String> fetch(String url) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await wrapped.fetch(url);
      } catch (e) {
        lastError = e;
        print('[RETRY] Попытка $attempt/$maxAttempts не удалась: $e');
      }
    }
    throw StateError('Все попытки исчерпаны: $lastError');
  }
}

void main() async {
  final DataFetcher fetcher = LoggingDecorator(
    CachingDecorator(RetryDecorator(HttpDataFetcher())),
  );

  print(await fetcher.fetch('https://api.example.com/data'));
  print(await fetcher.fetch('https://api.example.com/data'));
}
