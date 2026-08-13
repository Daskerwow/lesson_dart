/*
 * Базовые типы и null‑safety
 * 
 * Всегда предпочитайте конкретный тип вместо dynamic или Object.
 * Используйте nullable типы явно через ?; 
 * если значение не должно быть null — не ставьте ?.
 * Для полей, которые инициализируются позже, 
 * используйте late или конструкторные обязательные параметры.
 */

// не-nullable
String name = 'Alex';

// nullable
String? middleName;

// late если инициализируется позже, но гарантированно до использования
// и точно не будет null
late final String token;

// обязательный именованный параметр в конструкторе (null-safety)
class Person {
  final String firstName; // не обязательно объявлять ка late
  Person({required this.firstName});
}

/* ****************************************************************************
 * Классы, неизменяемость и value objects
 * 
 * Делаем модели immutable через final поля и const/const constructors когда возможно.
 * Реализуем copyWith для удобных изменений.
 * Переопределяем == и hashCode (либо используем пакеты, но здесь примеры вручную).
 */

class Prisoner {
  final int id;
  final String regNumber;
  final String lastName;
  final String firstName;
  final String? middleName;
  final DateTime birthDate;
  final String? citizenship;

  const Prisoner({
    required this.id,
    required this.regNumber,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.birthDate,
    this.citizenship,
  });

  // все необязательные поля
  Prisoner copyWith({
    int? id,
    String? regNumber,
    String? lastName,
    String? firstName,
    String? middleName,
    DateTime? birthDate,
    String? citizenship,
  }) {
    return Prisoner(
      id: id ?? this.id,
      regNumber: regNumber ?? this.regNumber,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      birthDate: birthDate ?? this.birthDate,
      citizenship: citizenship ?? this.citizenship,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'regNumber': regNumber,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'birthDate': birthDate.toIso8601String(),
    'citizenship': citizenship,
  };

  // Не самый лучший пример но сойдет
  factory Prisoner.fromJson(Map<String, dynamic> m) => Prisoner(
    id: m['id'] as int,
    regNumber: m['regNumber'] as String,
    lastName: m['lastName'] as String,
    firstName: m['firstName'] as String,
    middleName: m['middleName'] as String?,
    birthDate: DateTime.parse(m['birthDate'] as String),
    citizenship: m['citizenship'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prisoner && other.id == id && other.regNumber == regNumber;

  @override
  int get hashCode => Object.hash(id, regNumber);
}

/* ****************************************************************************
 * Generics и ограничение типов
 * 
 * Обобщения позволяют писать безопасный переиспользуемый код.
 * Ограничивайте generics через extends, 
 * используйте Comparable для сравнимых сущностей.
 * В Dart generic-параметры инвариантны по умолчанию; для параметров конструктора/метода 
 * можно использовать ключевое слово covariant при переопределении (см. раздел про variance).
 */

// простой generic контейнер
class Box<T> {
  final T value;
  Box(this.value);
}

// bounded generic (ограничения Generic типа)
// он должен быть подтипом num
T max<T extends num>(T a, T b) => (a > b) ? a : b;

// Comparable bound
T maxComparable<T extends Comparable<T>>(T a, T b) =>
    a.compareTo(b) >= 0 ? a : b;

/* ****************************************************************************
 * Наследование, интерфейсы, mixin и variance
 * 
 * Используйте наследование для явного «is‑a». 
 * Для повторного поведения предпочитайте mixin и композицию.
 * В Dart интерфейс — любой класс; 
 * реализуйте интерфейс через implements.
 * mixin — простой способ добавлять поведение.
 * covariance: Dart не поддерживает declaration‑site variance; 
 * при переопределении метода можно пометить параметр как covariant, 
 * чтобы принимать более конкретный тип, но это снимает проверки и может 
 * привести к runtime‑ошибкам, поэтому применяйте осознанно.
 */

// интерфейс
abstract class Repository<T, ID> {
  Future<T?> findById(ID id);
  Future<T> save(T entity);
}

// реализация
class InMemoryRepo<T, ID> implements Repository<T, ID> {
  final Map<ID, T> _store = {};

  @override
  Future<T?> findById(ID id) async => _store[id];

  @override
  Future<T> save(T entity) async {
    // потребуются механизмы получения ID от entity
    throw UnimplementedError();
  }
}

// mixin для логирования
mixin Logger {
  void log(String msg) => print('[LOG] $msg');
}

class Service with Logger {
  // можем вызывать методы класса Logger
  void doWork() => log('work');
}

// covariant пример (использовать аккуратно)
class Animal {}

class Dog extends Animal {}

class Base {
  void feed(Animal a) {}
}

class Derived extends Base {
  // принимаем конкретный подкласс; проверяйте на runtime
  @override
  void feed(covariant Dog a) {
    // мы установили более конкретный тип Dog
  }
}

/* 
 * Безопасные альтернативы: для covariant
 * Использовать generics с ограничениями
 */

// Указываем что Generic T должен наследоваться от Animal
abstract class Feeder<T extends Animal> {
  void feed(T a);
}

class DogFeeder implements Feeder<Dog> {
  @override
  void feed(Dog d) {}
}

/* ****************************************************************************
 * Функции, typedef, асинхронность и потоки
 * 
 * Явно указывайте тип возвращаемого значения Future/Stream.
 * Для callback‑типов используйте typedef с generics.
 * Для опциональных параметров предпочтительны именованные параметры с required/добавлением значений по умолчанию.
 */

// typedef для callback
typedef Predicate<T> = bool Function(T item);

// async
Future<Prisoner?> fetchPrisoner(int id) async {
  // ...
  return null;
}

// stream
Stream<Prisoner> prisonerUpdates() async* {
  // yield updates
}

// named params и defaults
String greet(String name, {String title = 'Mr'}) => 'Hello, $title $name';

/* ****************************************************************************
 * Типизация изменений и история состояний
 * 
 * Для версионности/истории используйте immutable snapshots с timestamp и 
 * generic‑репозитории для работы с историей.
 * Храните версии как неизменяемые снимки (snapshots) с метаданой effectiveFrom/effectiveTo.
 * Используйте generic Snapshot<T> для любых доменных объектов.
 */

// Снимки
class Snapshot<T> {
  final T value;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo; // может небыть (следующий снимок еще не сделан)
  final String recordedBy;

  const Snapshot({
    required this.value,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.recordedBy,
  });

  bool get isCurrent =>
      effectiveTo == null || effectiveTo!.isAfter(DateTime.now());
}

/*
 * Что означает «инвариантны» (в терминах типовой системы)
 * Инвариантность означает, что для параметризованного типа Container<T> 
 * нельзя свободно подставлять Container<Sub> туда, 
 * где ожидается Container<Super>, даже если Sub является подтипом Super. 
 * То есть при инвариантности нет отношения 
 * подтип‑/супертип между контейнерами — они считаются несовместимыми, 
 * если их параметры типов различны.
 */
class Animals {}

class Dogs extends Animals {}

List<Dogs> dogs = [Dogs()];
// Ошибка компиляции: List<Dog> не является List<Animal>
List<Animals> animals = dogs;

// Функции — контравариантность аргументов и ковариантность результата

/*
 * Для параметров функций действует контравариантность: 
 * функция, принимающая более общий тип, может заменить функцию, ожидающую более конкретный тип.
 * 
 * Для результата функции действует ковариантность: 
 * функция, возвращающая более конкретный тип, может заменить функцию, возвращающую более общий тип.
 */

typedef ConsumerAnimal = void Function(Animal);
typedef ConsumerDog = void Function(Dog);

void acceptAnimal(Animal a) {}
void acceptDog(Dog d) {}

ConsumerAnimal ca = acceptAnimal; // ок
//  — acceptDog не умеет принимать всех Animal
//ConsumerAnimal cb = acceptDog; // НЕ ок

/* **************************************************************************/
// Ковариантность (covariant)

/*
 * Определение: если S является подтипом T, то Container<S> также является подтипом Container<T>.
 * Семантика: безопасна для операций только чтения (producer).
 * В Dart: нет declaration‑site covariance по умолчанию; 
 * некоторые типы/контракты могут фактически использоваться ковариантно при чтении.
 */

// Представьте интерфейс Producer<T> { T produce(); }
// Тогда Producer<Dog> можно безопасно использовать там, где ожидается Producer<Animal>.

/* **************************************************************************/
// Контравариантность (contravariant)

/*
 * Определение: если S <: T, то Container<T> <: Container<S>.
 * Семантика: безопасна для операций только записи (consumer).
 * В Dart: контравариантность встречается в типах функций по аргументам; 
 * тип функции, принимающий более общий параметр, может заменить ожидающую более конкретный. 
 */

typedef Consumer<T> = void Function(T);
// Consumer<Animal> может выступать вместо Consumer<Dog> — потому что он принимает более общий тип.

/* **************************************************************************/
// Инвариантность (invariant)

/*
 * Определение: Container<S> не является ни подтипом, ни суперклассом Container<T>, если S != T.
 * Семантика: безопасная, но строгая — большинство обобщённых типов в реальных языках инвариантны.
 * В Dart: generic‑типы (List<T>, Map<K,V>, большинство пользовательских generic) по умолчанию инвариантны.
 */

List<Dog> dogser = [Dog()];
//List<Animal> animals = dogs; // Ошибка — List<Dog> не подтип List<Animal>

/* **************************************************************************/
// Бивариантность (bivariant)

/*
 * Определение: Container<S> и Container<T> считаются совместимыми как в направлении S->T, так и T->S.
 * Семантика: приводит к потере безопасности типов; встречается в слабых/динамических системах или при специальных допущениях. 
 * В Dart: бивариантность официально не модель, но в legacy/динамическом коде или при unsafe cast она может проявляться.
 */
