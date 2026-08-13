/// ============================================================================
/// ПАТТЕРН КОНКУРЕНТНОСТИ: FUTURE/STREAM PIPELINE (Конвейер асинхронной обработки)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Строит многоступенчатый конвейер обработки асинхронных данных через
/// композицию Stream-трансформаций (map, asyncMap, where, transform),
/// где каждый этап — независимая, тестируемая единица. Это идиоматичный
/// для Dart аналог паттернов Pipeline/Pipes-and-Filters.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Обработка потоковых данных: чтение файла построчно с фильтрацией и
///   трансформацией, обработка WebSocket-сообщений, ETL-процессы.
/// - Когда нужно ограничить степень параллелизма (например, не более
///   N одновременных сетевых запросов) — показано через кастомный
///   trasformer с семафором.
library;

import 'dart:async';
import 'dart:collection';

/// Простая модель "сырого" события из внешнего источника (сенсор,
/// лог-файл, сообщение очереди).
class RawEvent {
  final String payload;
  final DateTime timestamp;
  const RawEvent(this.payload, this.timestamp);
}

class ParsedEvent {
  final String type;
  final double value;
  const ParsedEvent(this.type, this.value);
}

class EnrichedEvent {
  final ParsedEvent event;
  final String category;
  const EnrichedEvent(this.event, this.category);

  @override
  String toString() =>
      'EnrichedEvent(${event.type}=${event.value}, cat=$category)';
}

/// Имитация источника потоковых событий (например, из WebSocket).
Stream<RawEvent> rawEventSource() async* {
  final samples = [
    'temp:23.5',
    'humidity:60.2',
    'temp:24.1',
    'invalid_data',
    'pressure:1013.2',
  ];

  for (final s in samples) {
    await Future.delayed(const Duration(milliseconds: 50));
    yield RawEvent(s, DateTime.now());
  }
}

/// ЭТАП 1: парсинг — синхронная трансформация через map.
/// Возвращает null для невалидных данных, которые отфильтруются дальше.
ParsedEvent? parseEvent(RawEvent raw) {
  final parts = raw.payload.split(':');
  if (parts.length != 2) return null;
  final value = double.tryParse(parts[1]);
  if (value == null) return null;
  return ParsedEvent(parts[0], value);
}

/// ЭТАП 2: асинхронное обогащение — имитация похода в другой сервис
/// (например, определение категории по справочнику из БД).
Future<EnrichedEvent> enrichEvent(ParsedEvent event) async {
  await Future.delayed(const Duration(milliseconds: 20));
  final category = switch (event.type) {
    'temp' => 'Температурные датчики',
    'humidity' => 'Датчики влажности',
    'pressure' => 'Датчики давления',
    _ => 'Неизвестная категория',
  };
  return EnrichedEvent(event, category);
}

/// Ограничитель параллелизма: гарантирует, что асинхронная операция
/// (например, сетевой вызов) выполняется не более чем в N потоках
/// одновременно — классическая задача при построении конвейеров.
class ConcurrencyLimiter {
  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiting = Queue();

  ConcurrencyLimiter(this.maxConcurrent);

  Future<T> run<T>(Future<T> Function() task) async {
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _waiting.add(completer);
      await completer.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      }
    }
  }
}

void main() async {
  final limiter = ConcurrencyLimiter(2); // не более 2 параллельных обогащений

  // Конвейер собирается декларативно из независимых, тестируемых по
  // отдельности функций — каждый этап решает ровно одну задачу.
  final pipeline = rawEventSource()
      .map(parseEvent) // ЭТАП 1: parse (может вернуть null)
      .where((event) => event != null) // ЭТАП 2: отфильтровать невалидные
      .cast<ParsedEvent>()
      .asyncMap(
        (event) => limiter.run(() => enrichEvent(event)),
      ); // ЭТАП 3: обогащение с лимитом

  await for (final enriched in pipeline) {
    print(enriched);
  }

  print('\nКонвейер завершён.');
}
