/// *************** Фабричные конструкторы ************************
///
/**
 - Навигация по элементам: first, last, single, их варианты OrNull.
 - Состояние коллекции: isEmpty, isNotEmpty, length.
 - Обход: iterator, indexed, reversed.
 - Фильтрация: nonNulls.
 - Interop: toJS, toJSProxyOrRef.
 - Асинхронность: wait.
 - Системные свойства: hashCode, runtimeType.
 */
///
void empty() {
  /// Создаёт пустой список
  /// List.empty({bool growable = false})
  /// growable: если true, список можно расширять (add, insert и т.д.).
  /// Если false, список фиксированного размера
  var fixedEmpty = List<int>.empty(); // пустой, фиксированный
  var growableEmpty = List<int>.empty(
    growable: true,
  ); // пустой, но можно добавлять
  growableEmpty.add(42); // ✅ работает
  print(fixedEmpty);
}

void filled() {
  /// Создаёт список заданной длины, заполняя все элементы значением fill
  /// List.filled(int length, E fill, {bool growable = false})
  /// fill: значение для каждого элемента.
  /// growable: можно ли изменять размер. по умолчанию нет
  var fixedFilled = List<String>.filled(3, 'init');

  var growableFilled = List<int>.filled(2, 0, growable: true);
  growableFilled.add(5); // теперь [0, 0, 5]
  print(fixedFilled); // ['init', 'init', 'init']
}

void from() {
  /// Создаёт список, копируя все элементы из переданного Iterable
  /// List.from(Iterable elements, {bool growable = true})
  /// elements: источник (например, другой список, Set, Iterable).
  /// growable: можно ли изменять размер. по умолчанию МОЖЕТ
  var source = {1, 2, 3}; // Set

  var list = List<int>.from(source); // [1, 2, 3]
  print(list);
}

void of() {
  /// Почти как List.from, но типизирован жёстче — принимает Iterable<E> и создаёт список того же типа.
  /// List.of(Iterable<E> elements, {bool growable = true})
  var _ = List<String>.of(['a', 'b', 'c']); // ['a', 'b', 'c']
}

void generate() {
  /// Генерирует список заданной длины, где каждый элемент вычисляется функцией
  /// List.generate(int length, E generator(int index), {bool growable = true})
  /// length: длина списка.
  /// generator: функция, принимающая индекс и возвращающая значение.
  /// growable: можно ли изменять размер. по умолчанию МОЖЕТ
  var _ = List<int>.generate(5, (i) => i * i);
  // [0, 1, 4, 9, 16]
}

void unmodifiable() {
  /// Создаёт список, который нельзя изменять (ни добавлять, ни удалять, ни менять элементы).
  /// List.unmodifiable(Iterable elements)
  var unmod = List<int>.unmodifiable([1, 2, 3]);
  unmod[0] = 10; // ❌ ошибка
  unmod.add(4); // ❌ ошибка
}

/// *************** Свойства ************************
void first() {
  /// Возвращает первый элемент списка/итератора.
  /// Если список пустой → выбрасывает исключение.
  var list = [10, 20, 30];
  print(list.first); // 10
}

void firstOrNull() {
  /// Расширение из IterableExtensions. Возвращает первый элемент
  /// или null, если коллекция пуста.
  var empty = <int>[];
  print(empty.firstOrNull); // null
}

void hashCode() {
  /// Уникальный хэш-код объекта (для сравнения/Map ключей).
  var list = [1, 2, 3];
  print(list.hashCode); // какое-то число
}

/// Это как enumerate в Python
void indexed() {
  /// Расширение из IterableExtensions. Возвращает record пары (index, element)
  /// для каждого элемента.
  /// indexed → Iterable<(int, T)>
  var list = ['a', 'b'];
  for (var (i, e) in list.indexed) {
    print('$i -> $e');
  }
  // 0 -> a
  // 1 -> b
}

void isEmpty() {
  /// Проверяет, пустая ли коллекция.
  [].isEmpty; // true
}

void isNotEmpty() {
  /// Проверяет, есть ли хотя бы один элемент.
  [].isNotEmpty; // false
}

void iterator() {
  /// Возвращает объект-итератор для обхода элементов вручную.
  var it = [1, 2].iterator;
  while (it.moveNext()) {
    print(it.current);
  }
}

void last() {
  /// Возвращает последний элемент списка.
  /// Если список пустой → исключение.
  [1, 2, 3].last; // 3
}

void lastOrNull() {
  /// Расширение из IterableExtensions. Возвращает последний элемент или null,
  /// если коллекция пуста.
  [].lastOrNull; // null
}

void length() {
  /// Количество элементов в списке.
  [1, 2, 3].length; // 3
}

void nonNulls() {
  /// Расширение из NullableIterableExtensions. Возвращает только ненулевые элементы.
  var list = [1, null, 2];
  print(list.nonNulls.toList()); // [1, 2]
}

void reversed() {
  /// Возвращает итератор элементов в обратном порядке.
  [1, 2, 3].reversed.toList(); // [3, 2, 1]
}

void runtimeType() {
  /// Тип объекта во время выполнения.
  print([1, 2, 3].runtimeType); // List<int>
}

void single() {
  /// Проверяет, что коллекция содержит ровно один элемент, и возвращает его.
  ['only'].single; // 'only'
}

void singleOrNull() {
  /// Расширение из IterableExtensions. Возвращает единственный
  /// элемент или null, если коллекция пуста.
  [].singleOrNull; // null
}

void wait() async {
  /// Расширение из FutureIterable. Если коллекция содержит Future<T>,
  /// то wait ждёт их все параллельно и возвращает список результатов.
  var futures = [Future.value(1), Future.value(2)];
  var results = await futures.wait; // [1, 2]
  print(results);
}

/// *************** Методы ************************
void add() {
  /// Добавление элементов
  var list = [1, 2];
  list.add(3); // [1, 2, 3]
  list.addAll([4, 5]); // [1, 2, 3, 4, 5]
  list.insert(1, 99); // [1, 99, 2, 3, 4, 5]
  list.insertAll(2, [7, 8]); // [1, 99, 7, 8, 2, 3, 4, 5]
  /// Лениво добавить элементы
  list.followedBy([12, 13]); // [1, 99, 7, 8, 2, 3, 4, 5, 12, 13]
}

void clear() {
  /// Удаление элементов
  var list = [1, 2, 3, 4];

  /// Удаление по значению
  list.remove(2); // [1, 3, 4]

  /// Удаление по индексу
  list.removeAt(0); // [3, 4]
  list.removeLast(); // [3]
  list.removeRange(0, 2);
  list.removeWhere((element) => element > 2);
  list.clear(); // []
}

void element() {
  /// Доступ к элементам
  var list = [10, 20, 30, 40, 50, 60, 70, 80];
  print(list.elementAt(1)); // 20
  print(list.elementAtOrNull(5)); // null
  print(list.firstWhere((e) => e > 15)); // 20
  print(list.lastWhere((e) => e < 30)); // 20
  print(list.sublist(2, 5));
}

void search() {
  /// Проверки и поиск
  var list = [1, 2, 3, 4];
  print(list.any((e) => e > 3)); // true
  print(list.every((e) => e < 5)); // true
  print(list.contains(2)); // true
  print(list.indexOf(3)); // 2
  print(list.lastIndexOf(4)); // 3
  print(list.indexWhere((e) => e.isEven)); // 1
}

void map() {
  /// Преобразования
  var list = [1, 2, 3];
  var _ = list.map((e) => e * 2); // [2, 4, 6]
  var _ = list.expand((e) => [e, -e]); // [1, -1, 2, -2, 3, -3]
  var _ = list.where((e) => e.isOdd); // [1, 3]
  var _ = list.cast<num>(); // List<num>
  print(list.join('-')); // "1-2-3"
}

void iterable() {
  /// Итерации и обход
  var list = [1, 2, 3];
  for (var e in list) {
    print(e);
  } // 1, 2, 3
  var _ = list.fold(0, (prev, e) => prev + e); // 6 sum
  var _ = list.reduce((a, b) => a + b); // 6
  var _ = list.skip(1); // [2, 3]
  var _ = list.take(2); // [1, 2]
}

void modify() {
  /// Модификация диапазонов
  var list = [0, 0, 0, 0];
  list.fillRange(1, 3, 5); // [0, 5, 5, 0]
  list.replaceRange(0, 2, [9, 9]); // [9, 9, 5, 0]
  list.setAll(2, [7, 8]); // [9, 9, 7, 8]
  list.setRange(1, 3, [1, 2, 3]); // [9, 1, 2, 8]
}

void sorted() {
  /// Сортировка и случайность
  var list = [3, 1, 2];
  list.sort(); // [1, 2, 3]
  list.shuffle(); // случайный порядок, например [2, 3, 1]
}

enum Color { red, green, blue }

void extend() {
  /// Дополнительные возможности
  var list = ['a', 'b', 'c'];
  print(list.asMap()); // {0: a, 1: b, 2: c}

  var colors = Color.values;
  print(
    colors.asNameMap(),
  ); // {red: Color.red, green: Color.green, blue: Color.blue}
  print(colors.byName('green')); // Color.green
}
