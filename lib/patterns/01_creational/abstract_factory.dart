/// ============================================================================
/// ПАТТЕРН: ABSTRACT FACTORY (Абстрактная фабрика)
/// Категория: Порождающий (Creational) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Предоставляет интерфейс для создания СЕМЕЙСТВ связанных объектов без
/// указания их конкретных классов. В отличие от Factory Method (один
/// продукт), Abstract Factory создаёт целую линейку совместимых продуктов.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Кроссплатформенный UI (виджеты Material vs Cupertino должны сочетаться
///   друг с другом внутри одной темы — нельзя смешивать кнопку Material
///   с чекбоксом Cupertino).
/// - Поддержка нескольких провайдеров БД/облака, где для каждого нужен
///   свой набор совместимых компонентов (Connection, QueryBuilder, Migrator).
library;

// --- Абстрактные продукты семейства "UI Kit" ---
abstract class Button {
  String render();
}

abstract class Checkbox {
  String render();
}

abstract class TextField {
  String render();
}

// --- Семейство продуктов: Material Design ---
class MaterialButton implements Button {
  @override
  String render() => '[MaterialButton: приподнятая, скруглённые углы, тень]';
}

class MaterialCheckbox implements Checkbox {
  @override
  String render() => '[MaterialCheckbox: квадратный, ripple-эффект]';
}

class MaterialTextField implements TextField {
  @override
  String render() => '[MaterialTextField: подчёркнутое поле, floating label]';
}

// --- Семейство продуктов: Cupertino (iOS) ---
class CupertinoButton implements Button {
  @override
  String render() => '[CupertinoButton: плоская, минималистичная]';
}

class CupertinoCheckbox implements Checkbox {
  @override
  String render() => '[CupertinoCheckbox: круглый переключатель iOS-стиля]';
}

class CupertinoTextField implements TextField {
  @override
  String render() =>
      '[CupertinoTextField: рамка со скруглением, без underline]';
}

/// АБСТРАКТНАЯ ФАБРИКА: интерфейс для создания семейства виджетов.
/// Гарантирует, что все виджеты, созданные одной конкретной фабрикой,
/// визуально и логически совместимы друг с другом.
abstract class UiKitFactory {
  Button createButton();
  Checkbox createCheckbox();
  TextField createTextField();
}

class MaterialUiKitFactory implements UiKitFactory {
  @override
  Button createButton() => MaterialButton();

  @override
  Checkbox createCheckbox() => MaterialCheckbox();

  @override
  TextField createTextField() => MaterialTextField();
}

class CupertinoUiKitFactory implements UiKitFactory {
  @override
  Button createButton() => CupertinoButton();

  @override
  Checkbox createCheckbox() => CupertinoCheckbox();

  @override
  TextField createTextField() => CupertinoTextField();
}

/// Клиентский код работает ТОЛЬКО через абстракцию UiKitFactory и
/// абстрактные продукты — он ничего не знает про Material или Cupertino.
/// Это позволяет подменить всю "тему" одной строчкой при инициализации.
class SettingsScreen {
  final UiKitFactory factory;
  const SettingsScreen(this.factory);

  String build() {
    /// Методы вызываются у конкретного типа объекта
    final button = factory.createButton();
    final checkbox = factory.createCheckbox();
    final textField = factory.createTextField();

    ///
    return 'Экран настроек:\n'
        '  ${textField.render()}\n'
        '  ${checkbox.render()}\n'
        '  ${button.render()}';
  }
}

enum Platform { android, ios }

UiKitFactory resolveFactory(Platform platform) {
  switch (platform) {
    case .android:
      return MaterialUiKitFactory();
    case .ios:
      return CupertinoUiKitFactory();
  }
}

/// --- СЕМЕЙСТВО ПРОДУКТОВ А: Соединения с базами данных (Connections) ---
abstract interface class DbConnection {
  void open();
  void close();
}

class PostgresConnection implements DbConnection {
  @override
  void close() => print('PostgreSQL connection closed.');

  @override
  void open() => print('PostgreSQL connection opened.');
}

class MongoConnection implements DbConnection {
  @override
  void close() => print('MongoDB connection closed.');

  @override
  void open() => print('MongoDB connection opened.');
}

/// --- СЕМЕЙСТВО ПРОДУКТОВ Б: Команды/Запросы (Commands) ---
abstract interface class DbCommand {
  void execute(String query);
}

class PostgresCommand implements DbCommand {
  @override
  void execute(String query) =>
      print('Executing PostgreSQL Query: "$query" via native driver.');
}

class MongoCommand implements DbCommand {
  @override
  void execute(String query) =>
      print('Executing MongoDB Command MQL: "{runCommand: $query}"');
}

/// --- АБСТРАКТНАЯ ФАБРИКА ---
/// Декларирует методы для создания всех доступных абстрактных продуктов.
abstract interface class DatabaseToolkitFactory {
  DbConnection createConnection();
  DbCommand createCommond();
}

/// --- КОНКРЕТНЫЕ ФАБРИКИ ---
/// Реализует создание семейства продуктов для реляционной СУБД PostgreSQL.
class PostgresToolkitFactory implements DatabaseToolkitFactory {
  @override
  DbCommand createCommond() => PostgresCommand();

  @override
  DbConnection createConnection() => PostgresConnection();
}

class MongoToolkitFactory implements DatabaseToolkitFactory {
  @override
  DbCommand createCommond() => MongoCommand();

  @override
  DbConnection createConnection() => MongoConnection();
}

/// --- КЛИЕНТСКИЙ КОД ---
class DatabaseManager {
  const DatabaseManager({required this._toolkit});
  final DatabaseToolkitFactory _toolkit;

  void runBusinessTransaction(String queryOrCommand) {
    final connection = _toolkit.createConnection();
    final command = _toolkit.createCommond();

    connection.open();
    command.execute(queryOrCommand);
    connection.close();
  }
}

void main() {
  // Работаем с SQL стеком
  print('--- Настройка инфраструктуры на PostgreSQL ---');
  final postgresManager = DatabaseManager(toolkit: PostgresToolkitFactory());
  postgresManager.runBusinessTransaction(
    'SELECT * FROM users WHERE active = true',
  );

  print('\n--- Настройка инфраструктуры на MongoDB ---');
  // Переключение на NoSQL стек требует замены всего лишь одной фабрики на входе
  final mongoManager = DatabaseManager(toolkit: MongoToolkitFactory());
  mongoManager.runBusinessTransaction('find({active: true})');

  // Приложение определяет платформу один раз при старте и дальше
  // весь UI собирается из единого, гарантированно совместимого семейства.
  final androidScreen = SettingsScreen(resolveFactory(.android));
  print(androidScreen.build());

  print('---');

  final iosScreen = SettingsScreen(resolveFactory(.ios));
  print(iosScreen.build());
}
