// stream_iterator_cheatsheet.dart
//
// Демонстрация возможностей StreamIterator<T>.
// Показывает работу конструктора, свойств, методов и оператора ==.
//
// Запуск:
//   dart run stream_iterator_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMITERATOR ---\n');

  await basicDemo();
  await cancelDemo();
  await propertiesDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Базовый пример: обход потока через StreamIterator
// =======================================================
Future<void> basicDemo() async {
  print('1. --- Базовый обход ---');

  // Источник: поток чисел
  final source = Stream<int>.fromIterable([10, 20, 30]);

  // Создаём StreamIterator
  final iterator = StreamIterator<int>(source);

  // moveNext возвращает Future<bool>: true если есть элемент, false если поток завершён
  while (await iterator.moveNext()) {
    print('current: ${iterator.current}');
  }

  print('поток завершён');
}

// =======================================================
// 2. Пример cancel()
// =======================================================
Future<void> cancelDemo() async {
  print('\n2. --- cancel ---');

  final source = Stream<int>.periodic(
    const Duration(milliseconds: 200),
    (i) => i,
  ).take(5);
  final iterator = StreamIterator<int>(source);

  // Получим первый элемент
  if (await iterator.moveNext()) {
    print('получили: ${iterator.current}');
  }

  // Отменим итератор до конца
  await iterator.cancel();
  print('итератор отменён');
}

// =======================================================
// 3. Свойства StreamIterator
// =======================================================
Future<void> propertiesDemo() async {
  print('\n3. --- Свойства ---');

  final source = Stream<String>.fromIterable(['a', 'b']);
  final iterator = StreamIterator<String>(source);

  // current: доступен только после успешного moveNext()
  if (await iterator.moveNext()) {
    print('current: ${iterator.current}');
  }

  print('hashCode: ${iterator.hashCode}');
  print('runtimeType: ${iterator.runtimeType}');
  print('toString: ${iterator.toString()}');
}

// =======================================================
// 4. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n4. --- Оператор == ---');

  final source1 = Stream<int>.fromIterable([1, 2]);
  final source2 = Stream<int>.fromIterable([1, 2]);

  final it1 = StreamIterator<int>(source1);
  final it2 = StreamIterator<int>(source2);
  final it3 = it1;

  print('it1 == it2: ${it1 == it2}'); // false, разные объекты
  print('it1 == it3: ${it1 == it3}'); // true, одна и та же ссылка

  await it1.cancel();
  await it2.cancel();
}
