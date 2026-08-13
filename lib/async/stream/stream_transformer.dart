// stream_transformer_cheatsheet.dart
//
// Демонстрация возможностей StreamTransformer<S, T>.
// Показывает работу конструкторов, методов, свойств, оператора == и статических методов.
// Используем простые примеры для наглядности.
//
// Запуск:
//   dart run stream_transformer_cheatsheet.dart

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAMTRANSFORMER ---\n');

  await fromHandlersDemo();
  await fromBindDemo();
  await customTransformerDemo();
  await propertiesDemo();
  await methodsDemo();
  await operatorsDemo();
  await staticMethodsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. StreamTransformer.fromHandlers
// =======================================================
Future<void> fromHandlersDemo() async {
  print('1. --- fromHandlers ---');

  // Создаём трансформер, который удваивает числа,
  // перехватывает ошибки и добавляет сообщение при завершении.
  final transformer = StreamTransformer<int, String>.fromHandlers(
    handleData: (data, sink) {
      sink.add('double=${data * 2}');
    },
    handleError: (error, stackTrace, sink) {
      sink.add('error=$error');
    },
    handleDone: (sink) {
      sink.add('done marker');
      sink.close();
    },
  );

  final source = Stream<int>.fromIterable([1, 2, 3]);
  final transformed = source.transform(transformer);

  await transformed.forEach((e) => print('transformed: $e'));
}

// =======================================================
// 2. StreamTransformer.fromBind
// =======================================================
Future<void> fromBindDemo() async {
  print('\n2. --- fromBind ---');

  // fromBind принимает функцию bind, которая сама возвращает новый Stream.
  final transformer = StreamTransformer<int, String>.fromBind(
    (stream) => stream.map((e) => 'val=$e'),
  );

  final source = Stream<int>.fromIterable([10, 20]);
  final transformed = source.transform(transformer);

  await transformed.forEach((e) => print('fromBind: $e'));
}

// =======================================================
// 3. StreamTransformer (кастомный bind)
// =======================================================
Future<void> customTransformerDemo() async {
  print('\n3. --- custom bind ---');

  // Создаём трансформер вручную через конструктор StreamTransformer.
  final transformer = StreamTransformer<int, int>.fromBind(
    (stream) => stream.where((e) => e.isEven).map((e) => e * 100),
  );

  final source = Stream<int>.fromIterable([1, 2, 3, 4]);
  final transformed = source.transform(transformer);

  await transformed.forEach((e) => print('custom transformer: $e'));
}

// =======================================================
// 4. Свойства StreamTransformer
// =======================================================
Future<void> propertiesDemo() async {
  print('\n4. --- Свойства ---');

  final transformer = StreamTransformer<int, String>.fromBind(
    (s) => s.map((e) => 'x$e'),
  );

  print('hashCode: ${transformer.hashCode}');
  print('runtimeType: ${transformer.runtimeType}');
  print('toString: ${transformer.toString()}');
}

// =======================================================
// 5. Методы StreamTransformer
// =======================================================
Future<void> methodsDemo() async {
  print('\n5. --- Методы ---');

  final transformer = StreamTransformer<int, String>.fromBind(
    (s) => s.map((e) => 'num=$e'),
  );

  final source = Stream<int>.fromIterable([5, 6]);
  final transformed = transformer.bind(source);

  await transformed.forEach((e) => print('bind result: $e'));

  // cast: адаптировать типы трансформера
  final casted = transformer.cast<num, String>();
  final source2 = Stream<num>.fromIterable([7, 8]);
  await casted.bind(source2).forEach((e) => print('casted result: $e'));
}

// =======================================================
// 6. Оператор ==
// =======================================================
Future<void> operatorsDemo() async {
  print('\n6. --- Оператор == ---');

  final t1 = StreamTransformer<int, String>.fromBind((s) => s.map((e) => '$e'));
  final t2 = StreamTransformer<int, String>.fromBind((s) => s.map((e) => '$e'));
  final t3 = t1;

  print('t1 == t2: ${t1 == t2}'); // false, разные объекты
  print('t1 == t3: ${t1 == t3}'); // true, одна и та же ссылка
}

// =======================================================
// 7. Статический метод castFrom
// =======================================================
Future<void> staticMethodsDemo() async {
  print('\n7. --- castFrom ---');

  final base = StreamTransformer<int, int>.fromBind(
    (s) => s.map((e) => e * 10),
  );

  // castFrom: адаптируем трансформер к другим типам
  final adapted = StreamTransformer.castFrom<int, int, num, num>(base);

  final source = Stream<num>.fromIterable([1, 2, 3]);
  final transformed = adapted.bind(source);

  await transformed.forEach((e) => print('castFrom result: $e'));
}
