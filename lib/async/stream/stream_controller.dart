// stream_controller_cheatsheet.dart
//
// Полный учебный пример по StreamController<T>.
// Покрывает: конструкторы, свойства, методы, оператор ==.
// Каждый пример снабжен комментариями и выводом.
//
// Запуск:
//   dart run stream_controller_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMCONTROLLER ---\n');

  await constructorsDemo();
  await propertiesDemo();
  await methodsDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Конструкторы StreamController
// =======================================================
Future<void> constructorsDemo() async {
  print('1. --- Конструкторы ---');

  // StreamController: single-subscription
  {
    print('\n1.1 StreamController (single)');
    final controller = StreamController<int>(
      onListen: () => print('onListen'),
      onPause: () => print('onPause'),
      onResume: () => print('onResume'),
      onCancel: () => print('onCancel'),
    );

    controller.stream.listen(
      (event) => print('event: $event'),
      onDone: () => print('done'),
      onError: (e) => print('error: $e'),
    );

    controller.add(1);
    controller.add(2);
    await controller.close();
  }

  // StreamController.broadcast: multi-subscription
  {
    print('\n1.2 StreamController.broadcast');
    final controller = StreamController<String>.broadcast(
      onListen: () => print('broadcast onListen'),
      onCancel: () => print('broadcast onCancel'),
    );

    controller.stream.listen((e) => print('sub1: $e'));
    controller.stream.listen((e) => print('sub2: $e'));

    controller.add('hello');
    controller.add('world');
    await controller.close();
  }
}

// =======================================================
// 2. Свойства StreamController
// =======================================================
Future<void> propertiesDemo() async {
  print('\n2. --- Свойства ---');

  final controller = StreamController<int>();

  // hasListener: есть ли подписчик
  print('hasListener (до подписки): ${controller.hasListener}');
  controller.stream.listen((e) => print('listener: $e'));
  print('hasListener (после подписки): ${controller.hasListener}');

  // isClosed: закрыт ли контроллер
  print('isClosed (до close): ${controller.isClosed}');
  await controller.close();
  print('isClosed (после close): ${controller.isClosed}');

  // done: Future, завершающийся при закрытии
  final controller2 = StreamController<int>();
  final doneFuture = controller2.done.then((_) => print('doneFuture завершён'));
  controller2.add(42);
  await controller2.close();
  await doneFuture;

  // isPaused: показывает, что подписка приостановлена
  final controller3 = StreamController<int>();
  final subscription = controller3.stream.listen(
    (e) => print('paused demo: $e'),
  );
  print('isPaused (до pause): ${controller3.isPaused}');
  subscription.pause();
  print('isPaused (после pause): ${controller3.isPaused}');
  subscription.resume();
  print('isPaused (после resume): ${controller3.isPaused}');
  await controller3.close();

  // sink: доступ к StreamSink интерфейсу
  final controller4 = StreamController<String>();
  final sink = controller4.sink;
  sink.add('через sink');
  controller4.stream.listen((e) => print('sink получил: $e'));
  await sink.close();

  // stream: сам поток
  final controller5 = StreamController<int>();
  controller5.stream.listen((e) => print('stream: $e'));
  controller5.add(99);
  await controller5.close();

  print('hashCode: ${controller.hashCode}');
  print('runtimeType: ${controller.runtimeType}');
  print('toString: ${controller.toString()}');
}

// =======================================================
// 3. Методы StreamController
// =======================================================
Future<void> methodsDemo() async {
  print('\n3. --- Методы ---');

  final controller = StreamController<int>();

  controller.stream.listen(
    (e) => print('data: $e'),
    onError: (e) => print('error: $e'),
    onDone: () => print('done'),
  );

  // add: добавить событие
  controller.add(1);
  controller.add(2);

  // addError: добавить ошибку
  controller.addError('ошибка');

  // addStream: добавить целый поток
  final source = Stream<int>.fromIterable([10, 20, 30]);
  await controller.addStream(source);

  // close: закрыть поток
  await controller.close();
}

// =======================================================
// 4. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n4. --- Оператор == ---');

  final c1 = StreamController<int>();
  final c2 = StreamController<int>();
  final c3 = c1;

  print('c1 == c2: ${c1 == c2}'); // false
  print('c1 == c3: ${c1 == c3}'); // true

  await c1.close();
  await c2.close();
}
