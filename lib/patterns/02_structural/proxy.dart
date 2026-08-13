/// ============================================================================
/// ПАТТЕРН: PROXY (Заместитель)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Предоставляет объект-заместитель, который контролирует доступ к другому
/// объекту (реальному субъекту), реализуя тот же интерфейс. Позволяет
/// добавить дополнительное поведение (ленивую загрузку, контроль доступа,
/// кэширование, логирование) без изменения самого объекта.
///
/// ВИДЫ PROXY:
/// - Virtual Proxy — ленивая инициализация дорогого объекта.
/// - Protection Proxy — контроль доступа по правам.
/// - Remote Proxy — представляет объект, находящийся в другом адресном
///   пространстве (по сути — любой сгенерированный gRPC/REST клиент).
/// - Caching Proxy — кэширует результаты дорогих операций.
///
/// ОТЛИЧИЕ ОТ DECORATOR: Proxy контролирует доступ (может вообще не
/// пропустить вызов к реальному объекту), Decorator — добавляет поведение,
/// но не блокирует и не заменяет обращение к обёрнутому объекту.
library;

/// Общий интерфейс — субъект и его заместитель.
abstract class Document {
  String read();
}

/// РЕАЛЬНЫЙ СУБЪЕКТ — "дорогой" в создании объект (имитация: тяжёлый
/// PDF-файл, инициализация которого требует чтения с диска).
class RealDocument implements Document {
  final String path;
  late final String _content;

  RealDocument(this.path) {
    print('[RealDocument] Дорогая загрузка файла $path с диска...');
    _content = 'Содержимое документа "$path"';
  }

  @override
  String read() => _content;
}

/// VIRTUAL PROXY: откладывает создание RealDocument до первого реального
/// обращения (ленивая инициализация) — если документ так и не прочитают,
/// дорогая загрузка вообще не произойдёт.
class LazyDocumentProxy implements Document {
  final String path;
  RealDocument? _real;

  LazyDocumentProxy(this.path);

  @override
  String read() {
    // Создаём реальный объект только при первом обращении.
    _real ??= RealDocument(path);
    return _real!.read();
  }
}

/// PROTECTION PROXY: контролирует доступ на основе прав пользователя,
/// не пропуская вызов к реальному объекту, если прав недостаточно.
class ProtectedDocumentProxy implements Document {
  final Document _real;
  final String _userRole;

  ProtectedDocumentProxy(this._real, this._userRole);

  @override
  String read() {
    if (_userRole != 'admin' && _userRole != 'editor') {
      throw StateError(
        'Доступ запрещён: недостаточно прав для чтения документа',
      );
    }
    print('[ProtectionProxy] Доступ разрешён для роли "$_userRole"');
    return _real.read();
  }
}

/// CACHING PROXY: кэширует результат дорогого чтения, чтобы повторные
/// обращения не приводили к повторному дорогому вызову.
class CachingDocumentProxy implements Document {
  final Document _real;
  String? _cachedContent;

  CachingDocumentProxy(this._real);

  @override
  String read() {
    if (_cachedContent != null) {
      print('[CachingProxy] Возврат из кэша');
      return _cachedContent!;
    }
    _cachedContent = _real.read();
    return _cachedContent!;
  }
}

void main() {
  print('--- Virtual Proxy: ленивая загрузка ---');
  final lazyDoc = LazyDocumentProxy('report_2026.pdf');
  print('Прокси создан, но файл ещё не загружен');
  print(lazyDoc.read()); // вот тут произойдёт реальная загрузка
  print(lazyDoc.read()); // повторное чтение — RealDocument уже создан

  print('\n--- Protection Proxy: контроль доступа ---');
  final protected = ProtectedDocumentProxy(RealDocument('secret.pdf'), 'guest');
  try {
    protected.read();
  } on StateError catch (e) {
    print('Ошибка: $e');
  }

  print('\n--- Caching Proxy: кэширование дорогих вызовов ---');
  final cached = CachingDocumentProxy(RealDocument('big_file.pdf'));
  cached
      .read(); // дорогая загрузка внутри RealDocument уже произошла при создании
  cached.read(); // а вот это — уже из кэша прокси
}
