import 'dart:collection'; // Для явного использования HashSet, если нужно

void main() {
  print('=== 1. КОНСТРУКТОРЫ (Constructors) ===');

  // Set() - Пустой набор (по умолчанию LinkedHashSet)
  Set<int> emptySet = {};
  emptySet.add(1);
  print('Пустой Set + 1: $emptySet');

  // Set.from(iterable) - Из существующего списка (удаляет дубликаты)
  List<int> listWithDups = [1, 2, 2, 3];
  Set<int> fromList = Set.from(listWithDups);
  print('Set.from([1, 2, 2, 3]): $fromList');

  // Set.of(iterable) - Типобезопасное создание

  Set<String> ofSet = {'a', 'b'};
  print('Set.of: $ofSet');
  // Set.identity() - Сравнение по ссылке (identity), а не по значению ==
  // Полезно, если нужны разные объекты с одинаковым содержимым
  Set<List<int>> identitySet = Set.identity();
  List<int> listA = [1, 2];
  List<int> listB = [1, 2]; // Содержимое такое же, но объект другой
  identitySet.add(listA);
  identitySet.add(listB);
  print(
    'Set.identity (два списка [1,2]): ${identitySet.length} элемента (должно быть 2)',
  );

  // Set.unmodifiable(iterable) - Нельзя менять после создания
  Set<int> readOnly = Set.unmodifiable([10, 20]);
  print('Unmodifiable Set: $readOnly');
  try {
    readOnly.add(30); // Вызовет ошибку UnsupportedOperation
  } catch (e) {
    print('Ошибка при добавлении в unmodifiable: $e');
  }

  print('\n=== 2. СВОЙСТВА (Properties) ===');
  Set<String> fruits = {'apple', 'banana', 'cherry'};

  print('length: ${fruits.length}'); // 3
  print('isEmpty: ${fruits.isEmpty}'); // false
  print('isNotEmpty: ${fruits.isNotEmpty}'); // true
  print(
    'first: ${fruits.first}',
  ); // Первый элемент (порядок вставки для LinkedHashSet)
  print('last: ${fruits.last}'); // Последний элемент

  // single выбросит ошибку, если элементов != 1
  Set<String> singleFruit = {'melon'};
  print('single: ${singleFruit.single}');

  // Расширения (Extensions) - безопасные версии
  Set<String> emptyFruits = {};
  print(
    'firstOrNull (пустой): ${emptyFruits.firstOrNull}',
  ); // null вместо ошибки
  print('lastOrNull (пустой): ${emptyFruits.lastOrNull}'); // null
  print('singleOrNull (пустой): ${emptyFruits.singleOrNull}'); // null

  // indexed - пары (индекс, значение)
  print('indexed: ');
  for (var pair in fruits.indexed) {
    print('  Индекс ${pair.$1}: ${pair.$2}');
  }

  print('\n=== 3. ДОБАВЛЕНИЕ И УДАЛЕНИЕ (Modification) ===');
  Set<int> numbers = {1, 2, 3};

  // add(value) -> bool
  bool isNew = numbers.add(4); // true (добавлен)
  bool isDup = numbers.add(2); // false (уже был)
  print('После add(4) и add(2): $numbers (isNew=$isNew, isDup=$isDup)');

  // addAll(iterable)
  numbers.addAll([5, 6, 6]);
  print('После addAll([5, 6, 6]): $numbers');

  // remove(value) -> bool
  bool removed = numbers.remove(3);
  print('Удалили 3? $removed. Набор: $numbers');

  // removeAll(iterable)
  numbers.removeAll([1, 5]);
  print('После removeAll([1, 5]): $numbers');

  // clear()
  Set<int> toClear = {10, 20};
  toClear.clear();
  print('После clear(): $toClear');

  // removeWhere(test) - удалить те, что соответствуют условию
  Set<int> numsFilter = {1, 2, 3, 4, 5};
  numsFilter.removeWhere((x) => x.isEven); // Удаляем четные
  print('removeWhere (оставили нечетные): $numsFilter');

  // retainWhere(test) - оставить ТОЛЬКО те, что соответствуют условию
  Set<int> numsRetain = {1, 2, 3, 4, 5};
  numsRetain.retainWhere((x) => x > 2); // Оставляем только > 2
  print('retainWhere (>2): $numsRetain');

  // retainAll(iterable) - пересечение с другим набором (оставляет общие)
  Set<int> numsRetainAll = {1, 2, 3};
  numsRetainAll.retainAll([2, 3, 4]); // Останутся только 2 и 3
  print('retainAll([2,3,4]): $numsRetainAll');

  print('\n=== 4. ПРОВЕРКА НАЛИЧИЯ (Lookup) ===');
  Set<String> colors = {'red', 'green', 'blue'};

  // contains
  print('contains("green"): ${colors.contains("green")}');

  // containsAll
  print('containsAll(["red", "blue"]): ${colors.containsAll(["red", "blue"])}');

  // lookup - возвращает сам объект из набора (важно для кастомных объектов)
  // Для строк это менее заметно, но для классов критично
  String? found = colors.lookup('red');
  print('lookup("red"): $found');
  print('lookup("yellow"): ${colors.lookup("yellow")}'); // null

  print('\n=== 5. МАТЕМАТИКА МНОЖЕСТВ (Set Operations) ===');
  Set<int> setA = {1, 2, 3, 4};
  Set<int> setB = {3, 4, 5, 6};

  // union - объединение
  print('Union: ${setA.union(setB)}'); // {1, 2, 3, 4, 5, 6}

  // intersection - пересечение (общие)
  print('Intersection: ${setA.intersection(setB)}'); // {3, 4}

  // difference - разность (что есть в A, но нет в B)
  print('Difference (A - B): ${setA.difference(setB)}'); // {1, 2}

  print('\n=== 6. ITERABLE МЕТОДЫ (Обработка) ===');
  Set<int> data = {1, 2, 3, 4, 5};

  // forEach
  print('forEach output: ');
  for (var x in data) {
    print('  Элемент: $x');
  }
  // ВАЖНО: Внутри forEach нельзя делать data.add() или data.remove()!

  // map -> Iterable (не Set!)
  List<int> doubled = data.map((x) => x * 2).toList();
  print('Map (x*2) to List: $doubled');

  // where -> Iterable
  List<int> evens = data.where((x) => x.isEven).toList();
  print('Where (even): $evens');

  // whereType<T>
  Set<Object> mixed = {1, 'hello', 2, 'world'};
  List<String> stringsOnly = mixed.whereType<String>().toList();
  print('whereType<String>: $stringsOnly');

  // any -> bool (хотя бы один)
  print('Any > 4?: ${data.any((x) => x > 4)}');

  // every -> bool (все)
  print('Every < 10?: ${data.every((x) => x < 10)}');

  // fold (сумма)
  int sum = data.fold(0, (prev, element) => prev + element);
  print('Fold (sum): $sum');

  // reduce (минимум)
  int minVal = data.reduce((a, b) => a < b ? a : b);
  print('Reduce (min): $minVal');

  // join
  print('Join ("-"): ${data.join("-")}');

  // toList / toSet
  List<int> listFromSet = data.toList();
  Set<int> setFromSet = data.toSet();
  print(listFromSet);
  print(setFromSet);

  // Поиск элементов
  print('firstWhere (>3): ${data.firstWhere((x) => x > 3)}');
  print('lastWhere (<4): ${data.lastWhere((x) => x < 4)}');
  // orElse для безопасности
  print(
    'firstWhere (>100, orElse: 0): ${data.firstWhere((x) => x > 100, orElse: () => 0)}',
  );

  // skip / take
  print('skip(2): ${data.skip(2).toList()}'); // Пропустить первые 2
  print('take(2): ${data.take(2).toList()}'); // Взять первые 2
  print('skipWhile (<3): ${data.skipWhile((x) => x < 3).toList()}');
  print('takeWhile (<3): ${data.takeWhile((x) => x < 3).toList()}');

  // followedBy (конкатенация ленивая)
  Set<int> moreData = {10, 11};
  print('followedBy: ${data.followedBy(moreData).toList()}');

  // expand (преобразование 1 элемента в много)
  List<int> expanded = data.expand((x) => [x, x * 10]).toList();
  print('Expand (x, x*10): $expanded');

  print('\n=== 7. СПЕЦИФИЧНЫЕ МЕТОДЫ И ОПЕРАТОРЫ ===');

  // cast<R>() - приведение типа
  Set<int> ints = {1, 2, 3};
  // Создаем view как Set<num>
  Set<num> numsView = ints.cast<num>();
  print('Cast to num: $numsView (тип runtime: ${numsView.runtimeType})');

  // elementAt(index) - медленно для Set, но работает
  print('elementAt(1): ${data.elementAt(1)}');

  // elementAtOrNull (из расширения)
  print('elementAtOrNull(100): ${data.elementAtOrNull(100)}'); // null

  // operator == (сравнение наборов)
  Set<int> setCopy = {1, 2, 3, 4, 5};
  Set<int> setDiffOrder = {5, 4, 3, 2, 1};
  print('setA == setCopy: ${data == setCopy}'); // true (содержимое равно)
  print(
    'setA == setDiffOrder: ${data == setDiffOrder}',
  ); // true (порядок не важен для равенства содержимого)

  // toString()
  print('toString: ${data.toString()}');

  // Static Method: castFrom
  List<int> sourceList = [1, 2, 3];
  Set<int> castedSet = Set.castFrom<Set<int>, int>(Set.from(sourceList));
  print('Static castFrom: $castedSet');

  print('\n=== ГОТОВО ===');
}
