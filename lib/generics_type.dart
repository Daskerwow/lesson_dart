import 'dart:async';

/// ===============================
/// БАЗОВЫЕ ДЖЕНЕРИКИ
/// ===============================
/// Дженерики позволяют параметризовать классы и методы типами.
/// Это даёт безопасность типов и переиспользуемость.
/// Пример: Cache<T> хранит значения любого типа T.
abstract interface class Cache<T> {
  T getByKey(String key);
  void setByKey(String key, T value);
}

// var a = Cache(); // тип аргумента T не указан
// T → dynamic (instantiate-to-bound)
// Так как T == dynamic, возвращаемый тип → dynamic.
// var result = a.getByKey('ss');

/*
 * Важные нюансы:
 * dynamic означает, что компилятор не будет проверять тип результата. 
 * Ты сможешь вызвать на result любые методы, 
 * но ошибки будут только во время выполнения.
 * 
 * Если бы у Cache<T> было ограничение, например:
 * abstract interface class Cache<T extends Object> { ... }
 * то при вызове Cache() без аргумента Dart подставил бы Object (границу) 
 * вместо dynamic.
 * 
 * Если хочешь, чтобы без указания типа возвращался строгий базовый класс, 
 * используй extends с нужной границей.
 * Если оставишь без ограничений, то получишь dynamic, что убирает проверку 
 * типов и может привести к ошибкам во время выполнения.
 */

/// ===============================
/// ОГРАНИЧЕНИЯ (extends)
/// ===============================
/// Ограничение через `extends` задаёт верхнюю границу.
/// Здесь Foo<T> требует, чтобы T был SomeBaseClass или его подтипом.
class SomeBaseClass {}

class Foo<T extends SomeBaseClass> {
  @override
  String toString() => "Instance of 'Foo<$T>'";
}

class Extender extends SomeBaseClass {}

var someBaseClassFoo = Foo<SomeBaseClass>();
var extenderFoo = Foo<Extender>();

/// ===============================
/// F-ОГРАНИЧЕНИЯ (самореферентные)
/// ===============================
/// Позволяют ссылаться на сам параметр типа.
/// Класс A реализует Comparable<A>, значит сравним только с самим собой.
abstract interface class Comparable<T> {
  int compareTo(T o);
}

class A implements Comparable<A> {
  @override
  int compareTo(A other) => 0;
}

/// Функция принимает только такие типы T,
/// которые реализуют Comparable<T> (т.е. сравнимы сами с собой).
int compareAndOffset<T extends Comparable<T>>(T t1, T t2) =>
    t1.compareTo(t2) + 1;

int useIt = compareAndOffset(A(), A());

/// ===============================
/// МНЕМОНИКА ДЛЯ ИМЁН ПАРАМЕТРОВ
/// ===============================
/// <E> — элемент коллекции
class IterableBase<E> {}

class Lists<E> {}

class HashSet<E> {}

class RedBlackTree<E> {}

/// <K>, <V> — ключ и значение
class Map<K, V> {}

class Multimap<K, V> {}

class MapEntry<K, V> {}

/// <R> — возвращаемый тип
class UnaryExpression {}

class LiteralExpression {}

class BinaryExpression {}

abstract class ExpressionVisitor<R> {
  R visitBinary(BinaryExpression node);
  R visitLiteral(LiteralExpression node);
  R visitUnary(UnaryExpression node);
}

/// <T>, <S>, <U> — универсальные placeholder’ы
class Futures<T> {
  // then<S>() использует новый параметр S,
  // чтобы не затенять T у Future<T>.
  Futures<S> then<S>(FutureOr<S> Function(T value) onValue) => Futures();

  // 42 -> T value
  // FutureOr<S> -> (Future<String> g) то что вернула f.then
  void dd() {
    Future<int> f = Future.value(42);
    Future<String> g = f.then((int value) {
      return "Value is $value"; // возвращаем String
    });

    print(g);
  }
}

/// Можно использовать описательные имена:
class Graph<N, E> {
  Graph(this.edges, this.nodes);
  final List<N> nodes;
  final List<E> edges;
}

class Graphs<Node, Edge> {
  Graphs(this.edges, this.nodes);
  final List<Node> nodes;
  final List<Edge> edges;
}

/// ===============================
/// ВАРИАТИВНОСТЬ ТИПОВ
/// ===============================
/// Dart по умолчанию делает дженерики ИНВАРИАНТНЫМИ.
/// Это значит: List<Dog> ≠ List<Animal>, даже если Dog наследует Animal.
/// Причина: иначе можно было бы записать Animal в список собак.

class Animal {}

class Dog extends Animal {}

void invarianceExample() {
  List<Dog> dogs = [Dog()];
  print(dogs);
  // List<Animal> animals = dogs; // ❌ Ошибка: ИНВАРИАНТНЫМИ
}

/// КОВАРИАНТНОСТЬ — разрешает подтипы в возвращаемых значениях.
/// Пример: функция Dog produce() может использоваться там,
/// где ожидается Animal produce().
typedef Producer<T> = T Function();

Dog produceDog() => Dog();
Animal produceAnimal() => Animal();

void covarianceExample() {
  Producer<Dog> dogProducer = produceDog;
  Producer<Animal> animalProducer = dogProducer; // ✅ ковариантность результата
  print(animalProducer.runtimeType);
}

/// КОНТРАВАРИАНТНОСТЬ — разрешает супертипы в аргументах функций.
/// Пример: если функция принимает Animal, её можно использовать там,
/// где ожидается функция, принимающая Dog.
typedef Consumer<T> = void Function(T);

void consumeAnimal(Animal a) {}
void consumeDog(Dog d) {}

void contravarianceExample() {
  Consumer<Animal> animalConsumer = consumeAnimal;
  Consumer<Dog> dogConsumer = animalConsumer; // ✅ контравариантность аргумента
  print(dogConsumer.runtimeType);
}

/// ===============================
/// СРАВНЕНИЕ ВИДОВ ВАРИАТИВНОСТИ
/// ===============================
/// | Вид                | Пример                           | Отношение типов   | В Dart                    |
/// |--------------------|----------------------------------|-------------------|---------------------------|
/// | Инвариантность     | List<Dog> vs List<Animal>        | Не совместимы     | ✅ по умолчанию           |
/// | Ковариантность     | Producer<Dog> → Producer<Animal> | Подтип разрешён   | ✅ для возвращаемых типов |
/// | Контравариантность | Consumer<Animal> → Consumer<Dog> | Супертип разрешён | ✅ для аргументов функций |

/// ===============================
/// ПРАКТИЧЕСКИЕ СОВЕТЫ
/// ===============================
/// - Используй ограничения (extends) для самодокументируемого API.
/// - Будь осторожен с dynamic — он ломает вывод типов.
/// - Аннотируй пустые коллекции: var xs = <int>[];.
/// - Для F-ограничений — проверяй, что тип сравним сам с собой.
/// - Следи за инвариантностью: не передавай List<Dog> туда,
///   где нужен List<Animal>; используй Iterable<Animal>.
