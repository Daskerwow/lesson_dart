/**
 * 
 * Существует два типа потоков: потоки «для одной подписки» и потоки «широковещания».
 * 
 *    * Поток, созданный функцией, async* является потоком с одной подпиской, но каждый вызов функции создает новый такой поток.
 *    - Прослушивание дважды одной и той же трансляции по подписке запрещено, даже после отмены первой подписки.
 *    - Потоки с одной подпиской обычно используются для потоковой передачи больших объемов непрерывных данных, например, при файловом вводе-выводе.
 *    * Широковещательный поток допускает любое количество слушателей и генерирует свои события, когда они готовы, независимо от того, есть слушатели или нет.
 *    - Трансляции используются для независимых мероприятий/наблюдателей.
 *    - Если несколько слушателей хотят слушать один и тот же поток по подписке, используйте функцию asBroadcastStream 
 *    - для создания транслируемого потока поверх нетранслируемого потока.
 *    
 *    Когда срабатывает событие «готово», подписчики отписываются до получения события.
 *    После отправки события у потока нет подписчиков. Добавление новых подписчиков к трансляционному 
 *    потоку после этого момента разрешено, но они просто получат новое событие «готово» как можно скорее.
 *    Подписки на потоковое вещание всегда учитывают запросы на "паузу". При необходимости им нужно 
 *    буферизовать входящий сигнал, но часто, и предпочтительнее, они могут просто запросить паузу и для самого входящего сигнала.
 * 
 * Функция forEach соответствует циклу await for, так же как Iterable.forEach соответствует 
 * обычному циклу for in. Подобно циклу, она будет вызывать функцию для каждого события 
 * данных и останавливаться при возникновении ошибки.
 * 
 * Вы вызываете listen метод для потока, чтобы сообщить ему, что хотите получать события, 
 * и зарегистрировать функции обратного вызова, которые будут получать эти события. 
 * При вызове listen вы получаете объект [StreamSubscription], который является активным
 */

///
// stream_cheatsheet.dart
//
// Полный учебный файл по Stream в Dart.
// Покрывает: конструкторы, свойства, методы, оператор, статический метод.
// Каждый пример максимально прикладной и прокомментированный.
//
// Запуск:
//   dart run stream_cheatsheet.dart
//
// Вывод показывает поведение каждого API.

import 'dart:async';

void main() async {
  print('--- НАЧАЛО УРОКА ПО STREAM ---\n');

  await constructorsDemo();
  await propertiesDemo();
  await methodsDemo();
  await operatorsDemo();
  await staticMethodsDemo();

  print('\n--- КОНЕЦ УРОКА ---');
}

// =======================================================
// 1. Конструкторы Stream
// =======================================================
Future<void> constructorsDemo() async {
  print('1. --- Конструкторы Stream ---');

  // 1) Stream.empty: пустой поток, сразу завершается.
  // Важная опция broadcast: true - можно подписываться многократно.
  // В обычном (single-subscription) пустом потоке повторная подписка приведет к ошибке.
  {
    print('\n1.1 Stream.empty (broadcast)');
    final s = Stream<int>.empty(broadcast: true);
    print('isBroadcast: ${s.isBroadcast}');
    s.listen((v) => print('data: $v'), onDone: () => print('done #1'));
    s.listen((v) => print('data: $v'), onDone: () => print('done #2'));
  }

  // 2) Stream.error: поток, который сразу эмитит ОДНО событие ошибки и завершится.
  {
    print('\n1.2 Stream.error');
    final s = Stream<int>.error(StateError('Ошибка в потоке'));
    s.listen(
      (v) => print('data: $v'),
      onError: (e, st) => print('error: $e'),
      onDone: () => print('done'),
    );
    // Важно: без обработчика onError подписка бросит исключение.
  }

  // 3) Stream.eventTransformed: трансформирует события исходного потока через EventSink.
  // Покажем: каждый входящий элемент удваиваем, ошибки пропускаем, done передаем.
  {
    print('\n1.3 Stream.eventTransformed');
    final source = Stream<int>.fromIterable([1, 2, 3]);
    final transformed = Stream<int>.eventTransformed(source, (
      EventSink<int> sink,
    ) {
      // Возвращаем "прокси"-sink, который определяет, как обрабатывать входящие события.
      // Этот sink будет получать события от исходного stream через add/addError/close.
      return _DoublingSink(sink);
    });
    transformed.listen((v) => print('data: $v'), onDone: () => print('done'));
  }

  // 4) Stream.fromFuture: создаёт поток из одного Future.
  // Если Future завершится значением -> один data event. Если ошибкой -> один error event.
  {
    print('\n1.4 Stream.fromFuture');
    final s1 = Stream<int>.fromFuture(Future.value(10));
    await s1.forEach((v) => print('data (value): $v'));

    final s2 = Stream<int>.fromFuture(Future<int>.error('boom'));
    s2.listen(
      (v) => print('data (error-case): $v'),
      onError: (e, _) => print('error: $e'),
      onDone: () => print('done'),
    );
  }

  // 5) Stream.fromFutures: поток из набора Future.
  // Эмитит результаты по мере завершения каждого Future (в том же порядке вызовов).
  // Ошибки будут эмититься как error events и НЕ прерывают поток (он продолжит для остальных).
  {
    print('\n1.5 Stream.fromFutures');
    final futures = <Future<int>>[
      Future.delayed(const Duration(milliseconds: 300), () => 1),
      Future<int>.error('ошибка посередине'),
      Future.delayed(const Duration(milliseconds: 100), () => 3),
    ];
    final s = Stream<int>.fromFutures(futures);
    s.listen(
      (v) => print('data: $v'),
      onError: (e, _) => print('error: $e'),
      onDone: () => print('done'),
    );
  }

  // 6) Stream.fromIterable: поток от Iterable.
  // Эмитит последовательно все элементы и завершается.
  {
    print('\n1.6 Stream.fromIterable');
    final s = Stream<String>.fromIterable(['a', 'b', 'c']);
    await s.forEach((v) => print('data: $v'));
  }

  // 7) Stream.multi: multi-subscription поток.
  // Удобно, когда нужно контролировать подписки и эмиссию нескольким подписчикам.
  {
    print('\n1.7 Stream.multi (multi-subscription)');
    final s = Stream<int>.multi((controller) {
      // MultiStreamController позволяет управлять событиями и жизненным циклом.
      controller.add(10);
      controller.add(20);
      controller.add(30);
      controller.close();
    }, isBroadcast: true);
    print('isBroadcast: ${s.isBroadcast}');
    s.listen((v) => print('sub1: $v'), onDone: () => print('sub1 done'));
    s.listen((v) => print('sub2: $v'), onDone: () => print('sub2 done'));
  }

  // 8) Stream.periodic: периодический поток.
  // computation принимает счетчик (0..∞) и возвращает значение события.
  // Важно: этот поток бесконечный, поэтому ограничим take(5).
  {
    print('\n1.8 Stream.periodic');
    final s = Stream<int>.periodic(
      const Duration(milliseconds: 150),
      (count) => count * 10, // 0, 10, 20, ...
    ).take(5);
    await s.forEach((v) => print('tick: $v'));
  }

  // 9) Stream.value: один data event и закрытие.
  {
    print('\n1.9 Stream.value');
    final s = Stream<String>.value('один раз и закрылись');
    s.listen((v) => print('data: $v'), onDone: () => print('done'));
  }
}

// Вспомогательный sink для eventTransformed: удваивает data события.
class _DoublingSink implements EventSink<int> {
  final EventSink<int> _out;
  _DoublingSink(this._out);
  @override
  void add(int event) => _out.add(event * 2);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _out.addError(error, stackTrace);
  @override
  void close() => _out.close();
}

// =======================================================
// 2. Свойства Stream
// =======================================================
Future<void> propertiesDemo() async {
  print('\n2. --- Свойства Stream ---');

  // first: Future первого элемента (или ошибка, если нет элементов).
  {
    print('\n2.1 first');
    final s = Stream<int>.fromIterable([7, 8, 9]);
    final first = await s.first;
    print('first: $first');
  }

  // isBroadcast: признак многоподписного потока.
  {
    print('\n2.2 isBroadcast');
    final single = Stream<int>.fromIterable([1, 2, 3]); // single-subscription
    print('single.isBroadcast: ${single.isBroadcast}');
    final broadcast = Stream<int>.empty(broadcast: true);
    print('broadcast.isBroadcast: ${broadcast.isBroadcast}');
  }

  // isEmpty: Future<bool> — пустой ли поток (без элементов).
  {
    print('\n2.3 isEmpty');
    final s1 = Stream<int>.empty();
    print('empty.isEmpty: ${await s1.isEmpty}');
    final s2 = Stream<int>.fromIterable([1]);
    print('nonEmpty.isEmpty: ${await s2.isEmpty}');
  }

  // last: Future последнего элемента (ошибка на пустом).
  {
    print('\n2.4 last');
    final s = Stream<String>.fromIterable(['x', 'y', 'z']);
    print('last: ${await s.last}');
  }

  // length: Future<int> количества элементов (перебирает весь поток).
  {
    print('\n2.5 length');
    final s = Stream<int>.fromIterable(List.generate(5, (i) => i)); // 0..4
    print('length: ${await s.length}');
  }

  // single: Future единственного элемента (ошибка, если 0 или >1).
  {
    print('\n2.6 single');
    final s = Stream<String>.fromIterable(['only']);
    print('single: ${await s.single}');
  }

  // hashCode / runtimeType: как у любых объектов.
  {
    print('\n2.7 hashCode / runtimeType');
    final s = Stream<double>.value(3.14);
    print('hashCode: ${s.hashCode}');
    print('runtimeType: ${s.runtimeType}');
  }
}

// =======================================================
// 3. Методы Stream
// =======================================================
Future<void> methodsDemo() async {
  print('\n3. --- Методы Stream ---');

  // any: есть ли хоть один элемент, удовлетворяющий условию.
  {
    print('\n3.1 any');
    final s = Stream<int>.fromIterable([2, 4, 6, 7]);
    print('any(isOdd): ${await s.any((e) => e.isOdd)}'); // true, потому что 7
  }

  // asBroadcastStream: превращает single-subscription поток в multi-subscription.
  // Можно передать onListen/onCancel для управления подписками.
  {
    print('\n3.2 asBroadcastStream');
    final source = Stream<int>.fromIterable([1, 2, 3]);
    final b = source.asBroadcastStream(
      onListen: (sub) => print('onListen: подписка создана'),
      onCancel: (sub) => print('onCancel: подписка отменена'),
    );
    b.listen((v) => print('sub1: $v'));
    b.listen((v) => print('sub2: $v'));
  }

  // asyncExpand: каждый элемент -> поток, затем все потоки конкатенируются асинхронно.
  {
    print('\n3.3 asyncExpand');
    final s = Stream<int>.fromIterable([
      1,
      2,
      3,
    ]).asyncExpand((v) => Stream<int>.fromIterable([v, v * 10]));
    await s.forEach((e) => print('data: $e')); // 1,10,2,20,3,30
  }

  // asyncMap: каждый элемент асинхронно мапится (через Future) в новое значение.
  {
    print('\n3.4 asyncMap');
    final s = Stream<int>.fromIterable([1, 2, 3]).asyncMap(
      (v) => Future.delayed(const Duration(milliseconds: 50), () => v * 100),
    );
    await s.forEach((e) => print('data: $e')); // 100, 200, 300
  }

  // cast<R>: адаптирует тип потока (при условии совместимости).
  {
    print('\n3.5 cast');
    final s = Stream<num>.fromIterable([1, 2, 3]);
    final sInt = s.cast<int>(); // num -> int (значения совместимы)
    await sInt.forEach((e) => print('int: $e'));
  }

  // contains: есть ли needle среди элементов (использует equality).
  {
    print('\n3.6 contains');
    final s = Stream<String>.fromIterable(['a', 'b', 'c']);
    print('contains("b"): ${await s.contains('b')}'); // true
  }

  // distinct: пропускает повторяющиеся подряд элементы (по equals).
  {
    print('\n3.7 distinct');
    final s = Stream<int>.fromIterable([1, 1, 2, 2, 2, 3, 1]);
    final d = s.distinct();
    await d.forEach((e) => print('distinct: $e')); // 1,2,3,1
  }

  // drain: игнорирует все данные, но ждёт завершения/ошибки.
  {
    print('\n3.8 drain');
    final s = Stream<int>.periodic(
      const Duration(milliseconds: 50),
      (i) => i,
    ).take(5);
    final result = await s.drain<String>('done-value');
    print('drain result: $result'); // 'done-value'
  }

  // elementAt: получить элемент по индексу (ошибка, если индекс вне диапазона).
  {
    print('\n3.9 elementAt');
    final s = Stream<int>.fromIterable([10, 20, 30]);
    print('elementAt(1): ${await s.elementAt(1)}'); // 20
  }

  // every: все ли элементы удовлетворяют условию.
  {
    print('\n3.10 every');
    final s = Stream<int>.fromIterable([2, 4, 6]);
    print('every(isEven): ${await s.every((e) => e.isEven)}'); // true
  }

  // expand: каждый элемент -> Iterable элементов (синхронно), затем плоский поток.
  {
    print('\n3.11 expand');
    final s = Stream<String>.fromIterable([
      'a',
      'b',
    ]).expand((e) => [e, e.toUpperCase()]);
    await s.forEach((e) => print('expand: $e')); // a,A,b,B
  }

  // firstWhere: первый элемент по предикату, или orElse.
  {
    print('\n3.12 firstWhere');
    final s = Stream<int>.fromIterable([1, 3, 5, 8, 10]);
    print('firstWhere(isEven): ${await s.firstWhere((e) => e.isEven)}'); // 8
  }

  // fold: свертка (reduce с начальными значением другого типа).
  {
    print('\n3.13 fold');
    final s = Stream<int>.fromIterable([1, 2, 3]);
    final sum = await s.fold<int>(0, (prev, e) => prev + e);
    print('fold sum: $sum'); // 6
  }

  // forEach: выполнить действие для каждого элемента.
  {
    print('\n3.14 forEach');
    final s = Stream<String>.fromIterable(['x', 'y']);
    await s.forEach((e) => print('forEach: $e'));
  }

  // handleError: перехват некоторых ошибок, не прерывая исходную подписку.
  {
    print('\n3.15 handleError');
    final s = Stream<int>.fromFutures([
      Future.value(1),
      Future.error('bad'),
      Future.value(3),
    ]).handleError((e) => print('handled error: $e'), test: (e) => e == 'bad');
    await s.forEach((e) => print('data: $e'));
  }

  // join: объединяет элементы в строку (через toString).
  {
    print('\n3.16 join');
    final s = Stream<int>.fromIterable([1, 2, 3]);
    print('join: ${await s.join(',')}'); // "1,2,3"
  }

  // lastWhere: последний элемент по предикату, или orElse.
  {
    print('\n3.17 lastWhere');
    final s = Stream<int>.fromIterable([1, 2, 3, 4, 5]);
    print('lastWhere(isEven): ${await s.lastWhere((e) => e.isEven)}'); // 4
  }

  // listen: подписка на поток, с onData/onError/onDone и cancelOnError.
  {
    print('\n3.18 listen');
    final s = Stream<int>.fromFutures([
      Future.value(10),
      Future.error('oops'),
      Future.value(30),
    ]);
    final sub = s.listen(
      (v) => print('listen data: $v'),
      onError: (e, _) => print('listen error: $e'),
      onDone: () => print('listen done'),
      cancelOnError: false, // если true, отменит подписку при ошибке.
    );
    await sub.asFuture<void>(); // дождаться завершения подписки
  }

  // map: преобразование каждого элемента.
  {
    print('\n3.19 map');
    final s = Stream<int>.fromIterable([1, 2, 3]).map((e) => 'n=$e');
    await s.forEach((e) => print('map: $e'));
  }

  // noSuchMethod: унаследовано от Object; обычно не используется напрямую со Stream.
  {
    print('\n3.20 noSuchMethod');
    // В обычном коде не вызывается; покажем лишь, что у объекта есть toString и т.п.
    final s = Stream<bool>.value(true);
    print('toString: ${s.toString()}');
  }

  // pipe: перенаправляет события в StreamConsumer (например, StreamController.sink).
  {
    print('\n3.21 pipe');
    final source = Stream<int>.fromIterable([1, 2, 3]);
    final controller = StreamController<int>();
    final target = controller.sink; // StreamConsumer<int>

    // Слушатель выходного контроллера:
    controller.stream.listen(
      (v) => print('piped: $v'),
      onDone: () => print('piped done'),
    );

    await source.pipe(target); // перенаправит все события и закроет sink
    await controller.close();
  }

  // reduce: свертка к тому же типу, что элементы.
  {
    print('\n3.22 reduce');
    final s = Stream<int>.fromIterable([2, 4, 6]);
    final product = await s.reduce((prev, e) => prev * e);
    print('reduce product: $product'); // 48
  }

  // singleWhere: единственный элемент, удовлетворяющий условию (ошибка если 0 или >1).
  {
    print('\n3.23 singleWhere');
    final s = Stream<int>.fromIterable([1, 2, 3]);
    print('singleWhere(e==2): ${await s.singleWhere((e) => e == 2)}'); // 2
  }

  // skip: пропустить первые count элементов.
  {
    print('\n3.24 skip');
    final s = Stream<int>.fromIterable([10, 20, 30, 40]);
    await s.skip(2).forEach((e) => print('skip: $e')); // 30, 40
  }

  // skipWhile: пропускать пока условие true, затем пропуск прекратить.
  {
    print('\n3.25 skipWhile');
    final s = Stream<int>.fromIterable([1, 2, 3, 1, 0]);
    await s
        .skipWhile((e) => e < 3)
        .forEach((e) => print('skipWhile: $e')); // 3,1,0
  }

  // take: взять первые count элементов.
  {
    print('\n3.26 take');
    final s = Stream<int>.fromIterable([5, 6, 7, 8]);
    await s.take(2).forEach((e) => print('take: $e')); // 5,6
  }

  // takeWhile: брать элементы пока условие true, затем завершиться.
  {
    print('\n3.27 takeWhile');
    final s = Stream<int>.fromIterable([1, 2, 3, 2, 1]);
    await s
        .takeWhile((e) => e < 3)
        .forEach((e) => print('takeWhile: $e')); // 1,2
  }

  // timeout: ограничивает время ожидания следующего события.
  // Если onTimeout не указан — кидает TimeoutException.
  // Если указан — позволяет эмитить альтернативные события/прервать.
  {
    print('\n3.28 timeout');
    final slow = Stream<int>.periodic(
      const Duration(milliseconds: 200),
      (i) => i,
    ).take(3);
    final withTimeout = slow.timeout(
      const Duration(milliseconds: 100), // событие позже дедлайна -> timeout
      onTimeout: (sink) {
        // Можно эмитить альтернативные события:
        sink.add(-1);
        sink.close();
      },
    );
    await withTimeout.forEach((e) => print('timeout stream data: $e')); // -1
  }

  // toList: собрать все элементы в список.
  {
    print('\n3.29 toList');
    final s = Stream<String>.fromIterable(['a', 'b', 'c']);
    print('toList: ${await s.toList()}'); // [a, b, c]
  }

  // toSet: собрать все элементы в множество.
  {
    print('\n3.30 toSet');
    final s = Stream<int>.fromIterable([1, 2, 2, 3]);
    print('toSet: ${await s.toSet()}'); // {1, 2, 3}
  }

  // toString: строковое представление объекта потока (не данных).
  {
    print('\n3.31 toString');
    final s = Stream<double>.value(1.5);
    print('stream toString: $s');
  }

  // transform: применить StreamTransformer к потоку.
  // Пример: в трансформере удваиваем значения и фильтруем ошибки.
  {
    print('\n3.32 transform');
    final s = Stream<int>.fromFutures([
      Future.value(1),
      Future.error('bad'),
      Future.value(3),
    ]).transform(_DoublingTransformer());
    s.listen(
      (v) => print('transform data: $v'),
      onError: (e, _) => print('transform error: $e'),
      onDone: () => print('transform done'),
    );
  }

  // where: фильтрует элементы по предикату.
  {
    print('\n3.33 where');
    final s = Stream<int>.fromIterable([1, 2, 3, 4, 5]).where((e) => e.isEven);
    await s.forEach((e) => print('where even: $e')); // 2,4
  }
}

// Пример StreamTransformer: удваивает значения, ошибки пропускает как есть.
class _DoublingTransformer extends StreamTransformerBase<int, int> {
  @override
  Stream<int> bind(Stream<int> stream) {
    return Stream<int>.eventTransformed(stream, (sink) => _DoublingSink(sink));
  }
}

// =======================================================
// 4. Операторы Stream
// =======================================================
Future<void> operatorsDemo() async {
  print('\n4. --- Операторы Stream ---');

  // operator == (Object other): унаследован от Object.
  // По умолчанию проверяет идентичность (тот же объект).
  {
    print('\n4.1 operator ==');
    final s1 = Stream<int>.fromIterable([1, 2, 3]);
    final s2 = Stream<int>.fromIterable([1, 2, 3]);
    print('s1 == s2: ${s1 == s2}'); // обычно false, разные объекты.
    final s3 = s1;
    print('s1 == s3: ${s1 == s3}'); // true, ссылка на тот же объект.
  }
}

// =======================================================
// 5. Статические методы Stream
// =======================================================
Future<void> staticMethodsDemo() async {
  print('\n5. --- Статические методы Stream ---');

  // castFrom<S, T>: адаптация потока одного типа к другому, без копирования.
  // Работает, если фактические элементы совместимы (иначе будет ошибка во время чтения).
  {
    print('\n5.1 castFrom');
    final source = Stream<num>.fromIterable([1, 2, 3]);
    final casted = Stream.castFrom<num, int>(source);
    await casted.forEach((e) => print('castFrom int: $e'));
  }
}
