/// ============================================================================
/// ПАТТЕРН: TEMPLATE METHOD (Шаблонный метод)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет скелет алгоритма в базовом классе, позволяя подклассам
/// переопределять отдельные шаги алгоритма без изменения его общей
/// структуры. В отличие от Strategy (композиция, весь алгоритм подменяется
/// целиком), Template Method использует наследование и меняет только
/// отдельные части алгоритма, сохраняя общий "скелет" неизменным.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Импорт данных из разных источников (CSV/JSON/XML), где общий процесс
///   (открыть -> прочитать -> распарсить -> валидировать -> сохранить)
///   одинаков, а детали парсинга отличаются.
/// - Тестовые фреймворки (setUp -> test -> tearDown).
/// - Любой процесс с фиксированными этапами, но вариативной реализацией
///   отдельных шагов.
library;

/// Абстрактный класс с ШАБЛОННЫМ МЕТОДОМ importData() — он фиксирует
/// порядок шагов и НЕ должен переопределяться в наследниках (в Dart нет
/// ключевого слова `final` для методов классов, поэтому это соглашение
/// подкрепляется документацией и код-ревью).
abstract class DataImporter {
  /// Шаблонный метод — определяет неизменный скелет алгоритма импорта.
  /// Каждый шаг либо фиксирован здесь, либо делегирован абстрактным
  /// методам, которые обязаны реализовать подклассы.
  Future<ImportResult> importData(String source) async {
    print('=== Начало импорта из $source ===');
    final rawData = await readSource(source);
    final parsedRecords = parse(rawData);
    final validRecords = <Map<String, dynamic>>[];
    final errors = <String>[];

    for (final record in parsedRecords) {
      final error = validate(record);
      if (error == null) {
        validRecords.add(record);
      } else {
        errors.add(error);
      }
    }

    // (hook) — необязательный шаг с реализацией по умолчанию,
    // подклассы могут его переопределить, но не обязаны.
    await afterValidation(validRecords, errors);

    await save(validRecords);
    print(
      '=== Импорт завершён: ${validRecords.length} успешно, '
      '${errors.length} с ошибками ===\n',
    );
    return ImportResult(validRecords.length, errors);
  }

  // --- Абстрактные шаги, обязательные для реализации в подклассах ---
  Future<String> readSource(String source);
  List<Map<String, dynamic>> parse(String rawData);
  Future<void> save(List<Map<String, dynamic>> records);

  // --- Шаг с реализацией по умолчанию — общий для всех форматов ---
  String? validate(Map<String, dynamic> record) {
    if (!record.containsKey('id')) return 'Отсутствует обязательное поле id';
    return null;
  }

  // --- Хук: подкласс может переопределить, но не обязан ---
  Future<void> afterValidation(
    List<Map<String, dynamic>> valid,
    List<String> errors,
  ) async {
    // Реализация по умолчанию — ничего не делает.
  }
}

class ImportResult {
  final int successCount;
  final List<String> errors;
  ImportResult(this.successCount, this.errors);
}

/// Конкретная реализация: импорт из CSV.
class CsvDataImporter extends DataImporter {
  @override
  Future<String> readSource(String source) async {
    print('[CSV] Чтение файла $source');
    return 'id,name\n1,Товар А\n2,Товар Б\n,Товар без id'; // имитация содержимого
  }

  @override
  List<Map<String, dynamic>> parse(String rawData) {
    final lines = rawData.split('\n');
    final headers = lines.first.split(',');
    return lines.skip(1).map((line) {
      final values = line.split(',');
      return Map.fromIterables(headers, values);
    }).toList();
  }

  @override
  Future<void> save(List<Map<String, dynamic>> records) async {
    print('[CSV] Сохранение ${records.length} записей в БД');
  }
}

/// Конкретная реализация: импорт из JSON, с дополнительным хуком.
class JsonDataImporter extends DataImporter {
  @override
  Future<String> readSource(String source) async {
    print('[JSON] Чтение файла $source');
    return '[{"id":"1","name":"Товар В"},{"id":"2","name":"Товар Г"}]';
  }

  @override
  List<Map<String, dynamic>> parse(String rawData) {
    // Упрощённый разбор для демонстрации (в реальности — dart:convert jsonDecode).
    return [
      {'id': '1', 'name': 'Товар В'},
      {'id': '2', 'name': 'Товар Г'},
    ];
  }

  @override
  Future<void> save(List<Map<String, dynamic>> records) async {
    print('[JSON] Сохранение ${records.length} записей в БД');
  }

  @override
  Future<void> afterValidation(
    List<Map<String, dynamic>> valid,
    List<String> errors,
  ) async {
    // Переопределённый хук: JSON-импортёр дополнительно шлёт метрику.
    print(
      '[JSON] Отправка метрики: успешно=${valid.length}, ошибок=${errors.length}',
    );
  }
}

void main() async {
  final DataImporter csvImporter = CsvDataImporter();
  await csvImporter.importData('products.csv');

  final DataImporter jsonImporter = JsonDataImporter();
  await jsonImporter.importData('products.json');
}
