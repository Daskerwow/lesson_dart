/*
 * Основные понятие классов 
 * Полиморфизм - тесно связан с наследованием классов. 
 * Позволяет менять поведения базового класса в производном
 * 
 * Инкапсуляция - объединения данных и методов работы с ними в одну оболочку (обычно это класс, модуль, пакет)
 * Сокрытия - настройка доступа к инкопсулированным методом и данным
 * используя вместе инкопсуляцию и сокрытие разработчик обеспечивает инвариантность данных
 * 
 * Приведения - Когда производный класс приводится к базавому, при этом теряет чать функционала
 * который реализован в проихводном классе. Но когда методы базавого класса переопределены в производном, 
 * то после приведения в базавому классу и вызове этого метода у базавого класса, буде вызван метод производного.
 * 
 * Интерфейс - Контракт который заключает класс реализующий интерфейс на реализацию всех методов и 
 * полей этого интерфейса.
 * 
 * Миксины - Это классы которые определяют некоторую реализацию (утилиту), которую можно
 * подмешивать к классу и импользовать ее
 * 
 * Перегрузка операторов - позвалят сделать более гибкие классы. Операторы можно только перегружать, 
 * а не переопределятся
 * так как они не пренадлежат к какому либо типу данных
 */

class Cat {
  final String name;
  final int age;
  final String _address;
  final bool _sleepState;

  // Позиционный параметры
  const Cat(
    this.name,
    this.age, [
    this._address = 'Uncnove',
    this._sleepState = false,
  ]);

  /// Геттеры для приватных полей
  String get address => _address;
  bool get sleepState => _sleepState;
}

class CatName {
  final String name;
  final String _address;
  final int age;
  final bool _sleepState;

  // Именованные параметры
  const CatName({
    required this.name,
    required this.age,
    String addres = 'Uncnown',
    this._sleepState = false,
  }) : _address = addres;

  String get address => _address;
  bool get sleepState => _sleepState;
}

class CatNameCostructor {
  final String name;
  final String _address;
  final int age;
  final bool _sleepState;

  const CatNameCostructor({
    required this.name,
    required this.age,
    this._address = 'Uncnown',
    this._sleepState = false,
  });

  /// Именованный конструктор
  const CatNameCostructor.onlyName({required String name, int age = 0})
    : this(name: name, age: age);

  const CatNameCostructor.fromNameAndAdress({
    required String name,
    required int age,
    required String addres,
  }) : this(name: name, age: age, address: addres);

  const CatNameCostructor.gudini(this.name, this.age, String address)
    : _address = address,
      _sleepState = false;

  String get address => _address;
  bool get sleepState => _sleepState;
}

class Rub {
  final int copeek;

  const Rub._(this.copeek);

  /// Фабричный конструктор
  /// Предназначен для дополнительных просчетов при создании объекта
  factory Rub(String rub) {
    String cop = (double.parse(rub) * 100).toStringAsFixed(0);
    return Rub._(int.parse(cop));
  }

  Rub operator +(Rub other) {
    // Любая логика
    return Rub._(copeek + other.copeek);
  }

  @override
  int get hashCode => copeek.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Rub ? copeek == other.copeek * 100 : false;
  }
}

// Callable object сделать объекты вызываемыми как функции
class Callable {
  int call(int a, int b) => a + b;
}

class CallableOne {
  final int a;
  const CallableOne(this.a);

  int call(int b) => a + b;
}

void main() {
  {
    final adder = Callable();
    final constAdder = CallableOne(10);
    print(adder(1, 2));
    print(constAdder(12));
  }
}
