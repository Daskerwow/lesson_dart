// ignore_for_file: avoid_print, unused_local_variable, unused_element

/// {@template future_cheatsheet}
/// FUTURE CHEAT SHEET v2.1 — Production-Ready Examples
///
/// Назначение: исчерпывающее руководство по работе с Future в Dart
/// {@endtemplate}
// ignore: dangling_library_doc_comments
library;

import 'dart:async';
import 'dart:math';

// ============================================================================
// 🎯 1. БАЗОВЫЕ КОНЦЕПЦИИ: Event Loop и Microtask Queue
// ============================================================================

/// 📊 Визуализация очереди событий Dart:
///
/// ```text
/// ┌─────────────────────────────────────┐
/// │         CALL STACK (синхронный)     │
/// │  • main()                           │
/// │  • print()                          │
/// └────────────────┬────────────────────┘
///                  ▼
/// ┌─────────────────────────────────────┐
/// │      MICROTASK QUEUE (приоритет)    │
/// │  • Future.microtask()               │
/// │  • scheduleMicrotask()              │
/// └────────────────┬────────────────────┘
///                  ▼
/// ┌─────────────────────────────────────┐
/// │       EVENT QUEUE (обычные задачи)  │
/// │  • Future.delayed()                 │
/// │  • Timer() / I/O / UI события       │
/// └─────────────────────────────────────┘
/// ```

Future<void> demonstrateEventLoopOrder() async {
  print('\n🔄 Event Loop Order Demo');
  print('─' * 50);

  print('1️⃣ [SYNC] Начало выполнения');

  /// ⚡ Правило: Microtasks выполняются ДО следующих Event tasks!
  Future.microtask(() => print('3️⃣ [MICRO] Future.microtask'));
  Future(() => print('5️⃣ [EVENT] Future() без задержки'));
  scheduleMicrotask(() => print('2️⃣ [MICRO] scheduleMicrotask'));

  Future.delayed(
    Duration.zero,
    () => print('4️⃣ [EVENT] Future.delayed(Duration.zero)'),
  );

  Future.delayed(
    const Duration(milliseconds: 100),
    () => print('6️⃣ [EVENT] Future.delayed(100ms)'),
  );

  await Future.delayed(const Duration(milliseconds: 150));
  print('7️⃣ [SYNC] Конец демонстрации');
}

// ============================================================================
// 🔧 2. КОНСТРУКТОРЫ FUTURE
// ============================================================================

/// 📦 Future.value() — для уже готового значения
Future<void> demonstrateFutureValue() async {
  print('\n📦 Future.value() — мгновенное завершение');

  final cachedUser = Future.value(User(id: 42, name: 'Cached'));
  final user = await cachedUser;
  print('   Получено: $user');
}

class User {
  final int id;
  final String name;

  const User({required this.id, required this.name});

  @override
  String toString() => 'User(id: $id, name: $name)';
}

/// 🔄 Future.sync() — синхронное вычисление, асинхронный результат
/// ❗ ВАЖНО: Future.sync не принимает type-параметры в конструкторе!
/// Тип выводится из возвращаемого значения функции.
Future<void> demonstrateFutureSync() async {
  print('\n🔄 Future.sync() — синхронное вычисление в Future');

  try {
    // ✅ Правильно: тип выводится из return
    final result = await Future.sync(() {
      print('   → Вычисление происходит СРАЗУ');
      return 42 * 2; // Dart выводит Future<int>
    });
    print('   Результат: $result');
  } catch (e) {
    print('   Ошибка перехвачена: $e');
  }
}

/// ⏱️ Future.delayed() — отложенное выполнение
Future<void> demonstrateFutureDelayed() async {
  print('\n⏱️ Future.delayed() — отложенное выполнение');

  final stopwatch = Stopwatch()..start();

  final result = await Future.delayed(const Duration(milliseconds: 300), () {
    print('   → Задача выполнена после задержки');
    return 'Готово!';
  });

  stopwatch.stop();
  print(
    '   Результат: $result (затрачено: ${stopwatch.elapsedMilliseconds}ms)',
  );
}

/// 🚨 Future.error() — создание завершённого с ошибкой Future
Future<void> demonstrateFutureError() async {
  print('\n🚨 Future.error() — завершение с ошибкой');

  try {
    await Future.error(
      ApiException('Пользователь не найден', code: 404),
      StackTrace.current,
    );
  } on ApiException catch (e) {
    print('   Перехвачена бизнес-ошибка: ${e.message} (код: ${e.code})');
  } catch (e, _) {
    print('   Неожиданная ошибка: $e');
  }
}

/// 🧵 Future.microtask() — выполнение в микрозадаче
Future<void> demonstrateFutureMicrotask() async {
  print('\n🧵 Future.microtask() — приоритетная очередь');

  print('   [SYNC] Старт');

  Future.microtask(() => print('   [MICRO] 1-я микрозадача'));
  Future.microtask(() => print('   [MICRO] 2-я микрозадача'));
  Future(() => print('   [EVENT] Обычная задача'));

  await Future.delayed(Duration.zero);
  print('   [SYNC] Финиш');
}

// ============================================================================
// ⚡ 3. МЕТОДЫ-ОПЕРАТОРЫ
// ============================================================================

/// 🔗 then() — трансформация успешного результата
Future<void> demonstrateThenChaining() async {
  print('\n🔗 then() — цепочки трансформации');

  final result = await Future.value(5)
      .then((value) {
        print('   Шаг 1: исходное значение = $value');
        return value * 2;
      })
      .then((value) {
        print('   Шаг 2: умножили на 2 = $value');
        return Future.delayed(
          const Duration(milliseconds: 100),
          () => '$value рублей',
        );
      })
      .then((value) {
        print('   Шаг 3: форматировали = $value');
        return value.toUpperCase();
      });

  print('   ✅ Итог: $result');
}

/// 🛡️ catchError() — централизованная обработка ошибок
Future<void> demonstrateCatchError() async {
  print('\n🛡️ catchError() — обработка ошибок в цепочке');

  // ❗ ВАЖНО: обработчик должен возвращать значение того же типа!
  final result = await Future.error(DatabaseException('Connection lost'))
      .then((value) => 'Не выполнится: $value')
      .catchError((error) {
        print('   ⚠️ Перехвачено: $error');
        return 'Оффлайн-режим'; // ✅ Возвращаем String, как требует цепочка
      })
      .then((value) => 'Статус: $value');

  print('   ✅ Результат после восстановления: $result');
}

/// 🎯 onError() — типизированная обработка с доступом к StackTrace
Future<void> demonstrateOnErrorTyped() async {
  print('\n🎯 onError() — типизированная обработка');

  Future<int> riskyOperation() async {
    throw ValidationException('Поле email обязательно');
  }

  final result = await riskyOperation()
      .onError<ValidationException>((error, _) {
        print('   🔍 Валидация: ${error.message}');
        return -1;
      })
      .onError<DatabaseException>((error, _) {
        print('   💾 База данных: ${error.message}');
        return -2;
      });

  print('   ✅ Код результата: $result');
}

/// ♻️ whenComplete() — гарантированное выполнение
Future<void> demonstrateWhenComplete() async {
  print('\n♻️ whenComplete() — блок "всегда"');

  final stopwatch = Stopwatch()..start();

  try {
    final result =
        await Future.delayed(
          const Duration(milliseconds: 200),
          () => 'Данные',
        ).whenComplete(() {
          stopwatch.stop();
          print('   ⏱️ Операция заняла: ${stopwatch.elapsedMilliseconds}ms');
        });

    print('   ✅ Успех: $result');
  } catch (e) {
    print('   ❌ Ошибка: $e');
  }
}

/// ⏰ timeout() — защита от "вечных" Future
Future<void> demonstrateTimeout() async {
  print('\n⏰ timeout() — ограничение времени ожидания');

  try {
    final result =
        await Future.delayed(
          const Duration(seconds: 5),
          () => 'Ответ сервера',
        ).timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {
            print('   ⚠️ Таймаут! Возвращаем кэшированные данные');
            return 'Кэш: устаревшие данные';
          },
        );
    print('   ✅ Результат: $result');
  } on TimeoutException catch (e) {
    print('   ❌ Таймаут не обработан: $e');
  }
}

// ============================================================================
// 🧩 4. СТАТИЧЕСКИЕ МЕТОДЫ
// ============================================================================

Future<void> demonstrateFutureWait() async {
  print('\n🎬 Future.wait() — ожидание всех задач');

  final stopwatch = Stopwatch()..start();

  final results = await Future.wait([
    _fetchUserProfile(),
    _fetchUserSettings(),
    _fetchUserNotifications(),
  ], eagerError: false);

  stopwatch.stop();

  print('   ✅ Все данные получены за ${stopwatch.elapsedMilliseconds}ms');
  print('   📊 Профиль: ${results[0]}');
  print('   ⚙️ Настройки: ${results[1]}');
  print('   🔔 Уведомления: ${results[2]}');
}

Future<String> _fetchUserProfile() async {
  await Future.delayed(const Duration(milliseconds: 300));
  return 'Профиль: Иван';
}

Future<String> _fetchUserSettings() async {
  await Future.delayed(const Duration(milliseconds: 200));
  return 'Тема: тёмная';
}

Future<String> _fetchUserNotifications() async {
  await Future.delayed(const Duration(milliseconds: 400));
  return '3 новых';
}

Future<void> demonstrateFutureAny() async {
  print('\n🏁 Future.any() — гонка до первого результата');

  final winner = await Future.any([
    Future.delayed(const Duration(seconds: 2), () => 'API: полные данные'),
    Future.delayed(
      const Duration(milliseconds: 100),
      () => 'Кэш: данные на 5 мин назад',
    ),
    Future.value('Дефолт: минимальный набор'),
  ]);

  print('   🏆 Победитель гонки: $winner');
}

Future<void> demonstrateFutureDoWhile() async {
  print('\n🔁 Future.doWhile() — асинхронный цикл');

  var page = 1;
  const maxPages = 3;

  await Future.doWhile(() async {
    print('   📄 Загрузка страницы $page...');
    await Future.delayed(const Duration(milliseconds: 150));
    page++;
    return page <= maxPages;
  });

  print('   ✅ Загружено страниц: ${page - 1}');
}

Future<void> demonstrateFutureForEach() async {
  print('\n🔄 Future.forEach() — последовательная асинхронная обработка');

  final items = ['A', 'B', 'C'];
  final results = <String>[];

  await Future.forEach<String>(items, (item) async {
    await Future.delayed(
      Duration(milliseconds: 100 * (item.codeUnitAt(0) - 64)),
    );
    results.add('$item-processed');
    print('   → Обработан: $item');
  });

  print('   ✅ Итог: $results');
}

// ============================================================================
// 🔄 5. ПРОДВИНУТЫЕ ПАТТЕРНЫ
// ============================================================================

/// 🔄 Retry-паттерн с экспоненциальной задержкой
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
  bool Function(Object error)? shouldRetry,
}) async {
  var attempt = 0;

  while (true) {
    try {
      attempt++;
      return await operation();
    } catch (e) {
      if (attempt >= maxAttempts || (shouldRetry?.call(e) == false)) {
        print('   ❌ Ошибка после $attempt попыток: $e');
        rethrow;
      }

      final delay = baseDelay * pow(2, attempt - 1);
      print(
        '   🔄 Попытка $attempt не удалась. Повтор через ${delay.inMilliseconds}ms...',
      );
      await Future.delayed(delay);
    }
  }
}

Future<void> demonstrateRetryPattern() async {
  print('\n🔄 Retry Pattern — автоматические повторные попытки');

  var callCount = 0;

  Future<String> flakyApi() async {
    callCount++;
    if (callCount < 3) {
      throw NetworkException('Временная ошибка сети');
    }
    return '✅ Данные получены';
  }

  final result = await retryWithBackoff(
    flakyApi,
    maxAttempts: 4,
    shouldRetry: (error) => error is NetworkException,
  );

  print('   ✅ Итог: $result (всего вызовов: $callCount)');
}

/// 🎛️ Cancellable Future
class CancellableOperation<T> {
  final Completer<T> _completer = Completer<T>();
  bool _isCancelled = false;

  Future<T> get future => _completer.future;

  void cancel([Object? reason]) {
    /// Завершть Future

    /// Если он уже завершен
    if (_isCancelled) return;

    /// Иначе говорим что завершили
    _isCancelled = true;

    /// Если операция не дошла до конца
    if (!_completer.isCompleted) {
      /// То данные отдавать некому и мы отправляем ошибку с причиной
      _completer.completeError(OperationCancelledException(reason));
    }
  }

  void complete(T value) {
    /// Завершаем операцию значением

    /// Если операция не была отменена и еще не завершилось
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  void completeError(Object error, [StackTrace? stack]) {
    if (!_isCancelled && !_completer.isCompleted) {
      _completer.completeError(error, stack);
    }
  }

  bool get isCancelled => _isCancelled;
}

Future<void> demonstrateCancellableFuture() async {
  /// Для ручного управлени асинхронными операциями
  print('\n🎛️ Cancellable Future — отмена операции');

  final operation = CancellableOperation<String>();

  Future.delayed(const Duration(seconds: 2)).then((_) {
    if (!operation.isCancelled) {
      operation.complete('✅ Задача завершена');
    }
  });

  Future.delayed(const Duration(milliseconds: 500), () {
    print('   ⏹️ Отмена операции...');
    operation.cancel('Пользователь ушёл с экрана');
  });

  try {
    final result = await operation.future;
    print('   Результат: $result');
  } on OperationCancelledException catch (e) {
    print('   ⚠️ Операция отменена: ${e.reason}');
  }
}

class OperationCancelledException implements Exception {
  final Object? reason;
  const OperationCancelledException([this.reason]);
  @override
  String toString() {
    // ✅ Используем интерполяцию вместо конкатенации
    return 'OperationCancelledException: $reason';
  }
}

class ApiException implements Exception {
  final String message;
  final int? code;
  const ApiException(this.message, {this.code});
  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

/// 🎚️ Debounce: отложенное выполнение
class Debouncer {
  Timer? _timer;

  void call(
    void Function() action, [
    Duration delay = const Duration(milliseconds: 300),
  ]) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() {
    cancel();
    _timer = null;
  }
}

Future<void> demonstrateDebouncePattern() async {
  print('\n🎚️ Debounce Pattern — отложенное выполнение');

  final debouncer = Debouncer();
  var searchCount = 0;

  void onSearchQuery(String query) {
    searchCount++;
    print('   🔤 Ввод #$searchCount: "$query"');

    debouncer(() {
      print('   🔍 Поиск по запросу: "$query"');
    });
  }

  onSearchQuery('f');
  onSearchQuery('fl');
  onSearchQuery('flu');
  onSearchQuery('flut');
  onSearchQuery('flutter');

  await Future.delayed(const Duration(milliseconds: 400));
  print('   ✅ Выполнен только последний запрос');

  debouncer.dispose();
}

// ============================================================================
// 🚀 MAIN
// ============================================================================

void main() async {
  print('🚀 FUTURE CHEAT SHEET v2.1 — Запуск демо');
  print('═' * 60);

  await demonstrateEventLoopOrder();

  await demonstrateFutureValue();
  await demonstrateFutureSync();
  await demonstrateFutureDelayed();
  await demonstrateFutureError();
  await demonstrateFutureMicrotask();

  await demonstrateThenChaining();
  await demonstrateCatchError();
  await demonstrateOnErrorTyped();
  await demonstrateWhenComplete();
  await demonstrateTimeout();

  await demonstrateFutureWait();
  await demonstrateFutureAny();
  await demonstrateFutureDoWhile();
  await demonstrateFutureForEach();

  await demonstrateRetryPattern();
  await demonstrateCancellableFuture();
  await demonstrateDebouncePattern();

  print('\n${'═' * 60}');
  print('✅ Все демонстрации завершены!');
  print('💡 Совет: комментируйте ненужные секции в main() для фокуса');
}
