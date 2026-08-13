/// ============================================================================
/// ПАТТЕРН: ISOLATE POOL / THREAD POOL (Пул изолятов)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Комбинация Object Pool + Actor Model: заранее поднимает N изолятов-воркеров
/// и распределяет между ними поступающие задачи, вместо создания нового
/// изолята под каждую задачу (Isolate.spawn — операция не бесплатная).
/// Это Dart-аналог классического Thread Pool из других языков.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Множество однотипных CPU-bound задач (обработка изображений пачками,
///   парсинг множества файлов) — пул амортизирует стоимость создания
///   изолятов между множеством задач.
/// - В реальных проектах на Flutter для этого часто используют пакет
///   `package:isolate_pool` или встроенный `compute()` (для одной задачи).
///   Здесь показана логика "с нуля" для понимания устройства.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

/// Задача, отправляемая в пул — чистая функция + аргумент + способ
/// вернуть результат.
class PoolTask<T, R> {
  final R Function(T) function;
  final T argument;
  final Completer<R> completer = Completer<R>();

  PoolTask(this.function, this.argument);
}

/// Сообщение для передачи задачи в воркер-изолят (функции нельзя
/// передавать через SendPort напрямую в общем случае, но здесь мы
/// используем статическую функцию и передаём её как есть — Dart это
/// поддерживает для top-level/static функций).
class _WorkerRequest {
  final Function function;
  final dynamic argument;
  final SendPort replyTo;
  const _WorkerRequest(this.function, this.argument, this.replyTo);
}

void _isolateWorkerLoop(SendPort mainSendPort) {
  final receivePort = ReceivePort();

  /// Обмениваемся портами для связи
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is _WorkerRequest) {
      try {
        final result = message.function(message.argument);
        message.replyTo.send(result);
      } catch (e) {
        message.replyTo.send(_WorkerError(e.toString()));
      }
    }
  });
}

class _WorkerError {
  final String message;
  _WorkerError(this.message);
}

/// ПУЛ ИЗОЛЯТОВ: держит N готовых воркеров и раздаёт им задачи по мере
/// освобождения — классическая схема "round-robin" / "первый свободный".
class IsolatePool {
  final int size;
  final List<SendPort> _workerPorts = [];
  final List<Isolate> _isolates = [];
  final Queue<int> _freeWorkerIndices = Queue();
  final Queue<_QueuedTask> _pendingTasks = Queue();

  IsolatePool(this.size);

  Future<void> start() async {
    for (var i = 0; i < size; i++) {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateWorkerLoop,
        receivePort.sendPort,
      );
      final workerSendPort = await receivePort.first as SendPort;
      _isolates.add(isolate);
      _workerPorts.add(workerSendPort);
      _freeWorkerIndices.add(i);
    }
    print('[Pool] Запущено $size воркеров-изолятов');
  }

  /// Выполнить функцию в одном из свободных изолятов пула.
  Future<R> run<T, R>(R Function(T) function, T argument) async {
    final task = _QueuedTask(function, argument, Completer<dynamic>());
    if (_freeWorkerIndices.isNotEmpty) {
      _dispatch(task);
    } else {
      _pendingTasks.add(task);
    }
    final result = await task.completer.future;
    if (result is _WorkerError) {
      throw StateError('Ошибка в воркере: ${result.message}');
    }
    return result as R;
  }

  void _dispatch(_QueuedTask task) {
    final workerIndex = _freeWorkerIndices.removeFirst();
    final responsePort = ReceivePort();
    responsePort.listen((result) {
      responsePort.close();
      task.completer.complete(result);
      _freeWorkerIndices.add(workerIndex);
      // Если есть задачи в очереди — сразу отдаём освободившемуся воркеру.
      if (_pendingTasks.isNotEmpty) {
        _dispatch(_pendingTasks.removeFirst());
      }
    });
    _workerPorts[workerIndex].send(
      _WorkerRequest(task.function, task.argument, responsePort.sendPort),
    );
  }

  Future<void> shutdown() async {
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    print('[Pool] Все воркеры остановлены');
  }
}

class _QueuedTask {
  final Function function;
  final dynamic argument;
  final Completer<dynamic> completer;
  _QueuedTask(this.function, this.argument, this.completer);
}

// Top-level функция — тяжёлое CPU-bound вычисление, выполняемое в воркере.
int _countPrimesUpTo(int limit) {
  var count = 0;
  for (var n = 2; n <= limit; n++) {
    var isPrime = true;
    for (var i = 2; i * i <= n; i++) {
      if (n % i == 0) {
        isPrime = false;
        break;
      }
    }
    if (isPrime) count++;
  }
  return count;
}

void main() async {
  final pool = IsolatePool(3);
  await pool.start();

  // Раздаём 6 тяжёлых задач на 3 воркера — задачи 4,5,6 дождутся
  // освобождения воркеров от задач 1,2,3.
  final ranges = [50000, 60000, 70000, 80000, 90000, 100000];
  final results = await Future.wait(
    ranges.map((limit) => pool.run(_countPrimesUpTo, limit)),
  );

  for (var i = 0; i < ranges.length; i++) {
    print('Простых чисел до ${ranges[i]}: ${results[i]}');
  }

  await pool.shutdown();
}
