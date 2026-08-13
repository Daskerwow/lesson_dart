/// ============================================================================
/// ПАТТЕРН: MEMENTO (Хранитель / Снимок)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет сохранять и восстанавливать предыдущее состояние объекта, не
/// раскрывая деталей его реализации. Три роли: Originator (создаёт снимки
/// своего состояния), Memento (неизменяемый снимок), Caretaker (хранит
/// историю снимков, но не заглядывает внутрь них).
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Undo-функциональность там, где Command избыточен (нужен просто снимок
///   всего состояния целиком, а не набор обратимых операций).
/// - Сохранение игрового прогресса (save/load), снимки состояния формы
///   перед рискованной операцией с возможностью отката.
library;

/// MEMENTO: неизменяемый снимок состояния. Инкапсулирует данные так, что
/// внешний код (Caretaker) не может их прочитать или изменить — только
/// вернуть обратно в Originator.
class EditorMemento {
  final String _content;
  final int _cursorPosition;
  final DateTime _timestamp;

  // Приватный конструктор — создать Memento может только сам Originator
  // (через фабричный метод внутри Editor), это защищает инкапсуляцию.
  EditorMemento._(this._content, this._cursorPosition)
    : _timestamp = DateTime.now();

  DateTime get timestamp => _timestamp;
}

/// ORIGINATOR: объект, чьё состояние сохраняется и восстанавливается.
class TextEditor {
  String _content = '';
  int _cursorPosition = 0;

  String get content => _content;

  void type(String text) {
    _content = _content + text;
    _cursorPosition = _content.length;
  }

  /// Создаёт снимок текущего состояния.
  EditorMemento save() {
    print('[Editor] Сохранение снимка: "$_content"');
    return EditorMemento._(_content, _cursorPosition);
  }

  /// Восстанавливает состояние из снимка.
  void restore(EditorMemento memento) {
    _content = memento._content;
    _cursorPosition = memento._cursorPosition;
    print('[Editor] Восстановлено состояние: "$_content"');
  }
}

/// CARETAKER: хранит историю снимков, но не знает и не должен знать
/// об их внутреннем содержимом — для него Memento непрозрачен.
class EditorHistory {
  final List<EditorMemento> _snapshots = [];

  void push(EditorMemento memento) => _snapshots.add(memento);

  EditorMemento? pop() {
    if (_snapshots.isEmpty) return null;
    return _snapshots.removeLast();
  }

  int get snapshotCount => _snapshots.length;
}

void main() {
  final editor = TextEditor();
  final history = EditorHistory();

  editor.type('Привет');
  history.push(editor.save()); // снимок №1: "Привет"

  editor.type(', мир');
  history.push(editor.save()); // снимок №2: "Привет, мир"

  editor.type('! Это тест.');
  print('Текущее содержимое: "${editor.content}"');

  // Откатываемся на снимок назад.
  final lastSnapshot = history.pop(); // достаём снимок "Привет, мир"
  if (lastSnapshot != null) editor.restore(lastSnapshot);

  print('После отката: "${editor.content}"');
  print('Осталось снимков в истории: ${history.snapshotCount}');
}
