/*
================================================================================
ФАЙЛ: enums_and_state_machine.dart
ТЕМА: Расширенное использование enum в Dart + state machine с sealed классами
================================================================================

ОБЩИЙ КОНТЕКСТ:
- Начиная с современных версий Dart, enum — это полноценные типы:
  можно объявлять поля, конструкторы (const), методы, реализовывать интерфейсы,
  расширять функциональность через extensions и использовать свойства .name/.index/.values/.byName.
- Enum хороши как "ограниченный набор вариантов" (tagged values), когда нужные
  экземпляры известны заранее и неизменяемы.
- Для состояний, несущих данные (например, результат загрузки, ошибка с текстом),
  лучше применять sealed классы: они расширяемы, типобезопасны и выразительны в UI.

АРХИТЕКТУРНЫЕ ПРИНЦИПЫ:
- Enum используется как "ярлык состояния" (state tag) или типизированная конфигурация.
- Sealed классы описывают варианты с данными; базовый тип обязателен для переменных,
  чтобы не ловить ошибки присвоения несовместимых подклассов.
- Идиоматично избегать лишних кастов в UI: для этого можно использовать pattern matching
  (switch по типам объектов) или методы-помощники.

ТЕСТИРУЕМОСТЬ И ПОДДЕРЖИВАЕМОСТЬ:
- Enum и sealed классы легко покрываются unit-тестами.
- Статическая исчерпывающая обработка switch защищает от пропуска новых вариантов при расширении.

* У каждого enum‑значения есть:
  -index
  -name
  -toString()
  -values
  -byName

================================================================================
РАЗДЕЛ 1: БАЗОВЫЕ ВОЗМОЖНОСТИ ENUM
================================================================================
*/
// Простейший enum — пригодится для демонстрации .values, .byName и .name.
enum Color { red, green, blue }

// Enum как ключи конфигураций (например, уровни логирования).
// Важно: Map с enum-ключами — читабельно и безопасно.
enum LogLevel { debug, info, warning, error }

final logMessages = <LogLevel, String>{
  .debug: "Отладка",
  .info: "Информация",
  .warning: "Предупреждение",
  .error: "Ошибка",
};

// Пример enum с дополнительными данными (final поле) и конструктором const.
// Подходит для моделирования фиксированных ролей, где у каждой роли есть уровень доступа.
// Идиоматично держать поля неизменяемыми (final).
enum UserRole {
  admin(level: 3),
  moderator(level: 2),
  user(level: 1);

  // Дополнительные данные, связанные с вариантом enum.
  final int level;

  // Enum-конструкторы должны быть const. Параметры — именованные для читабельности.
  const UserRole({required this.level});

  // Методы в enum позволяют инкапсулировать логику, связанную с вариантом.
  bool canDeleteContent() => level >= 2;
}

// Enum как конфигурационный тип: храним число колёс, и имеем метод для логики.
// Такие enum удобны для UI/логики: один тип — всё рядом.
enum VehicleType {
  car(4),
  bike(2),
  truck(6);

  // Поле со значением для каждого варианта.
  final int wheels;

  // Позиционный const-конструктор — аккуратнее при небольшом числе полей.
  const VehicleType(this.wheels);

  // Локальная бизнес-логика, читаемая и короткая.
  bool isHeavy() => wheels > 4;
}

// Enum с геттером + switch по this.
// Важно: switch по enum — исчерпывающий, если нет default, компилятор потребует обработать все варианты.
// Это повышает устойчивость к ошибкам при добавлении новых вариантов.
enum PaymentStatus {
  pending,
  completed,
  failed;

  // Геттер возвращает описания для UI.
  String get description {
    switch (this) {
      case .pending:
        return "Ожидает оплаты";
      case .completed:
        return "Оплата прошла успешно";
      case .failed:
        return "Ошибка оплаты";
    }
  }
}

enum OrderStatus {
  /// Перечисляем поля как и в обычном enum через запятую
  /// но сейчас каждое поле это как именованный конструктор класса
  /// который создает как бы для каждого поля экземпляр класса
  /// тем самым ты получешь дополнительное свойства в дополнение к стандартным:
  ///  -name
  ///  -index
  ///  -code -> наше поле
  ///  -label -> наше поле
  ///  -colorHex -> наше поле
  ///  -isFinal -> наше поле
  ///
  pending(code: 0, label: 'В ожидании', colorHex: 0xFF9E9E9E, isFinal: false),
  processing(
    code: 1,
    label: 'В обработке',
    colorHex: 0xFF2196F3,
    isFinal: false,
  ),
  shipped(code: 2, label: 'Отгружен', colorHex: 0xFF673AB7, isFinal: false),
  delivered(code: 3, label: 'Доставлен', colorHex: 0xFF4CAF50, isFinal: true),
  cancelled(code: 4, label: 'Отменён', colorHex: 0xFFF44336, isFinal: true);

  /// "Технический" код — удобно хранить в БД / API
  final int code;

  /// Человеческий заголовок для UI
  final String label;

  /// Цвет для отображения (ARGB)
  final int colorHex;

  /// Является ли это финальным состоянием
  final bool isFinal;

  const OrderStatus({
    required this.code,
    required this.label,
    required this.colorHex,
    required this.isFinal,
  });

  // ------------------------
  // Методы enum
  // ------------------------

  /// Преобразование в JSON (например, в числовой код)
  int toJson() => code;

  /// Бросает, если код неизвестен
  static OrderStatus fromJson(int code) {
    return OrderStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () {
        throw ArgumentError('Unknown OrderStatus code: $code');
      },
    );
  }

  /// Можно ли ещё отменить заказ
  bool get canBeCancelled => switch (this) {
    OrderStatus.pending || OrderStatus.processing => true,
    // имеет значение по умолчанию, поэтому не требует исчерпываемости
    _ => false,
  };

  /// Короткое текстовое представление для логов
  String get short => '$name($code)'; // name — стандартное свойство Enum

  /// "Красивый" текст для UI (если label не хватает)
  String toDisplayString({bool withCode = false}) {
    if (!withCode) return label;
    return '$label (#$code)';
  }

  /// Пример "приоритета" статуса для сортировки, отличного от index
  int get sortPriority => switch (this) {
    .pending => 10,
    .processing => 20,
    .shipped => 30,
    .delivered => 40,
    .cancelled => 50,
  };

  /// Сравнение статусов по sortPriority
  static int compareByPriority(OrderStatus a, OrderStatus b) =>
      a.sortPriority.compareTo(b.sortPriority);
}

/*
================================================================================
РАЗДЕЛ 2: ENUM + ИНТЕРФЕЙСЫ И EXTENSIONS
================================================================================
*/

// Интерфейс для описания контракта (полезно для единообразия в UI или отчётах).
abstract interface class Describable {
  String describe();
}

// Enum реализует интерфейс — хороший способ обеспечить общий API на уровне типа.
enum ColorType implements Describable {
  red,
  green,
  blue;

  @override
  String describe() => "Цвет: $name"; // $name — встроённое свойство enum.
}

// Интерфейс для действий (например, отрисовка). Enum может содержать логику.
abstract class Drawable {
  void draw();
}

// Enum реализует Drawable; вся логика "под типом", без внешних if/else.
// Это улучшает локальность изменений — при добавлении нового варианта достаточно
// расширить switch.
enum Shape implements Drawable {
  circle,
  square,
  triangle;

  @override
  void draw() {
    switch (this) {
      case .circle:
        print("Рисуем круг");
      case .square:
        print("Рисуем квадрат");
      case .triangle:
        print("Рисуем треугольник");
    }
  }
}

// Enum + extension — аккуратный способ добавить функциональность, не модифицируя исходный тип.
// Extension удобно использовать для сериализации, маппинга и утилит.
enum FileType { pdf, doc, jpg }

extension FileTypeExt on FileType {
  String get mime {
    switch (this) {
      case FileType.pdf:
        return "application/pdf";
      case FileType.doc:
        return "application/msword";
      case FileType.jpg:
        return "image/jpeg";
    }
  }
}

/// С расширениями
enum SaymentStatus {
  pending(code: 0, isFinal: false, canRetry: true),
  processing(code: 1, isFinal: false, canRetry: false),
  success(code: 2, isFinal: true, canRetry: false),
  failed(code: 3, isFinal: true, canRetry: true),
  cancelled(code: 4, isFinal: true, canRetry: false);

  final int code;
  final bool isFinal;
  final bool canRetry;

  const SaymentStatus({
    required this.code,
    required this.isFinal,
    required this.canRetry,
  });

  /// JSON сериализация
  int toJson() => code;

  /// Безопасный парсер
  static SaymentStatus? tryParse(int? code) {
    if (code == null) return null;
    for (final s in SaymentStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }

  /// Жёсткий парсер (кидает ошибку)
  static SaymentStatus fromJson(int code) {
    return tryParse(code) ??
        (throw ArgumentError('Unknown SaymentStatus code: $code'));
  }
}

extension SaymentStatusX on SaymentStatus {
  /// Человекочитаемое имя
  String get label => switch (this) {
    .pending => 'Ожидает оплаты',
    .processing => 'Обрабатывается',
    .success => 'Оплачено',
    .failed => 'Ошибка оплаты',
    .cancelled => 'Отменено',
  };

  /// Цвет для UI
  /*Color get color => switch (this) {
    .pending => const Color(0xFF9E9E9E),
    .processing => const Color(0xFF2196F3),
    .success => const Color(0xFF4CAF50),
    .failed => const Color(0xFFF44336),
    .cancelled => const Color(0xFF795548),
  };*/

  /// Приоритет сортировки
  int get priority => switch (this) {
    .pending => 10,
    .processing => 20,
    .success => 30,
    .failed => 40,
    .cancelled => 50,
  };

  /// Можно ли отменить
  bool get canCancel => switch (this) {
    SaymentStatus.pending || SaymentStatus.processing => true,
    _ => false,
  };

  /// Короткая строка
  String get short => '$name($code)';
}

/*
================================================================================
РАЗДЕЛ 3: СЕРИАЛИЗАЦИЯ И ИСПОЛЬЗОВАНИЕ .index/.values/.byName
================================================================================
*/

// Enum с приоритетами: .index полезен для компактной сериализации (например, в БД),
// но для долговременных контрактов предпочтительно использовать .name (строковое имя),
// так как порядок может измениться, а строки более стабильны.
enum Priority { low, medium, high }

// Enum как "фиксированный data-class": значения и дополнительные поля.
// Подходит для статических ответов/кодовых таблиц. Для динамических моделей используйте классы.
enum ApiResponse {
  success(code: 200, message: "OK"),
  notFound(code: 404, message: "Not Found"),
  serverError(code: 500, message: "Internal Server Error");

  final int code;
  final String message;

  const ApiResponse({required this.code, required this.message});

  bool get isError => code >= 400;
}

/*
================================================================================
РАЗДЕЛ 4: DEMO main() — практическое использование
================================================================================
*/

void main() {
  /// enumValue.name
  print(Color.red.name); // red
  print(Color.green.name); // green

  /// ✅ Где полезно:
  /// сериализация в JSON
  /// логирование
  /// отображение в UI
  /// генерация ключей
  /// маппинг enum → строка без toString()

  /// enumValue.index
  print(Color.red.index); // 0
  print(Color.green.index); // 1
  print(Color.blue.index); // 2

  /// ✅ Где полезно:
  /// компактное хранение (например, в базе)
  /// быстрые сравнения
  /// сортировка по порядку объявления

  /// toString() — старый способ (не рекомендуется)
  print(Color.red.toString()); // Color.red

  /// Enum.compareByIndex(a, b)
  /// Сравнивает по порядку объявления:
  final list = [Color.blue, Color.red, Color.green];
  list.sort(Enum.compareByIndex);
  print(list); // [Color.red, Color.green, Color.blue]

  /// Enum.compareByName(a, b)
  /// Сравнивает по алфавиту:
  list.sort(Enum.compareByName);
  print(list); // [Color.blue, Color.green, Color.red]

  final status = OrderStatus.processing;
  final json = {
    'orderId': 123,
    'status': status.toJson(), // 1
  };

  // из JSON:
  final restor = OrderStatus.fromJson(json['status'] as int);
  print(restor); // OrderStatus.processing
  print(restor.name); // processing
  print(restor.label); // В обработке

  final listOrder = [
    OrderStatus.delivered,
    OrderStatus.pending,
    OrderStatus.processing,
    OrderStatus.cancelled,
  ];

  listOrder.sort(OrderStatus.compareByPriority);

  print(listOrder.map((s) => s.name).toList());
  // [pending, processing, shipped, delivered, cancelled] если добавишь shipped

  // Демонстрация дополнительных полей и методов в enum.
  final role = UserRole.moderator;
  print(role.level); // 2
  print(role.canDeleteContent()); // true

  // .values.byName для восстановления из строки (например, из JSON).
  final c = Color.values.byName('green');
  print(c); // Color.green
  print(c.name); // "green" — стабильная строка для логов/сериализации

  // Enum как ключи конфигурации.
  print(logMessages[LogLevel.error]); // "Ошибка"

  // Параметры в enum-значениях и логика.
  print(VehicleType.car.wheels); // 4
  print(VehicleType.truck.isHeavy()); // true

  // Extension на enum — добавляет MIME-тип.
  print(FileType.jpg.mime); // "image/jpeg"

  // .index и восстановление из .values по индексу — компактно, но осторожно с изменением порядка.
  final p = Priority.high;
  print(p.index); // 2
  final restored = Priority.values[2];
  print(restored); // Priority.high

  // "Фиксированный data-class" на enum: код + сообщение + логика isError.
  final r = ApiResponse.notFound;
  print("${r.code} - ${r.message}"); // 404 - Not Found
  print(r.isError); // true

  // Демонстрация state machine.
  final s1 = fetchData(false);
  final s2 = fetchData(true);
  renderState(s1);
  renderState(s2);
}

/*
================================================================================
РАЗДЕЛ 5: STATE MACHINE — ENUM + SEALED КЛАССЫ
================================================================================

ЗАДАЧА:
- Моделируем состояния асинхронной загрузки данных для UI.
- Enum: фиксирует "ярлык" состояния (idle/loading/success/error).
- Sealed классы: хранят сопутствующие данные (успешные — с payload, ошибка — с сообщением).
- Такой подход читабелен, расширяем, и типобезопасен.

КЛЮЧЕВОЙ МОМЕНТ:
- Переменные, которые могут ссылаться на любой из подклассов sealed-иерархии,
  должны иметь тип базового класса (LoadState), иначе возникнет ошибка присвоения.

ПРИМЕЧАНИЕ:
- Для Flutter хорошо использовать pattern matching (switch по типам объекта) в UI,
  чтобы не кастовать вручную. Ниже — пример функции renderState(), где избегаем кастов.
*/

enum LoadStatus { idle, loading, success, error }

// Sealed базовый тип: содержит общий "ярлык" состояния.
// Поле status помогает выполнять грубую маршрутизацию, логгировать, или сериализовать состояние.
// В Dart ключевое слово sealed делает класс абстрактным по сути:
//  -Нельзя создать экземпляр sealed‑класса напрямую.
//  -Можно наследовать только внутри того же файла.
// sealed гарантирует, что все возможные подтипы известны компилятору и находятся в одном месте.
// Это позволяет использовать исчерпывающий switch

sealed class LoadState {
  final LoadStatus status;
  const LoadState(this.status);
}

// Конкретные состояния.
class IdleState extends LoadState {
  const IdleState() : super(.idle);
}

class LoadingState extends LoadState {
  const LoadingState() : super(.loading);
}

// Состояние "успех" параметризуем типом данных T — пригодно для повторного использования.
class SuccessState<T> extends LoadState {
  final T data;
  const SuccessState(this.data) : super(.success);
}

class ErrorState extends LoadState {
  final String message;
  const ErrorState(this.message) : super(.error);
}

// Функция, возвращающая одно из состояний.
// ВАЖНО: тип переменной должен быть LoadState (базовый), иначе присвоение SuccessState/ErrorState
// в LoadingState будет некорректным. Ниже — корректная реализация.
LoadState fetchData(bool shouldFail) {
  // Если нужна промежуточная переменная — обязательно базовый тип.
  LoadState state = const LoadingState();

  try {
    if (shouldFail) {
      throw Exception("Сетевая ошибка");
    }
    // Успешная загрузка — возвращаем SuccessState с данными конкретного типа.
    state = const SuccessState<String>("Данные получены");
  } catch (e) {
    // Превращаем исключение в пользовательское сообщение (или код/тип ошибки).
    state = ErrorState(e.toString());
  }

  return state;
}

/*
 * final result = fetchData(false);
 * result имеет статический тип LoadState
 * поэтому так нельзя:
 *  print(result.data); // ❌ Ошибка: у LoadState нет поля data
 * 
 * Но можно проверить тип и привести:
 *  if (result is SuccessState<String>) {
 *    print(result.data); // ✅ "Данные получены"
 * }
 */

/*
================================================================================
РАЗДЕЛ 6: РЕНДЕРИНГ СОСТОЯНИЯ БЕЗ КАСТОВ (IDИОМАТИЧНО ДЛЯ UI)
================================================================================

ЦЕЛЬ:
- Избежать ручных as-кастов в UI (например, Flutter виджеты).
- Использовать оператор switch по типу объекта (pattern matching по runtime типам).
- Такой код устойчив к расширению: добавили новый подкласс — компилятор потребует обработку.

Примечание:
- В чистом Dart (без Flutter) демонстрируем текстовый рендер. В Flutter можно
  напрямую вернуть разные виджеты в зависимости от варианта.
*/

void renderState(LoadState state) {
  // Идиоматично сначала грубо проверить статус (если нужно), затем сузить тип.
  // Но современный подход — сразу использовать switch по типам:
  switch (state) {
    case IdleState():
      print("Idle: Нажмите кнопку для загрузки");
    case LoadingState():
      print("Loading: Идёт загрузка...");
    case SuccessState<String>(data: final data):
      // Pattern matching позволяет вынуть данные без кастов.
      print("Success: $data");
    case ErrorState(message: final msg):
      print("Error: $msg");
    case LoadState():
      print("Unknown state");
  }
}

/*
================================================================================
РАЗДЕЛ 7: СЕРИАЛИЗАЦИЯ И РЕКОМЕНДАЦИИ
================================================================================

- String-значения (.name) надёжнее для долговременного хранения, чем .index.
- Для обмена по сети предпочтительно маппить enum к строкам:
  Color.values.byName(json['color']) — удобно, но проверяйте валидность строки.
- Для sealed состояний используйте DTO/JSON-форматы с явным полем "type" (например, "success"/"error")
  и payload в зависимости от типа.
- Для сложных моделей данных используйте классы/record/генерацию (freezed, json_serializable).

================================================================================
РАЗДЕЛ 8: ТЕСТЫ И ПРАКТИКА
================================================================================

- Тесты для enum:
  - Проверяйте соответствие mime/description и т.д.
  - Проверяйте, что .byName восстанавливает корректные значения; валидируйте ошибки для
    неизвестных строк.
- Тесты для state machine:
  - fetchData(false) возвращает SuccessState<String> с нужным payload.
  - fetchData(true) возвращает ErrorState с ожидаемым сообщением.
  - renderState() покрывает все варианты — исчерпывающий switch.

================================================================================
КЛЮЧЕВОЕ:
- Enum — мощный тип для фиксированных вариантов с локальной логикой.
- Sealed классы — переносчики данных и детализированных состояний.
- Всегда объявляйте переменные как базовый тип иерархии, если они могут принимать разные варианты.
- Используйте pattern matching в switch по типам для UI, чтобы избежать кастов.
================================================================================
*/
