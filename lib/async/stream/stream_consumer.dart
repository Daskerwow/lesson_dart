// stream_consumer_cheatsheet.dart
//
// Демонстрация возможностей StreamConsumer<S>.
// Показывает работу addStream, close, а также использование через Stream.pipe.
//
// Запуск:
//   dart run stream_consumer_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMCONSUMER ---\n');

  await basicDemo();
  await pipeDemo();
  await propertiesDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Базовый пример: addStream и close
// =======================================================
Future<void> basicDemo() async {
  print('1. --- addStream и close ---');

  // Создаём StreamController, у которого есть sink (StreamSink),
  // он реализует интерфейс StreamConsumer.
  // через него можно управлять этип контроллером
  final controller = StreamController<int>();

  // Подписываемся на поток контроллера, чтобы видеть, что туда попадает.
  controller.stream.listen(
    (v) => print('consumer получил: $v'),
    onDone: () => print('consumer закрыт'),
  );

  // addStream: передаём целый поток в consumer.
  final source = Stream<int>.fromIterable([1, 2, 3]);
  await controller.sink.addStream(source);

  // После addStream можно добавить ещё один поток.
  final source2 = Stream<int>.fromIterable([10, 20]);
  await controller.sink.addStream(source2);

  // close: говорим, что больше потоков не будет.
  await controller.sink.close();
}

// =======================================================
// 2. Использование через Stream.pipe
// =======================================================
Future<void> pipeDemo() async {
  print('\n2. --- Stream.pipe ---');

  // Создаём StreamController, у которого есть sink (StreamSink),
  // он реализует интерфейс StreamConsumer.
  // через него можно управлять этип контроллером
  final controller = StreamController<String>();

  // Подписка на выходной поток контроллера
  controller.stream.listen(
    (v) => print('pipe consumer получил: $v'),
    onDone: () => print('pipe consumer закрыт'),
  );

  // Источник: поток строк
  final source = Stream<String>.fromIterable(['a', 'b', 'c']);

  // pipe: передаём поток в consumer (sink).
  // pipe вызывает addStream, затем close.
  await source.pipe(controller.sink);

  // После pipe sink закрыт, и поток завершён.
}

// =======================================================
// 3. Свойства StreamConsumer
// =======================================================
Future<void> propertiesDemo() async {
  print('\n3. --- Свойства ---');

  final controller = StreamController<int>();
  final consumer = controller.sink;

  print('hashCode: ${consumer.hashCode}');
  print('runtimeType: ${consumer.runtimeType}');
  print('toString: ${consumer.toString()}');

  await consumer.close();
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
