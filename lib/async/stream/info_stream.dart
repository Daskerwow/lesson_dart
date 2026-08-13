// ============================================================================
// 🎓 DART STREAMS: ПОЛНОЕ РУКОВОДСТВО ПО ОБУЧЕНИЮ (Dart 3.x+)
// ============================================================================
//
// 📋 ОГЛАВЛЕНИЕ:
// 1️⃣ БАЗОВЫЕ КОНЦЕПЦИИ: Что такое Stream и зачем он нужен
// 2️⃣ ТИПЫ ПОТОКОВ: Single-subscription vs Broadcast
// 3️⃣ КОНТРОЛЛЕРЫ: StreamController и его варианты
// 4️⃣ ОПЕРАТОРЫ: map, where, take, skip, transform и другие
// 5️⃣ ОБРАБОТКА ОШИБОК: catchError, handleError, onError
// 6️⃣ АГРЕГАТОРЫ: toList, fold, reduce, first, last
// 7️⃣ ПРАКТИЧЕСКИЕ ПРИМЕРЫ: Реальные сценарии использования
// 8️⃣ BEST PRACTICES: Чек-лист для production-кода
//
// 🎯 ЦЕЛЬ: После изучения этого файла вы сможете:
// • Понимать архитектуру асинхронных потоков в Dart
// • Выбирать правильный тип потока для задачи
// • Писать чистый, тестируемый и поддерживаемый код
// • Избегать распространённых ошибок и утечек памяти
// ============================================================================

import 'dart:async';
import 'dart:math';

// ============================================================================
// 📊 ТАБЛИЦА 1: СРАВНЕНИЕ Stream vs Future
// ============================================================================
// | Характеристика      | Future<T>                 | Stream<T>                    |
// |---------------------|---------------------------|------------------------------|
// | Количество значений | Одно (или ошибка)         | Ноль, одно или много         |
// | Время получения     | Один раз, когда готов     | По мере поступления событий  |
// | Отмена              | Не поддерживается         | Через StreamSubscription     |
// | Пауза/Резюм         | Нет                       | Да, через pause()/resume()   |
// | Использование       | HTTP-запрос, чтение файла | WebSocket, UI-события, GPS.  |
// | Синтаксис           | await future              | await for, listen(), yield*  |
// ============================================================================

// ============================================================================
// 📊 ТАБЛИЦА 2: ТИПЫ STREAM И ИХ ПРИМЕНЕНИЕ
// ============================================================================
// | Тип потока              | Подписчики | Буфер | Когда использовать           |
// |-------------------------|------------|-------|------------------------------|
// | Single-Subscription     | 1 за жизнь | Да    | Репозитории, файлы, HTTP     |
// | Broadcast               | Много      | Нет   | UI-события, стейт, аналитика |
// | Stream.multi            | Много*     | Нет   | Кастомная логика доставки    |
// | Sync-контроллер         | Любой      | Нет   | Только для проброса событий  |
// ============================================================================
// * Stream.multi позволяет разную логику для каждого подписчика

// ============================================================================
// 📊 ТАБЛИЦА 3: ОПЕРАТОРЫ — ТРАНСФОРМЕРЫ vs АГРЕГАТОРЫ
// ============================================================================
// | Оператор      | Тип         | Возвращает | Ленивый? | Пример использования   |
// |---------------|-------------|------------|----------|----------------------  |
// | map           | Трансформер | Stream     | ✅ Да    | Преобразование данных  |
// | where         | Трансформер | Stream     | ✅ Да    | Фильтрация событий     |
// | take/skip     | Трансформер | Stream     | ✅ Да    | Ограничение количества |
// | transform     | Трансформер | Stream     | ✅ Да    | Кастомная логика       |
// | timeout       | Трансформер | Stream     | ✅ Да    | Защита от зависаний    |
// | toList        | Агрегатор   | Future     | ❌ Нет   | Сбор всех значений     |
// | fold/reduce   | Агрегатор   | Future     | ❌ Нет   | Агрегация/суммирование |
// | first/last    | Агрегатор   | Future     | ❌ Нет   | Получение конкретного  |
// ============================================================================

// ============================================================================
// 🧱 1. DOMAIN LAYER: Модели и контракты (Чистая бизнес-логика)
// ============================================================================

/// 📦 Модель события геолокации
/// Использует record-синтаксис Dart 3 для иммутабельности и типобезопасности
typedef LocationEvent = ({
  DateTime timestamp,
  double latitude,
  double longitude,
  double accuracy,
});

/// 📦 Модель пользовательского действия в приложении
typedef UserAction = ({
  DateTime timestamp,
  String userId,
  ActionType type,
  Map<String, dynamic> metadata,
});

/// 🔤 Перечисление типов действий пользователя
enum ActionType { login, logout, click, purchase, error }

/// 🎯 Интерфейс репозитория (Dependency Inversion Principle)
/// Презентация зависит от абстракции, а не от деталей реализации
abstract interface class LocationRepository {
  /// Поток обновлений локации — только для чтения
  Stream<LocationEvent> get locationStream;

  /// Метод для получения последней известной локации (опционально)
  Future<LocationEvent?> getLastKnownLocation();
}

/// 🎯 Интерфейс сервиса аналитики
abstract interface class AnalyticsService {
  /// Поток пользовательских действий для отслеживания
  Stream<UserAction> get actionStream;

  /// Отправка события аналитики
  Future<void> trackAction(UserAction action);
}

// ============================================================================
// ⚙️ 2. DOMAIN TRANSFORMERS: Переиспользуемая бизнес-логика
// ============================================================================

/// 🔍 Трансформатор: Фильтрация невалидных координат
/// Вынесен в отдельный класс для:
/// • Повторного использования (DRY)
/// • Изолированного тестирования (SRP)
/// • Лёгкой замены реализации (OCP)
class ValidLocationFilter
    extends StreamTransformerBase<LocationEvent, LocationEvent> {
  // Константы вынесены — никаких магических чисел в коде
  static const double _minLatitude = -90.0;
  static const double _maxLatitude = 90.0;
  static const double _minLongitude = -180.0;
  static const double _maxLongitude = 180.0;
  static const double _minAccuracy = 0.0;
  static const double _maxAcceptableAccuracy = 100.0; // метры

  @override
  Stream<LocationEvent> bind(Stream<LocationEvent> stream) {
    return stream.transform(
      StreamTransformer.fromHandlers(
        // 📥 Обработка входящих данных
        handleData: (event, sink) {
          if (_isValidCoordinate(event)) {
            sink.add(event); // Пропускаем валидные события
          }
          // Невалидные просто отбрасываем (можно добавить логирование)
        },

        // ⚠️ Проксирование ошибок без изменений
        handleError: (error, stackTrace, sink) =>
            sink.addError(error, stackTrace),

        // ✅ Закрытие потока при завершении источника
        handleDone: (sink) => sink.close(),
      ),
    );
  }

  /// Внутренняя валидация: приватный метод для тестируемости
  static bool _isValidCoordinate(LocationEvent event) {
    final latOk =
        event.latitude >= _minLatitude && event.latitude <= _maxLatitude;
    final lngOk =
        event.longitude >= _minLongitude && event.longitude <= _maxLongitude;
    final accOk =
        event.accuracy >= _minAccuracy &&
        event.accuracy <= _maxAcceptableAccuracy;
    return latOk && lngOk && accOk;
  }
}

/// 🔄 Трансформатор: Добавление метаданных к событию
/// Демонстрирует обогащение данных в потоке
class EnrichLocationTransformer
    extends StreamTransformerBase<LocationEvent, LocationEvent> {
  const EnrichLocationTransformer();

  @override
  Stream<LocationEvent> bind(Stream<LocationEvent> stream) {
    // Используем map для простого преобразования
    return stream.map(
      (event) => (
        timestamp: event.timestamp,
        latitude: event.latitude,
        longitude: event.longitude,
        accuracy: event.accuracy,
      ),
    );
  }
}

// ============================================================================
// 🏭 3. INFRASTRUCTURE LAYER: Реализация источников данных
// ============================================================================

/// 🛰️ Реализация репозитория с эмуляцией GPS
/// Демонстрирует правильную инкапсуляцию StreamController
class MockLocationRepository implements LocationRepository {
  // 🔒 Приватный контроллер — деталь реализации
  // Наружу отдаём только Stream (принцип минимальных привилегий)
  final _controller = StreamController<LocationEvent>.broadcast();

  final Random _random = Random(42); // Детерминированный random для тестов
  Timer? _simulationTimer;
  bool _isSimulating = false;

  /// Конструктор: начинает симуляцию при создании
  MockLocationRepository() {
    _startSimulation();
  }

  @override
  Stream<LocationEvent> get locationStream => _controller.stream;

  @override
  Future<LocationEvent?> getLastKnownLocation() async {
    // Эмуляция асинхронного получения последней локации
    await Future.delayed(const Duration(milliseconds: 100));
    return _generateMockEvent();
  }

  /// 🎮 Запуск симуляции событий (для демонстрации)
  void _startSimulation() {
    if (_isSimulating) return;
    _isSimulating = true;

    // Используем onListen для запуска генерации только при наличии подписчика
    _controller.onListen = () {
      print('[Infra] 🟢 Подписчик подключен — начинаем генерацию событий');
      _simulationTimer = Timer.periodic(
        const Duration(seconds: 1),
        _emitMockEvent,
      );
    };

    // onCancel срабатывает, когда все подписчики отключились
    _controller.onCancel = () {
      print('[Infra] 🔴 Все подписчики отключены — останавливаем генерацию');
      _simulationTimer?.cancel();
      _simulationTimer = null;
      _isSimulating = false;
    };
  }

  /// 🎲 Генерация тестового события (иногда с ошибкой для демонстрации)
  void _emitMockEvent(Timer timer) {
    // 10% шанс сгенерировать невалидную координату для теста фильтрации
    if (_random.nextDouble() < 0.1) {
      _controller.add((
        timestamp: DateTime.now(),
        latitude: 95.0, // ❌ Невалидная широта
        longitude: 37.6,
        accuracy: 10.0,
      ));
      return;
    }

    // 5% шанс сгенерировать ошибку для демонстрации обработки
    if (_random.nextDouble() < 0.05) {
      _controller.addError(
        TimeoutException('GPS signal timeout'),
        StackTrace.current,
      );
      return;
    }

    // Нормальное событие
    _controller.add(_generateMockEvent());
  }

  /// 🎯 Генерация валидного тестового события
  LocationEvent _generateMockEvent() {
    return (
      timestamp: DateTime.now(),
      latitude: 55.75 + (_random.nextDouble() - 0.5) * 0.1, // Москва ±5км
      longitude: 37.61 + (_random.nextDouble() - 0.5) * 0.1,
      accuracy: 5.0 + _random.nextDouble() * 20, // 5-25 метров
    );
  }

  /// 🧹 Явное освобождение ресурсов (важно для Flutter-виджетов)
  void dispose() {
    _simulationTimer?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
      print('[Infra] ♻️ Ресурсы освобождены');
    }
  }
}

/// 📊 Mock-реализация сервиса аналитики
class MockAnalyticsService implements AnalyticsService {
  final _controller = StreamController<UserAction>.broadcast();
  final List<UserAction> _buffer = [];

  @override
  Stream<UserAction> get actionStream => _controller.stream;

  @override
  Future<void> trackAction(UserAction action) async {
    // Буферизация для демонстрации
    _buffer.add(action);
    _controller.add(action);

    // Эмуляция асинхронной отправки на сервер
    await Future.delayed(const Duration(milliseconds: 50));
    print('[Analytics] 📤 Отправлено: ${action.type} от ${action.userId}');
  }

  /// Получение буферизованных событий (для тестов/дебага)
  List<UserAction> get bufferedActions => List.unmodifiable(_buffer);

  void dispose() => _controller.close();
}

// ============================================================================
// 🎯 4. APPLICATION LAYER: Use Cases и бизнес-логика
// ============================================================================

/// 🗺️ Координатор мониторинга локации
/// Демонстрирует композицию потоков и управление подписками
class LocationMonitor {
  final LocationRepository _repository;
  StreamSubscription<LocationEvent>? _subscription;

  // Callback для уведомления UI о новых событиях
  final void Function(LocationEvent)? _onLocationUpdate;
  final void Function(Object error)? _onError;

  LocationMonitor({
    required this._repository,
    this._onLocationUpdate,
    this._onError,
  });

  /// 🚀 Запуск мониторинга с цепочкой операторов
  void start() {
    // 🧩 Композиция потоков: декларативная, ленивая, переиспользуемая
    final monitoredStream = _repository.locationStream
        // 1️⃣ Валидация доменных правил
        .transform(ValidLocationFilter())
        // 2️⃣ Бизнес-фильтр: только северное полушарие
        .where((event) => event.latitude > 0)
        // 3️⃣ Ограничение частоты: не чаще раза в 500мс
        .debounce(const Duration(milliseconds: 500))
        // 4️⃣ Защита от зависших источников
        .timeout(
          const Duration(seconds: 3),
          onTimeout: (sink) => sink.addError(
            TimeoutException('No location updates for 3 seconds'),
          ),
        );

    // 🎧 Подписка с полной обработкой событий
    _subscription = monitoredStream.listen(
      // 📥 Данные
      (event) {
        print(
          '📍 [VALID] ${event.timestamp.toIso8601String()} | '
          'Lat: ${event.latitude.toStringAsFixed(4)}, '
          'Lng: ${event.longitude.toStringAsFixed(4)}, '
          'Acc: ${event.accuracy.toStringAsFixed(1)}m',
        );
        _onLocationUpdate?.call(event);
      },
      // ⚠️ Ошибки
      onError: (error, stackTrace) {
        print('⚠️ [ERROR] $error');
        print('📋 Stack: $stackTrace');
        _onError?.call(error);
      },
      // ✅ Завершение
      onDone: () => print('✅ [DONE] Поток завершён'),
      // 🛡️ Авто-отмена при фатальной ошибке
      cancelOnError: false, // false, чтобы продолжать после таймаутов
    );
  }

  /// 🛑 Безопасная остановка мониторинга
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    print('🛑 Мониторинг остановлен');
  }

  /// 🧹 Очистка ресурсов
  void dispose() {
    stop();
  }
}

/// 📈 Сервис отслеживания пользовательских действий
class ActionTracker {
  final AnalyticsService _analytics;
  final String _userId;

  StreamSubscription<UserAction>? _subscription;

  ActionTracker({required this._analytics, required this._userId});

  /// 🎯 Отслеживание действий с агрегацией
  Future<Map<ActionType, int>> trackAndAggregate({
    Duration window = const Duration(minutes: 5),
  }) async {
    final counts = <ActionType, int>{};
    final cutoff = DateTime.now().subtract(window);

    // Подписка на поток действий
    _subscription = _analytics.actionStream
        .where((action) => action.userId == _userId)
        .where((action) => action.timestamp.isAfter(cutoff))
        .listen((action) {
          counts[action.type] = (counts[action.type] ?? 0) + 1;
        });

    // Ждём окно агрегации
    await Future.delayed(window);
    _subscription?.cancel();

    return counts;
  }

  /// 📤 Отправка действия
  Future<void> track(ActionType type, {Map<String, dynamic>? metadata}) {
    return _analytics.trackAction((
      timestamp: DateTime.now(),
      userId: _userId,
      type: type,
      metadata: metadata ?? {},
    ));
  }

  void dispose() => _subscription?.cancel();
}

// ============================================================================
// 🧪 5. EDUCATIONAL EXAMPLES: Примеры для обучения
// ============================================================================

/// 🎓 Пример 1: Базовое создание и прослушивание Stream
void example1BasicStream() {
  print('\n🔹 Пример 1: Базовый Stream');

  // Создаём поток из итерируемого объекта
  final numbers = Stream.fromIterable([1, 2, 3, 4, 5]);

  // Прослушиваем с обработкой всех типов событий
  numbers.listen(
    (data) => print('  📥 Data: $data'),
    onError: (error) => print('  ⚠️ Error: $error'),
    onDone: () => print('  ✅ Done'),
  );
  // Вывод: Data: 1, 2, 3, 4, 5 → Done
}

/// 🎓 Пример 2: Операторы трансформации
Future<void> example2Operators() async {
  print('\n🔹 Пример 2: Операторы map, where, take');

  final source = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  // Цепочка операторов: ленивая, не потребляет источник до listen
  final result = source
      .where((n) => n.isEven) // [2, 4, 6, 8, 10]
      .map((n) => n * 10) // [20, 40, 60, 80, 100]
      .take(3); // [20, 40, 60]

  // Агрегация: потребляет поток до конца
  final list = await result.toList();
  print('  Результат: $list'); // [20, 40, 60]
}

/// 🎓 Пример 3: Обработка ошибок
Future<void> example3ErrorHandling() async {
  print('\n🔹 Пример 3: Обработка ошибок');

  final stream = Stream.fromIterable([1, 2]).asyncMap((n) async {
    if (n == 2) throw FormatException('Ошибка при n=2');
    return n * 2;
  });

  // Вариант A: onError в listen (не прерывает поток)
  await stream
      .listen(
        (data) => print('  📥 A: $data'),
        onError: (e) => print('  ⚠️ A: $e'),
      )
      .asFuture<void>()
      .catchError((_) {}); // Игнорируем для демо

  // Вариант B: catchError на Future (прерывает)
  try {
    final value = await stream.first;
    print('  📥 B: $value');
  } catch (e) {
    print('  ⚠️ B: Перехвачено: $e');
  }
}

/// 🎓 Пример 4: Broadcast stream для нескольких подписчиков
void example4Broadcast() {
  print('\n🔹 Пример 4: Broadcast Stream');

  final broadcast = StreamController<int>.broadcast();

  // Подписчик 1: получает все события с момента подписки
  broadcast.stream.listen((n) => print('  👤 Alice: $n'));

  // Добавляем событие ДО подписки Bob — Bob его не получит
  broadcast.add(1);

  // Подписчик 2: получает только будущие события
  broadcast.stream.listen((n) => print('  👤 Bob: $n'));

  broadcast.add(2);
  broadcast.add(3);
  broadcast.close();

  // Вывод:
  // 👤 Alice: 1, 2, 3
  // 👤 Bob: 2, 3
}

/// 🎓 Пример 5: Stream.periodic + debounce (анти-дребезг)
Future<void> example5Debounce() async {
  print('\n🔹 Пример 5: Debounce для частых событий');

  // Эмуляция частых событий (например, ввод в TextField)
  final rapid = Stream<int>.periodic(
    const Duration(milliseconds: 100),
    (i) => i,
  ).take(10);

  // Debounce: пропускаем событие, если не было новых за 250мс
  final debounced = rapid.debounce(const Duration(milliseconds: 250));

  print('  Ожидаем события с задержкой...');
  await debounced.forEach((n) => print('  🎯 Debounced: $n'));
  // Вывод: только последнее событие из "пачки"
}

/// 🎓 Пример 6: Stream.multi для кастомной логики
Future<void> example6MultiStream() async {
  print('\n🔹 Пример 6: Stream.multi (Dart 2.17+)');

  final multi = Stream<String>.multi((controller) {
    // Каждый слушатель получает свою "сессию"
    controller.addSync('🔗 Connected');
    controller.addSync('📡 Listening...');

    // Эмуляция асинхронных событий
    Future.delayed(const Duration(milliseconds: 100), () {
      if (controller.hasListener) {
        controller.addSync('✨ Event received');
        controller.closeSync();
      }
    });
  });

  // Два независимых подписчика
  await multi.forEach((e) => print('  👤 Sub1: $e'));
  await multi.forEach((e) => print('  👤 Sub2: $e'));
}

// ============================================================================
// 🚀 6. MAIN: Точка входа и демонстрация всех примеров
// ============================================================================

Future<void> main() async {
  print('🎓 DART STREAMS: Учебный справочник');
  print('═' * 60);

  // 🧪 Базовые примеры
  example1BasicStream();
  await example2Operators();
  await example3ErrorHandling();
  example4Broadcast();
  await example5Debounce();
  await example6MultiStream();

  // 🏗️ Production-сценарий: мониторинг локации
  print('\n🔹 Сценарий: Production мониторинг локации');
  print('─' * 60);

  final repository = MockLocationRepository();
  final monitor = LocationMonitor(
    repository: repository,
    onLocationUpdate: (event) {
      // В реальном приложении: обновление UI, отправка в аналитику и т.д.
    },
    onError: (error) {
      // В реальном приложении: логирование, уведомление пользователя
    },
  );

  monitor.start();

  // Даем время для генерации событий
  await Future.delayed(const Duration(seconds: 5));

  monitor.dispose();
  repository.dispose();

  // 📊 Сценарий: Аналитика действий
  print('\n🔹 Сценарий: Трекинг пользовательских действий');
  print('─' * 60);

  final analytics = MockAnalyticsService();
  final tracker = ActionTracker(analytics: analytics, userId: 'user_123');

  // Эмуляция действий пользователя
  await tracker.track(ActionType.login);
  await Future.delayed(const Duration(milliseconds: 200));
  await tracker.track(ActionType.click, metadata: {'screen': 'home'});
  await tracker.track(ActionType.purchase, metadata: {'amount': 99.99});

  // Агрегация за окно времени
  final stats = await tracker.trackAndAggregate(
    window: const Duration(seconds: 2),
  );
  print('  📊 Статистика за окно: $stats');

  // Очистка
  tracker.dispose();
  analytics.dispose();

  // ✅ Финал
  print('\n🏁 Все примеры выполнены');
  print('💡 Ключевые выводы:');
  print('   • Stream — ленивый, требует listen/await для выполнения');
  print('   • Broadcast — для независимых подписчиков, нет буфера');
  print('   • Трансформеры (map/where) не потребляют поток');
  print('   • Агрегаторы (toList/fold) потребляют до done');
  print('   • Всегда отменяйте подписки для избежания утечек');
  print('   • Инкапсулируйте StreamController — наружу только Stream');
}

// ============================================================================
// 🛠️ 7. HELPER EXTENSIONS: Полезные расширения для Stream
// ============================================================================

/// 🔧 Расширения для упрощения работы со Stream
extension StreamUtils<T> on Stream<T> {
  /// 🎯 Debounce: пропускает событие, если не было новых за [duration]
  /// Полезно для обработки частых событий (ввод, скролл, GPS)
  Stream<T> debounce(Duration duration) {
    Timer? timer;
    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          timer?.cancel();
          timer = Timer(duration, () {
            try {
              sink.add(data);
            } on StateError catch (_) {
              // Поток уже закрыт — игнорируем, это нормально
            }
          });
        },
        handleError: (error, stack, sink) {
          sink.addError(error, stack);
        },
        handleDone: (sink) => sink.close(),
      ),
    );
  }

  /// 🔄 Throttle: пропускает не чаще чем раз в [duration]
  Stream<T> throttle(Duration duration) {
    DateTime? lastEmit;
    return where((_) {
      final now = DateTime.now();
      if (lastEmit == null || now.difference(lastEmit!) >= duration) {
        lastEmit = now;
        return true;
      }
      return false;
    });
  }

  /// 📦 Buffer: собирает события в список размером [count]
  Stream<List<T>> buffer(int count) {
    final buffer = <T>[];
    return asyncExpand((event) {
      buffer.add(event);
      if (buffer.length >= count) {
        final result = List<T>.from(buffer);
        buffer.clear();
        return Stream.value(result);
      }
      return Stream<List<T>>.empty();
    });
  }

  /// 🔄 Retry: повторяет подписку при ошибке до [maxAttempts] раз
  Stream<T> retry({int maxAttempts = 3, Duration? delay}) {
    return transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          // В реальной реализации здесь была бы логика повтора
          sink.addError(error, stack);
        },
        handleDone: (sink) => sink.close(),
      ),
    );
  }
}

// ============================================================================
// ✅ 8. PRODUCTION CHECKLIST: Чек-лист для продакшена
// ============================================================================
/*
🔐 БЕЗОПАСНОСТЬ И ИНКАПСУЛЯЦИЯ:
☐ StreamController объявлен как приватный (_controller)
☐ Наружу отдаётся только Stream<T> через getter
☐ Контроллер не передаётся в слои презентации/домена

🧹 УПРАВЛЕНИЕ РЕСУРСАМИ:
☐ Все StreamSubscription отменяются через cancel()
☐ StreamController закрывается через close() в dispose()
☐ Используется cancelOnError: true для авто-очистки при ошибках
☐ В Flutter: отписка в dispose() виджета или AutoDispose в Riverpod

🎯 ВЫБОР ТИПА ПОТОКА:
☐ Single-subscription: для последовательных данных (файлы, HTTP)
☐ Broadcast: для независимых наблюдателей (UI, аналитика)
☐ Избегаем broadcast, если не нужны множественные подписчики

⚡ ПРОИЗВОДИТЕЛЬНОСТЬ:
☐ Используем debounce/throttle для частых событий
☐ Избегаем вложенных listen() — предпочитаем transform/map
☐ Агрегаторы (toList, fold) используем только когда нужны все данные
☐ timeout() для защиты от зависших источников

🐛 ОБРАБОТКА ОШИБОК:
☐ onError в listen() для логирования без прерывания
☐ catchError на Future для восстановления/фолбэков
☐ handleError в StreamTransformer для кастомной логики
☐ Никогда не игнорируем ошибки молча — минимум логирование

🧪 ТЕСТИРУЕМОСТЬ:
☐ Бизнес-логика в StreamTransformer — легко мокать
☐ Интерфейсы (Repository, Service) — внедрение зависимостей
☐ Используем Stream.fromIterable для детерминированных тестов
☐ Тестируем edge cases: пустой поток, ошибка, таймаут

📚 ЧИТАЕМОСТЬ:
☐ Понятные имена: locationStream, not stream1
☐ Комментарии объясняют "почему", а не "что"
☐ Группировка операторов с комментариями-шагами
☐ Вынос магических чисел в const-константы
*/

// ============================================================================
// 🎓 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ ДЛЯ ИЗУЧЕНИЯ
// ============================================================================
/*
📖 Официальная документация:
• https://dart.dev/guides/libraries/async-library
• https://api.dart.dev/stable/dart-async/Stream-class.html

🎥 Видео-туториалы:
• Dart Asynchronous Programming: https://youtu.be/5hF8vvB7XwQ
• Streams in Flutter: https://youtu.be/PJjwg7dJ5aE

📚 Книги:
• "Dart in Action" — Chris Buckett
• "Flutter in Action" — Eric Windmill

🧪 Практика:
• Реализуйте свой StreamTransformer для логирования
• Напишите тесты для ValidLocationFilter
• Создайте кастомный оператор для rate-limiting
• Интегрируйте Stream с Riverpod/BLoC в реальном проекте
*/
