/// ============================================================================
/// ПАТТЕРН КОНКУРЕНТНОСТИ: PRODUCER-CONSUMER (Производитель-Потребитель)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Разделяет производство данных и их обработку через промежуточную
/// буферизованную очередь, позволяя производителю и потребителю работать
/// с разной скоростью, не блокируя друг друга напрямую. В Dart идиоматично
/// реализуется через StreamController с буферизацией — сам dart:async
/// построен на этой идее.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Обработка потока событий (сенсоры, WebSocket-сообщения, логи), когда
///   скорость поступления данных отличается от скорости их обработки.
/// - Batch-обработка: собираем события в очередь и обрабатываем пачками
///   для эффективности (например, батчинг записи в БД).
library;

import 'dart:async';
import 'dart:collection';

/// Ограниченная по размеру очередь с обратным давлением (backpressure):
/// если очередь заполнена, производитель ждёт, пока потребитель освободит
/// место — это защищает от неограниченного роста памяти при быстром
/// производителе и медленном потребителе.

/// Ограниченная очередь с корректным backpressure (без гонок).
class BoundedQueue<T> {
  final int capacity;
  final Queue<T> _queue = Queue<T>();
  final Queue<Completer<void>> _waitingProducers = Queue();
  final Queue<Completer<T>> _waitingConsumers = Queue();

  int maxObserved = 0; // диагностика

  BoundedQueue(this.capacity);

  Future<void> put(T item) async {
    while (true) {
      // 1. Есть ждущий потребитель — отдаём напрямую (handoff)
      if (_waitingConsumers.isNotEmpty) {
        final consumer = _waitingConsumers.removeFirst();
        consumer.complete(item);
        return;
      }

      // 2. Есть место — кладём
      if (_queue.length < capacity) {
        _queue.add(item);
        if (_queue.length > maxObserved) maxObserved = _queue.length;
        assert(_queue.length <= capacity, 'Очередь переполнена!');
        return;
      }

      // 3. Места нет — ждём и после пробуждения проверяем заново
      final completer = Completer<void>();
      _waitingProducers.add(completer);
      await completer.future;
    }
  }

  Future<T> take() async {
    if (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (_waitingProducers.isNotEmpty) {
        _waitingProducers.removeFirst().complete();
      }
      return item;
    }

    final completer = Completer<T>();
    _waitingConsumers.add(completer);
    return completer.future;
  }

  int get length => _queue.length;
}

Future<void> producer(BoundedQueue<int> queue, String name, int count) async {
  for (var i = 1; i <= count; i++) {
    await queue.put(i);
    print('[$name] произвёл: $i  (очередь: ${queue.length})');
    await Future.delayed(const Duration(milliseconds: 5));
  }
  print('[$name] закончил');
}

Future<void> consumer(BoundedQueue<int> queue, String name, int count) async {
  for (var i = 0; i < count; i++) {
    final item = await queue.take();
    print('  [$name] обработал: $item  (очередь: ${queue.length})');
    await Future.delayed(const Duration(milliseconds: 25)); // медленнее
  }
  print('  [$name] закончил');
}

void main() async {
  const capacity = 3;
  final queue = BoundedQueue<int>(capacity);

  print('=== BoundedQueue (capacity = $capacity) ===\n');

  await Future.wait([
    producer(queue, 'P1', 8),
    producer(queue, 'P2', 8),
    producer(queue, 'P3', 8),
    consumer(queue, 'C', 24),
  ]);

  print('\nГотово.');
  print('Максимальный размер очереди за всё время: ${queue.maxObserved}');
  print('Финальный размер очереди: ${queue.length}');
}
