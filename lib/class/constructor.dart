class A {
  // неявный конструктор A();
}

// Неименованный (unnamed) — обычный конструктор класса.
class B {
  final int x;
  const B(this.x); // неименованный
}

// Именованный (named) — дополнительный  конструктор с именем.
class C {
  final int x;
  const C(this.x);

  /// Именованный конструктор (не фабричный)
  /// x = 0; называется списком инициализации
  const C.zero() : x = 0; // именованный -> создаст объект C() с полем x = 0
}

/*
 * const‑конструктор — делает экземпляры константными; 
 * все поля должны быть final и все выражения в инициализаторах — константы.
 */
class Point {
  final int x, y;
  const Point(this.x, this.y);
}

const p = Point(1, 2);

// Список инициализации (initializer list) — позволяет инициализировать
// final поля до тела конструктора.
class D {
  final int sum;

  /// Список иинициализации может иметь сколько угодно переменных через дапятую ,
  const D(int a, int b) : sum = a + b;
}

// assert в списке инициализации — проверка инвариантов в рантайме во время разработки.
class E {
  final int v;
  const E(this.v) : assert(v >= 0);
}

/*
 * Redirecting (перенаправляющий)
 * конструктор вызывает другой конструктора этого же класса. 
 */
class F {
  final int x;
  const F(this.x);

  /// Именованный конструктор переадресовывает на главный конструктор
  const F.defaultValue() : this(42); // перенаправление
}

// Private (приватный) конструктор — имя начинается с нижнего подчёркивания,
// доступен только в библиотеке.
class G {
  G._(); // приватный по сути он именованный просто имя начинается с _
}

/*
 * factory — не обязательно создаёт новый экземпляр; может вернуть кэш, 
 * подтип или null (если nullable возвращаемый тип). 
 * Позволяет реализовать паттерны singleton, flyweight, фабрика для подтипов и др. 
 */

class H {
  final int x;
  const H._(this.x); // приватный (именованный)

  static final Map<int, H> _cache = {};

  factory H(int x) {
    return _cache.putIfAbsent(x, () => H._(x)); // кэшированный экземпляр
  }
}

/*
 * Redirecting factory — factory, перенаправляющий на другой конструктор 
 * (может быть генеративным или factory), в том числе у подтипа. 
 */

class I {
  final int x;
  I(this.x);
  // redirecting factory к приватному конструктору/классу
  factory I.zero() = I._zero;

  I._zero() : x = 0;
}

/*
 * Factory как фабрика подтипов — возвращает экземпляр подтипа
 * (полезно для абстрактных фабрик).
 */

abstract class Shape {
  factory Shape(String kind) {
    if (kind == 'circle') return Circle();
    return Square();
  }
}

class Circle implements Shape {}

class Square implements Shape {}

class Force {
  final String b;

  Force._(this.b) {
    print('object -> $b');
  }

  Force() : this._('10');
}

/*
 * Параметры конструктора: позиционные, именованные, обязательные, по умолчанию
 */

// Позиционные обязательные (positional required)
class J {
  J(int a, String b); // оба обязательны
}

// Опциональные позиционные (optional positional) — обёрнуты в
// квадратные скобки, могут иметь значения по умолчанию.
class K {
  int a;
  int b;
  K(this.a, [this.b = 0]);
}

// Именованные параметры (named) — в фигурных скобках;
// предпочтительны для читабельности.
class L {
  int a;
  int b;
  L({required this.a, this.b = 0});
}

// required (для именованных) — помечает именованный параметр как обязательный
// (компиляторная проверка).
class M {
  const M({required this.a});
  final int a;
}

// forwarding (constructor tear-offs / forwarding constructors) — именованные
// параметры и positional могут быть проброшены в другой конструктор внутри класса
// (синтаксис -> this(...))
class N {
  final int a;
  final int b;
  N(this.a, this.b);
  N.fromA(int a) : this(a, 0); // forwarding через redirecting
}

// Конструкторы с перенаправлением на другой класс (redirecting to subtypes)
/*
 * factory-конструктор может вернуть экземпляр другого класса 
 * (подтипа или реализации интерфейса) — реализация паттерна фабрики/абстрактной 
 * фабрики (см. пример Shape выше).
 */

abstract class Transport {
  void move();

  // redirecting factory: синтаксис `=` перенаправляет на конкретный конструктор подтипа
  // model сама поподает в Car.create(model)
  factory Transport.car(String model) = Car.create;
  factory Transport.bike() = Bike;
}

class Car implements Transport {
  final String model;
  const Car.create(this.model);

  @override
  void move() => print('Driving $model');
}

class Bike implements Transport {
  const Bike();

  @override
  void move() => print('Riding bike');
}

void main() {
  Transport t1 = Transport.car('Tesla');
  t1.move(); // Driving Tesla

  Transport t2 = Transport.bike();
  t2.move(); // Riding bike
}

// Конструкторы для наследования и super‑инициализация
// Вызов конструктора суперкласса в списке инициализации через super(...).
class Base {
  final int x;
  Base(this.x);
}

class Child extends Base {
  final int y;
  Child(super.x, this.y); // :super(x)
}

// const-конструктор в подклассе может делегировать в const‑super (если super-конструктор const).
class AConst {
  final int v;
  const AConst(this.v);
}

class BConst extends AConst {
  const BConst(super.v);
}

// Паттерны и специальные случаи
// Singleton через private + factory:
class Singleton {
  Singleton._internal();
  static final Singleton _instance = Singleton._internal();
  factory Singleton() => _instance;
}

// Immutable value с константами (const) и factory при необходимости валидации:
class Email {
  final String value;
  const Email._(this.value);

  factory Email(String v) {
    if (!v.contains('@')) throw FormatException('Invalid email');
    return Email._(v);
  }
}

// Конструктор, возвращающий null (factory с nullable типом) — полезно при валидации:
class Maybe {
  final int v;
  Maybe._(this.v);
  factory Maybe.tryParse(String s) {
    final n = int.tryParse(s);
    return n == null ? throw FormatException() : Maybe._(n);
  }
}

// primaryConstructor
// LongClassName() {}                          new() {}
// LongClassName.name() {}                     new name() {}
// const LongClassName();                      const new();
// const LongClassName.name();                 const new name();
// LongClassName(): this.other();              new(): this.other();
// LongClassName.name(): this();               new name(): this();
// const LongClassName(): this.other();        const new(): this.other();
// const LongClassName.name(): this();         const new name(): this();
// factory LongClassName() { ... }             factory() { ... }
// factory LongClassName.name() { ... }        factory name() { ... }
// factory LongClassName() = D;                factory() = D;
// factory LongClassName.name() = D;           factory name() = D;
// const factory LongClassName() = D;          const factory() = D;
// const factory LongClassName.name() = D;     const factory name() = D;

// самый простой синтаксис (var или final обязательны иначе поле не создается)
// с пустым телом
class Pointer(var int x, var int y);

/// Инициализаторы
class ScopingDemo(var String x, String suffix) {
  // В инициализаторе поля, не являющемся поздним, 'x' обозначает параметр 'x'.
  final String fieldAtDeclaration = x;
  final String fieldInInitializer;
  final String fieldInInitializerTwo;

  // В списке инициализаторов 'x' обозначает параметр 'x'.
  this : fieldInInitializer = x, fieldInInitializerTwo = x {
    // (после this : В этой области имя параметра, такое как x, относится непосредственно к параметру конструктора.)

    // Внутри тела функции 'x' обозначает переменную поле класса (this.x = this.x.toUpperCase()),
    // поэтому присваивание ей значения обновляет поле.
    x = x.toUpperCase();

    // Параметр 'suffix' не создает никакого поля, поэтому он по-прежнему ссылается на параметр.
    print('$x$suffix');
  }
}

/// Тело конструктора
class PointTwo(var int x, var int y) {
  // Тело
  this : assert(x >= 0 && y >= 0) {
    print('PointTwo inicialized at ($x, $y)');
  }
}

class UserTwo({required var String _name});

/// Константный конструктор все поля обязатьельно final!
class const User(final String name, final int age) {
  /// Здесь обычное тело класса, где мы как обычно объявляем методы
  /// и любые другие конструктора

  // User. можно опустить
  factory fromJson(Map<String, Object?> json) =>
      User(json['name'] as String, json['age'] as int);

  Map<String, Object?> toJson() => {'name': name, 'age': age};

  User copyWith({String? name, int? age}) =>
      User(name ?? this.name, age ?? this.age);
}

class const ConstPoint(final int x, final int y) {
  final int z;

  /// Нет блока тела: Наличие тела { ... } является ошибкой во время компиляции, даже если оно пусто.
  /// Постоянный первичный конструктор может использовать только список инициализаторов,
  /// за которым следует точка с запятой.
  this : z = x + y;
}

/// Именованные первичный конструктор
class PointNamed.custom(var int x, [var int? y]);

/// Приватный
class PointPrivate._(var int x);

/// Наследование
class const Personer(final String name, final int age);
class const Employee(super.name, super.age, final String role) extends Personer;

// Первичный конструктор в Enum
enum Colors({required final String hex}) {
  red(hex: '#FF0000'),
  green(hex: '#00FF00'),
  blue(hex: '#0000FF');
}

/// Ограничения при использовании первичного конструктора
// - Объявление параметров не может быть поздним или внешним: поздние и внешние модификаторы не допускаются
// по параметрам в заголовке основного конструктора. Чтобы использовать эти модификаторы, объявите поля в теле класса, как обычно.
// - Столкновение имен: Объявление параметра в основном конструкторе
// с тем же именем, что и метод или другое поле в теле класса приводит к ошибке во время компиляции.
// - Нет назначений основным параметрам конструктора: Основные параметры конструктора доступны только для чтения в
// области первичной инициализации. Назначение им (например, с x = 5 или x++) в инициализаторе поля или
// списке инициализаторов основного конструктора является ошибкой во время компиляции.
// - Двойная инициализация: Вы не можете инициализировать переменную экземпляра как в ее объявлении, так и в
// списке инициализаторов основного конструктора (или в качестве формального параметра инициализации), даже если поле изменчиво
// - Ограничения тела первичтного конструктора
//   - Основная часть тела конструктора (этот блок) не может использовать модификаторы async, async* или sync*,
//     и она не может использовать синтаксис выражения arrow (=>).
//   - Вы не можете написать this блок, если заголовок класса не объявляет первичный конструктор.
//   - Класс может иметь не более одной основной части тела конструктора.
// - Первичные конструкторы класса Mixin должны быть тривиальными: класс mixin может объявить первичный
// конструктор только в том случае, если он не имеет параметров, списка инициализаторов и тела.
//
// factory случай по краю метода: Если у вас есть метод с именем factory без возвращаемого типа (например, factory() {}),
// компилятор разбирует его как заводской конструктор после отправки первичных конструкторов.
// Убедитесь, что такие методы имеют явные типы возврата, чтобы избежать этого конфликта.

/**
 * Генеративные: неименованные, именованные, const, redirecting, private, 
 * с initializer list и assert.
 * Factory: factory обычный (кэш/фабрика), redirecting factory, 
 * factory возвращающий подтип, factory возвращающий nullable.
 * первичный
 * Параметры: позиционные обязательные, опциональные позиционные, 
 * именованные (с required/по умолчанию).
 * Наследование: super(...) в initializer list; const-super; forwarding/redirecting.
 * Шаблоны: singleton, value object с валидацией, кэширование, фабрика подтипов.
 * 
 */
