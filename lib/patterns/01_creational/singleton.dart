/// ============================================================================
/// ПАТТЕРН: SINGLETON (Одиночка)
/// Категория: Порождающий (Creational) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Гарантирует, что у класса есть только один экземпляр, и предоставляет
/// глобальную точку доступа к нему. Используется, когда ровно один объект
/// должен координировать действия во всей системе (конфигурация, логгер,
/// пул соединений, кэш, реестр сервисов).
///
/// КОГДА ИСПОЛЬЗОВАТЬ:
/// - Нужен единственный источник правды: конфигурация приложения, логгер.
/// - Создание объекта дорого (подключение к БД, файловый дескриптор),
///   и повторное создание недопустимо.
/// - Нужен централизованный доступ к ресурсу, разделяемому всей программой.
///
/// КОГДА НЕ ИСПОЛЬЗОВАТЬ (и почему это спорный паттерн):
/// - Singleton — это, по сути, глобальное изменяемое состояние. Он усложняет
///   unit-тестирование (нельзя легко подменить mock), создаёт скрытые
///   зависимости между модулями и нарушает принцип единственной
///   ответственности, если начинает "разрастаться".
/// - В большинстве случаев лучше использовать Dependency Injection
///   (см. 06_enterprise/dependency_injection.dart) и передавать один и тот
///   же экземпляр через конструктор, а не обращаться к глобальному объекту.
///
/// РЕАЛИЗАЦИЯ В DART:
/// В Dart есть встроенный идиоматичный способ через `factory`-конструктор
/// и статическое приватное поле — это самый распространённый вариант.
library;

// -----------------------------------------------------------------------
// ПРИМЕР 1: AppConfig — глобальная неизменяемая конфигурация приложения.
// Типичный продакшен-кейс: конфиг читается один раз при старте приложения
// (например, из .env или remote config) и переиспользуется везде.
// -----------------------------------------------------------------------
class AppConfig {
  // Приватный статический экземпляр — единственный на всё приложение.
  static AppConfig? _instance;

  // Поля конфигурации. В реальном проекте — apiBaseUrl, флаги фич,
  // таймауты сети и т.д.
  final String apiBaseUrl;
  final Duration networkTimeout;
  final bool isProduction;

  // Приватный именованный конструктор — снаружи создать объект напрямую
  // невозможно (`AppConfig._internal(...)` недоступен вне библиотеки).
  AppConfig._internal({
    required this.apiBaseUrl,
    required this.networkTimeout,
    required this.isProduction,
  });

  /// Единственный способ получить экземпляр. При первом вызове создаёт
  /// объект, при последующих — возвращает уже созданный.
  ///
  /// ВАЖНО: инициализация должна произойти один раз при старте приложения
  /// (обычно в main()), чтобы избежать состояния гонки при параллельном
  /// первом обращении из нескольких мест.
  factory AppConfig.initialize({
    required String apiBaseUrl,
    Duration networkTimeout = const Duration(seconds: 30),
    bool isProduction = false,
  }) {
    // Если уже инициализирован — просто возвращаем существующий,
    // повторная инициализация игнорируется (иначе конфиг "плавал" бы
    // в рантайме, что опасно).
    return _instance ??= AppConfig._internal(
      apiBaseUrl: apiBaseUrl,
      networkTimeout: networkTimeout,
      isProduction: isProduction,
    );
  }

  /// Доступ к уже инициализированному конфигу из любой точки приложения.
  /// Бросает исключение, если конфиг ещё не был проинициализирован —
  /// это явная и предсказуемая ошибка вместо "тихого" null.
  static AppConfig get instance {
    final inst = _instance;

    if (inst == null) {
      throw StateError(
        'AppConfig не инициализирован. Вызовите AppConfig.initialize() '
        'в начале main() перед первым использованием.',
      );
    }

    return inst;
  }

  /// Полезно для unit-тестов: сбросить singleton между тестами,
  /// чтобы тесты не влияли друг на друга через общее состояние.
  static void resetForTesting() => _instance = null;

  @override
  String toString() =>
      'AppConfig(apiBaseUrl: $apiBaseUrl, prod: $isProduction)';
}

// -----------------------------------------------------------------------
// ПРИМЕР 2: Logger — классический "ленивый" Singleton через `factory`.
// Использует внутренний буфер и потокобезопасную (в терминах Dart —
// изолят-безопасную) запись логов.
// -----------------------------------------------------------------------
enum LogLevel { debug, info, warning, error }

class Logger {
  // static final инициализируется лениво и ровно один раз в Dart —
  // это потокобезопасно в рамках одного изолята.
  static final Logger _instance = Logger._internal();

  final List<String> _buffer = [];

  Logger._internal();

  /// factory-конструктор — при каждом `Logger()` возвращается один и тот же
  /// объект. Это самый идиоматичный способ Singleton в Dart.
  factory Logger() => _instance;

  void log(LogLevel level, String message) {
    final entry =
        '[${DateTime.now().toIso8601String()}] '
        '${level.name.toUpperCase()}: $message';
    _buffer.add(entry);
    // В реальном проекте здесь была бы запись в файл / отправка в Sentry /
    // вывод в консоль в зависимости от окружения.
    // ignore: avoid_print
    print(entry);
  }

  List<String> get history => List.unmodifiable(_buffer);
}

// -----------------------------------------------------------------------
// ДЕМОНСТРАЦИЯ ИСПОЛЬЗОВАНИЯ
// -----------------------------------------------------------------------
void main() {
  // Инициализация происходит один раз при старте приложения.
  AppConfig.initialize(
    apiBaseUrl: 'https://api.example.com',
    isProduction: true,
  );

  // Далее из любого места кода — тот же самый экземпляр.
  print(AppConfig.instance);
  print(identical(AppConfig.instance, AppConfig.instance)); // true

  final logger1 = Logger();
  final logger2 = Logger();
  logger1.log(LogLevel.info, 'Приложение запущено');
  logger2.log(LogLevel.warning, 'Логгер тот же самый экземпляр');

  // Доказательство, что это один и тот же объект в памяти.
  print('logger1 == logger2: ${identical(logger1, logger2)}'); // true
  print('Всего записей в логе: ${logger1.history.length}');
}

class _GetItImplementation implements GetIt {}

// Пример из GetIt
abstract class GetIt {
  static final GetIt _instance = _GetItImplementation();

  /// access to the Singleton instance of GetIt
  static GetIt get instance => _instance;

  /// Short form to access the instance of GetIt
  static GetIt get I => _instance;
}
