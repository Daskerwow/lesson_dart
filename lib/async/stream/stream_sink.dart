// stream_sink_cheatsheet.dart
//
// Демонстрация возможностей StreamSink<S>.
// Показывает работу свойств, методов и оператора ==.
// Используем StreamController.sink как реализацию.
//
// Запуск:
//   dart run stream_sink_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMSINK ---\n');

  await basicDemo();
  await addStreamDemo();
  await propertiesDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Базовый пример: add, addError, close
// =======================================================
Future<void> basicDemo() async {
  print('1. --- add / addError / close ---');

  final controller = StreamController<String>();
  final sink = controller.sink; // StreamSink<String>

  // Подписка на поток
  controller.stream.listen(
    (event) => print('получено: $event'),
    onError: (e) => print('ошибка: $e'),
    onDone: () => print('done'),
  );

  // add: добавить событие
  sink.add('hello');
  sink.add('world');

  // addError: добавить ошибку
  sink.addError('что-то пошло не так');

  // close: закрыть sink
  await sink.close();
}

// =======================================================
// 2. addStream: передача целого потока в sink
// =======================================================
Future<void> addStreamDemo() async {
  print('\n2. --- addStream ---');

  final controller = StreamController<int>();
  final sink = controller.sink;

  controller.stream.listen(
    (event) => print('stream data: $event'),
    onDone: () => print('stream done'),
  );

  // Источник: поток чисел
  final source = Stream<int>.fromIterable([1, 2, 3]);

  // addStream: передаём весь поток в sink
  await sink.addStream(source);

  // После завершения addStream можно снова использовать add
  sink.add(99);

  await sink.close();
}

// =======================================================
// 3. Свойства StreamSink
// =======================================================
Future<void> propertiesDemo() async {
  print('\n3. --- Свойства ---');

  final controller = StreamController<String>();
  final sink = controller.sink;

  // done: Future, завершающийся при закрытии sink
  sink.done.then((_) => print('sink.done завершён'));

  sink.add('test');
  await sink.close();

  print('hashCode: ${sink.hashCode}');
  print('runtimeType: ${sink.runtimeType}');
  print('toString: ${sink.toString()}');
}

// =======================================================
// 4. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n4. --- Оператор == ---');

  final c1 = StreamController<int>();
  final c2 = StreamController<int>();

  final s1 = c1.sink;
  final s2 = c2.sink;
  final s3 = s1;

  print('s1 == s2: ${s1 == s2}'); // false, разные объекты
  print('s1 == s3: ${s1 == s3}'); // true, одна и та же ссылка

  await s1.close();
  await s2.close();
}
