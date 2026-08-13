/// ============================================================================
/// ПАТТЕРН: OBJECT POOL (Пул объектов)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Переиспользует набор заранее созданных дорогих объектов вместо создания
/// нового объекта под каждый запрос и его последующего уничтожения.
/// Клиент "берёт" объект из пула, использует, и "возвращает" обратно —
/// вместо new/dispose на каждую операцию.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Пул соединений с БД (самый частый пример) — установка соединения
///   дорога (handshake, аутентификация), поэтому соединения переиспользуются.
/// - Пул потоков/изолятов (см. isolate_pool.dart), пул сетевых буферов.
/// - Игры: пул пуль/частиц, чтобы избежать частых аллокаций в игровом цикле
///   (что вызывало бы паузы сборщика мусора).
library;

import 'dart:async';
import 'dart:collection';

/// "Дорогой" в создании ресурс — имитация соединения с БД.
class DbConnection {
  final int id;
  bool inUse = false;

  DbConnection._(this.id);

  static Future<DbConnection> establish(int id) async {
    print('[Connection $id] Устанавливаем соединение (дорогая операция)...');
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // имитация handshake
    return DbConnection._(id);
  }

  Future<String> query(String sql) async {
    await Future.delayed(const Duration(milliseconds: 30));
    return 'Результат "$sql" от соединения #$id';
  }
}

/// ПУЛ ОБЪЕКТОВ: управляет жизненным циклом ограниченного набора
/// дорогих объектов, выдавая их "в аренду" и принимая обратно.
class ConnectionPool {
  final int maxSize;
  final Queue<DbConnection> _available = Queue();
  final Set<DbConnection> _all = {};
  final Queue<Completer<DbConnection>> _waiting = Queue();
  int _nextId = 1;
  int _creating = 0; // ← сколько соединений сейчас создаётся

  ConnectionPool(this.maxSize);

  /// Получить соединение из пула. Если все заняты и лимит не достигнут —
  /// создаётся новое. Если лимит достигнут — запрос встаёт в очередь
  /// ожидания, пока кто-то не освободит соединение.
  Future<DbConnection> acquire() async {
    if (_available.isNotEmpty) {
      final conn = _available.removeFirst();
      conn.inUse = true;
      print(
        '[Pool] Выдано существующее соединение #${conn.id} '
        '(доступно ещё: ${_available.length})',
      );
      return conn;
    }
    if (_all.length + _creating < maxSize) {
      _creating++; // ← резервируем слот ДО await
      try {
        final conn = await DbConnection.establish(_nextId++);
        conn.inUse = true;
        _all.add(conn);
        return conn;
      } finally {
        _creating--;
      }
    }
    // Пул исчерпан — ждём, пока кто-то освободит соединение.
    print('[Pool] Все $maxSize соединений заняты, ожидаем...');
    final completer = Completer<DbConnection>();
    _waiting.add(completer);
    return completer.future;
  }

  /// Вернуть соединение в пул вместо его уничтожения.
  void release(DbConnection conn) {
    conn.inUse = false;
    if (_waiting.isNotEmpty) {
      // Сразу передаём освободившееся соединение следующему ожидающему.
      final completer = _waiting.removeFirst();
      conn.inUse = true;
      completer.complete(conn);
      return;
    }
    _available.add(conn);
    print('[Pool] Соединение #${conn.id} возвращено в пул');
  }
}

/// Удобная обёртка "acquire -> use -> release", гарантирующая возврат
/// ресурса в пул даже при исключении (аналог try-with-resources).
Future<T> withConnection<T>(
  ConnectionPool pool,
  Future<T> Function(DbConnection conn) action,
) async {
  final conn = await pool.acquire();
  try {
    return await action(conn);
  } finally {
    pool.release(conn);
  }
}

void main() async {
  final pool = ConnectionPool(2); // максимум 2 одновременных соединения

  // Запускаем 4 "запроса" параллельно — пул из 2 соединений заставит
  // часть запросов подождать освобождения, вместо создания 4 соединений.
  final results = await Future.wait([
    withConnection(pool, (c) => c.query('SELECT * FROM users')),
    withConnection(pool, (c) => c.query('SELECT * FROM orders')),
    withConnection(pool, (c) => c.query('SELECT * FROM products')),
    withConnection(pool, (c) => c.query('SELECT * FROM invoices')),
  ]);

  print('\nРезультаты:');
  results.forEach(print);
}
