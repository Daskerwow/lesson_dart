/// *************** Фабричные конструкторы ************************
///
void mapNew() {
  /// Создаёт пустой LinkedHashMap
  var map = <String, String>{};
  print(map);
}

/// Создать на основе друго Map
void from() {
  /// Копирует ключи и значения из другого Map
  /// Map.from(Map other)
  var original = {'a': 1, 'b': 2};
  var copy = Map.from(original);
  print(copy);
}

/// Создать на основе друго Map
void of() {
  /// То же самое, что Map.from, но более идиоматично.
  /// Map.of(Map other)
  var original = {'x': 42};
  var copy = Map.of(original);
  print(copy); // {x: 42}
}

/// Создать на основе друго Map
void unmodifiable() {
  /// Создаёт карту, которую нельзя изменять.
  /// Map.unmodifiable(Map other)
  var original = {'a': 1};
  var unmod = Map.unmodifiable(original);
  //unmod['b'] = 2; // Ошибка: Unsupported operation
  print(unmod); // {a: 1}
}

/// Создать на основе списка MapEntry<K, V>
void fromEntries() {
  var entries = <MapEntry<String, int>>[MapEntry('x', 10), MapEntry('y', 20)];
  var map = Map.fromEntries(entries);
  print(map);
}

/// не рекомендуется для использовнаия
void fromIterable() {
  /// Map.fromIterable(Iterable iterable, {K key(e), V value(e)})
  var list = <String>['apple', 'banana'];

  /// Генераторное включения
  var mapGen = {for (var item in list) item[0]: item.length};
  print(mapGen);
}

void fromIterables() {
  /// Соединяет два списка в карту.
  /// Map.fromIterables(Iterable<K> keys, Iterable<V> values)
  var keys = ['one', 'two'];
  var values = [1, 2];
  var map = Map.fromIterables(keys, values);
  print(map);
}

void identity() {
  /// Создаёт карту, где сравнение ключей идёт по идентичности (===), а не по ==
  /// Map.identity()
  var key1 = Object();
  var key2 = Object();
  var map = Map.identity();
  map[key1] = 'value1';
  print(map.containsKey(key2)); // false (разные объекты)
}

/// *************** Свойства ************************
void entries() {
  /// Возвращает список MapEntry.
  /// entries
  var map = {'a': 1, 'b': 2};
  for (var e in map.entries) {
    print('${e.key} -> ${e.value}');
    // a -> 1
    // b -> 2
  }
}

void isEmptyIsNotEmpty() {
  /// isEmpty / isNotEmpty
  var mapss = {};
  print(mapss.isEmpty); // true
  print(mapss.isNotEmpty); // false
}

void keysValues() {
  /// Доступ к ключам и значениям.
  /// keys / values
  var map22 = {'a': 1, 'b': 2};
  print(map22.keys); // (a, b)
  print(map22.values); // (1, 2)
}

void length() {
  /// Количество пар.
  /// length
  var map = {'x': 10, 'y': 20};
  print(map.length); // 2
}

void runtimeType() {
  /// Текущий тип.
  var map = {'x': 10, 'y': 20};
  print(map.runtimeType);
}

/// *************** Методы ************************
void addAll() {
  /// Добавляет пары из другой карты.
  /// addAll(Map other)
  var map = {'a': 1};
  map.addAll({'b': 2, 'c': 3});
  print(map); // {a: 1, b: 2, c: 3}
}

void addEntries() {
  /// Добавляет список MapEntry.
  /// addEntries(Iterable<MapEntry>)
  var map = {'a': 1};
  map.addEntries([MapEntry('b', 2), MapEntry('c', 3)]);
  print(map); // {a: 1, b: 2, c: 3}
}

void cast() {
  /// Приводит типы ключей/значений.
  /// cast<RK, RV>()
  var map = {'a': 1} as Map<Object, Object>;
  var casted = map.cast<String, int>();
  print(casted); // {a: 1}
}

void clear() {
  /// Удаляет все элементы.
  /// clear()
  var map = {'a': 1};
  map.clear();
  print(map); // {}
}

void containsKeyContainsValue() {
  /// Проверка наличия.
  /// containsKey / containsValue
  var map = {'a': 1};
  print(map.containsKey('a')); // true
  print(map.containsValue(2)); // false
}

void forEach() {
  /// Итерация по карте.
  /// forEach(action)
  var map = {'a': 1, 'b': 2};
  map.forEach((k, v) => print('$k -> $v'));
}

void map() {
  /// Трансформация в новый Map.
  /// map(convert)
  var map = {'a': 1, 'b': 2};
  var newMap = map.map((k, v) => MapEntry(k.toUpperCase(), v * 10));
  print(newMap); // {A: 10, B: 20}
}

void putIfAbsent() {
  /// Возвращает значение связанное с ключом key, если ключ уже связан с каким‑то значением.
  /// иначе связывает ключ с новым значением. И возвращает его.
  var map = {'a': 1};

  /// так как ключ 'b' отсутствует, то он связывается с новым значением 2
  /// (добавляет в коллекцию ключ 'b' и связывает с ним значение 2)
  /// а после возвращает связанное значение
  map.putIfAbsent('b', () => 2);
  print(map); // {a: 1, b: 2}
}

void remove() {
  /// Удаляет элемент по ключу! если таковой имеется.
  /// иначе вернет null
  /// remove(key)
  var map = {'a': 1, 'b': 2};
  map.remove('a');
  print(map); // {b: 2}
}

void removeWhere() {
  /// Удаляет по условию.
  /// removeWhere(test)
  var map = {'a': 1, 'b': 2, 'c': 3};
  map.removeWhere((k, v) => v.isOdd);
  print(map); // {b: 2}
}

void update() {
  /// Обновляет значение.
  /// update(key, update, {ifAbsent})
  var map = {'a': 1};
  map.update('a', (v) => v + 10);
  map.update('b', (v) => v + 10, ifAbsent: () => 10);
  print(map); // {a: 11, b: 10}
}

void updateAll() {
  /// Обновляет все значения.
  /// updateAll(update)
  var map = {'a': 1, 'b': 2};
  map.updateAll((k, v) => v * 2);
  print(map); // {a: 2, b: 4}
}
