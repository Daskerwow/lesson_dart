/// ============================================================================
/// ПАТТЕРН: ITERATOR (Итератор)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Предоставляет способ последовательного доступа к элементам составного
/// объекта, не раскрывая его внутреннего представления. Dart имеет
/// встроенную поддержку через интерфейсы Iterable/Iterator и синтаксис
/// `for-in` — это один из немногих паттернов, глубоко встроенных в язык.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Обход собственных коллекций/структур данных единым способом (for-in),
///   независимо от их внутреннего устройства (массив, дерево, связный список).
/// - Ленивая генерация последовательностей без материализации всей
///   коллекции в памяти (например, чтение большого файла построчно).
library;

/// Собственная структура данных: круговой буфер (Circular/Ring Buffer),
/// внутреннее устройство которого (индексы head/tail в массиве
/// фиксированного размера) мы хотим скрыть от потребителя.
class RingBuffer<T> extends Iterable<T> {
  final List<T?> _storage;
  int _head = 0;
  int _count = 0;

  RingBuffer(int capacity) : _storage = List<T?>.filled(capacity, null);

  void add(T item) {
    final tail = (_head + _count) % _storage.length;
    if (_count == _storage.length) {
      // Буфер полон — перезаписываем самый старый элемент.
      _storage[_head] = item;
      _head = (_head + 1) % _storage.length;
    } else {
      _storage[tail] = item;
      _count++;
    }
  }

  /// Реализация Iterable требует переопределить только `iterator` —
  /// все остальные методы (map, where, toList, for-in и т.д.) Dart
  /// предоставляет автоматически на основе этого итератора.
  @override
  Iterator<T> get iterator => _RingBufferIterator<T>(this);

  T? elementAtIndex(int i) => _storage[(_head + i) % _storage.length];
  int get length_ => _count;
}

/// Конкретный итератор — хранит состояние обхода (текущую позицию)
/// отдельно от самой коллекции. Это позволяет иметь несколько независимых
/// обходов одной коллекции одновременно.
class _RingBufferIterator<T> implements Iterator<T> {
  final RingBuffer<T> _buffer;
  int _index = -1;

  _RingBufferIterator(this._buffer);

  @override
  T get current => _buffer.elementAtIndex(_index) as T;

  @override
  bool moveNext() {
    _index++;
    return _index < _buffer.length_;
  }
}

void main() {
  final buffer = RingBuffer<int>(3);
  buffer.add(1);
  buffer.add(2);
  buffer.add(3);
  buffer.add(4); // вытесняет 1, т.к. буфер заполнен

  // Благодаря реализации Iterable, работает нативный for-in Dart,
  // а также все стандартные методы коллекций.
  print('Обход for-in:');
  for (final value in buffer) {
    print('  $value');
  }

  print('Через .map и .toList: ${buffer.map((v) => v * 10).toList()}');
  print('Сумма через .fold: ${buffer.fold<int>(0, (a, b) => a + b)}');
}
