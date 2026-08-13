// stream_view_cheatsheet.dart
//
// Демонстрация возможностей StreamView<T>.
// Показывает работу конструктора, свойств, методов и оператора ==.
//
// Запуск:
//   dart run stream_view_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMVIEW ---\n');

  await basicDemo();
  await propertiesDemo();
  await methodsDemo();
  await operatorsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Базовый пример: StreamView
// =======================================================
Future<void> basicDemo() async {
  print('1. --- Базовый пример ---');

  final controller = StreamController<int>();

  // Создаём StreamView поверх контроллера
  final view = StreamView<int>(controller.stream);

  // Подписка через view
  view.listen(
    (event) => print('view получил: $event'),
    onDone: () => print('view done'),
  );

  // Добавляем события через контроллер
  controller.add(1);
  controller.add(2);
  await controller.close();
}

// =======================================================
// 2. Свойства StreamView
// =======================================================
Future<void> propertiesDemo() async {
  print('\n2. --- Свойства ---');

  final source = Stream<int>.fromIterable([10, 20, 30]);
  final view = StreamView<int>(source);

  print('first: ${await view.first}');
  print('last: ${await view.last}');
  print('length: ${await view.length}');
  print('isEmpty: ${await view.isEmpty}');
  print(
    'single: ${await StreamView<int>(Stream<int>.fromIterable([99])).single}',
  );
  print('isBroadcast: ${view.isBroadcast}');
  print('hashCode: ${view.hashCode}');
  print('runtimeType: ${view.runtimeType}');
  print('toString: ${view.toString()}');
}

// =======================================================
// 3. Методы StreamView
// =======================================================
Future<void> methodsDemo() async {
  print('\n3. --- Методы ---');

  final source = Stream<int>.fromIterable([1, 2, 3, 4, 5]);
  final view = StreamView<int>(source);

  // any
  print('any >3: ${await view.any((e) => e > 3)}');

  // asyncMap
  await view
      .asyncMap((e) async => e * 10)
      .forEach((e) => print('asyncMap: $e'));

  // where
  await view.where((e) => e.isEven).forEach((e) => print('where even: $e'));

  // map
  await view.map((e) => 'val=$e').forEach((e) => print('map: $e'));

  // expand
  await view.expand((e) => [e, e * 100]).forEach((e) => print('expand: $e'));

  // distinct
  final d = StreamView<int>(Stream<int>.fromIterable([1, 1, 2, 2, 3]));
  await d.distinct().forEach((e) => print('distinct: $e'));

  // fold
  final sum = await view.fold<int>(0, (prev, e) => prev + e);
  print('fold sum: $sum');

  // join
  print('join: ${await view.join(",")}');

  // toList / toSet
  print('toList: ${await view.toList()}');
  print('toSet: ${await view.toSet()}');

  // timeout
  final slow = StreamView<int>(
    Stream<int>.periodic(const Duration(milliseconds: 200), (i) => i).take(2),
  );
  try {
    await slow.timeout(const Duration(milliseconds: 100)).forEach(print);
  } catch (e) {
    print('timeout пойман: $e');
  }

  // transform
  final transformer = StreamTransformer<int, String>.fromBind(
    (s) => s.map((e) => 'num=$e'),
  );
  await view.transform(transformer).forEach((e) => print('transform: $e'));

  // pipe
  final controller = StreamController<int>();
  controller.stream.listen((e) => print('pipe получил: $e'));
  await view.pipe(controller.sink);
  await controller.close();
}

// =======================================================
// 4. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n4. --- Оператор == ---');

  final source1 = Stream<int>.fromIterable([1]);
  final source2 = Stream<int>.fromIterable([1]);

  final v1 = StreamView<int>(source1);
  final v2 = StreamView<int>(source2);
  final v3 = v1;

  print('v1 == v2: ${v1 == v2}'); // false, разные объекты
  print('v1 == v3: ${v1 == v3}'); // true, одна и та же ссылка
}
