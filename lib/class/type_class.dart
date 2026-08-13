/*
 * В Dart sealed class — это класс с закрытой иерархией наследования: 
 * его можно расширять только внутри того же файла/библиотеки, что 
 * гарантирует исчерпывающую обработку всех подклассов. 
 * Помимо sealed, в Dart есть несколько модификаторов для классов: abstract, 
 * base, final, interface, mixin. Каждый из них задаёт правила наследования 
 * и использования.
 * 
 * sealed — это модификатор, который гарантирует, что класс может быть 
 * расширен только внутри того же файла/библиотеки. Tоже абстрактный по сути, 
 * но наследовать можно только внутри файла, что делает иерархию закрытой
 * 
 * base — это модификатор, который гарантирует, что класс наследуется только 
 * от базового класса. для библиотек, где нужно контролировать наследование, 
 * но не запрещать его полностью.
 * 
 * final — это модификатор, который гарантирует, 
 * что класс не может быть расширен. (нельзя наследоваться)
 * Полезно для immutable типов, которые не должны иметь наследников.
 * 
 * interface — для API‑контрактов, когда важна реализация, а не наследование.
 * 
 * abstract — просто нельзя создать экземпляр, но наследовать
 * можно где угодно. Для контрактов и базовых классов, которые будут 
 * расширяться в разных местах.
 */

/// abstract
/// Класс нельзя инстанцировать напрямую.
/// Используется как контракт или базовый класс.
abstract class Shape {
  void draw(); // абстрактный метод
}

class Circle extends Shape {
  @override
  void draw() => print("Рисуем круг");
}

class Squad implements Shape {
  ///
  @override
  void draw() {
    // TODO: implement draw
  }
}

/// base
/// Класс можно наследовать, но нельзя реализовывать как интерфейс.
/// Это гарантирует, что наследники используют его как основу, а не просто
/// копируют контракт.
base class BaseLogger {
  void log(String msg) => print("LOG: $msg");
}

/// Когда класс помечен как base, это означает:
/// Его можно наследовать, но нельзя реализовывать как интерфейс.
/// Все наследники тоже должны быть помечены как base, final или sealed.
base class FileLogger extends BaseLogger {
  @override
  void log(String msg) => print("FILE: $msg");
}

/// final
/// Класс нельзя наследовать. Полезно для immutable типов или когда
/// нужно запретить расширение.
final class Config {
  final String apiKey;
  const Config(this.apiKey);
}

/// interface
/// Класс можно реализовывать как интерфейс, но нельзя наследовать.
/// Это удобно для API‑контрактов.
interface class Printable {
  const Printable(this.name);
  final String name;

  void printData() {
    // TODO: implement printData
  }
}

class Prizma extends Printable {
  Prizma() : super('');

  /// Если мы не реализуем метод void printData()
  /// то класс Prizma будет Абстрактным и нельзя будет создать его экземпляр
}

/// Хдесь мы реализуем интерфейс
/// тем самым нам обязательно нужно реализовать все методы и свойства интерфейса
class Report implements Printable {
  const Report(this.name);

  @override
  final String name;

  @override
  void printData() => print("Отчёт готов");
}

/// sealed
/// Класс можно наследовать только внутри того же файла.
/// Создаёт закрытую иерархию — удобно для state machine.
sealed class Result {}

class Success extends Result {
  final String data;
  Success(this.data);
}

class Failure extends Result {
  final String message;
  Failure(this.message);
}

void handle(Result r) {
  switch (r) {
    case Success(:final data):
      print("Успех: $data");
    case Failure(:final message):
      print("Ошибка: $message");
  }
}

/// mixin
/// Определяет набор методов/полей, которые можно "примешивать" к другим классам.
mixin Logger {
  String get dim;
  void log(String msg) => print("LOG: $msg -> $dim");
}

class Service with Logger {
  @override
  String dim = 'dody';

  void run() {
    /// Позволяет вызывать метод mixin класса как собственный
    log("Сервис запущен");
  }
}

mixin class Dory {
  String get dim => 'dim';

  void log(String msg) => print("LOG: $msg -> $dim");
}

void main() {
  // final s = Shape(); ❌ Ошибка: нельзя создать экземпляр
  final c = Circle();
  c.draw(); // "Рисуем круг"

  final logger = FileLogger();
  logger.log("Hello");

  final f = Config("12345");
  print(f.apiKey);

  // class ExtendedConfig extends Config {} ❌ Ошибка: нельзя наследовать

  final r = Report('Bore');
  r.printData(); // "Отчёт готов"

  handle(Success("Данные получены"));
  handle(Failure("Сетевая ошибка"));

  final s = Service();
  s.run(); // "LOG: Сервис запущен"
}
