// stream_subscription_cheatsheet.dart
//
// Демонстрация возможностей StreamSubscription<T>.
// Показывает работу свойств, методов и оператора ==.
// Используем Stream.periodic и StreamController для примеров.
//
// Запуск:
//   dart run stream_subscription_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMSUBSCRIPTION ---\n');

  await basicDemo();
  await pauseResumeDemo();
  await cancelDemo();
  await handlersDemo();
  await propertiesDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Базовый пример: listen возвращает StreamSubscription
// =======================================================
Future<void> basicDemo() async {
  print('1. --- Базовый пример ---');

  final stream = Stream<int>.fromIterable([1, 2, 3]);
  final subscription = stream.listen(
    (event) => print('получено: $event'),
    onDone: () => print('done'),
    onError: (e) => print('error: $e'),
  );

  // asFuture: возвращает Future, который завершится при onDone или onError
  await subscription.asFuture<void>();
}

// =======================================================
// 2. pause / resume
// =======================================================
Future<void> pauseResumeDemo() async {
  print('\n2. --- pause / resume ---');

  final stream = Stream.periodic(
    const Duration(milliseconds: 200),
    (i) => i,
  ).take(5);
  final subscription = stream.listen((event) => print('event: $event'));

  // Поставим паузу после первого события
  await Future.delayed(const Duration(milliseconds: 250));
  subscription.pause();
  print('isPaused: ${subscription.isPaused}');

  // Подождём немного, затем возобновим
  await Future.delayed(const Duration(milliseconds: 500));
  subscription.resume();
  print('isPaused: ${subscription.isPaused}');

  await subscription.asFuture<void>();
}

// =======================================================
// 3. cancel
// =======================================================
Future<void> cancelDemo() async {
  print('\n3. --- cancel ---');

  final stream = Stream.periodic(
    const Duration(milliseconds: 200),
    (i) => i,
  ).take(10);
  final subscription = stream.listen((event) => print('event: $event'));

  // Отменим подписку после пары событий
  await Future.delayed(const Duration(milliseconds: 500));
  await subscription.cancel();
  print('подписка отменена');
}

// =======================================================
// 4. Замена обработчиков: onData, onError, onDone
// =======================================================
Future<void> handlersDemo() async {
  print('\n4. --- onData / onError / onDone ---');

  final controller = StreamController<int>();

  final subscription = controller.stream.listen(
    (event) => print('init data: $event'),
  );

  // Заменим обработчик данных
  subscription.onData((event) => print('новый data handler: $event'));

  // Заменим обработчик ошибок
  subscription.onError((error) => print('новый error handler: $error'));

  // Заменим обработчик завершения
  subscription.onDone(() => print('новый done handler'));

  controller.add(1);
  controller.addError('ошибка');
  await controller.close();
  await subscription.asFuture<void>();
}

// =======================================================
// 5. Свойства StreamSubscription
// =======================================================
Future<void> propertiesDemo() async {
  print('\n5. --- Свойства ---');

  final stream = Stream<int>.fromIterable([42]);
  final subscription = stream.listen((event) => print('event: $event'));

  print('hashCode: ${subscription.hashCode}');
  print('runtimeType: ${subscription.runtimeType}');
  print('toString: ${subscription.toString()}');

  await subscription.asFuture<void>();
}

// =======================================================
// 6. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n6. --- Оператор == ---');

  final stream1 = Stream<int>.fromIterable([1]);
  final stream2 = Stream<int>.fromIterable([2]);

  final sub1 = stream1.listen((_) {});
  final sub2 = stream2.listen((_) {});
  final sub3 = sub1;

  print('sub1 == sub2: ${sub1 == sub2}'); // false
  print('sub1 == sub3: ${sub1 == sub3}'); // true

  await sub1.cancel();
  await sub2.cancel();
}
