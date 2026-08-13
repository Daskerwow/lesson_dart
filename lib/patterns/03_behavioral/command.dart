/// ============================================================================
/// ПАТТЕРН: COMMAND (Команда)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Инкапсулирует запрос в виде объекта, позволяя параметризовать клиентов
/// с разными запросами, ставить запросы в очередь, логировать их и
/// поддерживать отмену операций (undo/redo).
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Undo/Redo в текстовых/графических редакторах — классический кейс.
/// - Очереди задач (job queue), отложенное выполнение операций.
/// - Макросы — запись последовательности команд для повторного выполнения.
library;

/// Получатель (Receiver) — объект, над которым выполняются реальные операции.
class TextDocument {
  final StringBuffer _buffer = StringBuffer();
  String get content => _buffer.toString();

  void insert(int position, String text) {
    final current = _buffer.toString();
    _buffer
      ..clear()
      ..write(current.substring(0, position))
      ..write(text)
      ..write(current.substring(position));
  }

  void delete(int position, int length) {
    final current = _buffer.toString();
    _buffer
      ..clear()
      ..write(current.substring(0, position))
      ..write(current.substring(position + length));
  }
}

/// Абстрактная команда: объявляет execute() и undo() — ключевая часть
/// паттерна для поддержки отмены операций.
abstract class Command {
  void execute();
  void undo();
}

class InsertTextCommand implements Command {
  final TextDocument document;
  final int position;
  final String text;

  InsertTextCommand(this.document, this.position, this.text);

  @override
  void execute() => document.insert(position, text);

  @override
  void undo() => document.delete(position, text.length);
}

class DeleteTextCommand implements Command {
  final TextDocument document;
  final int position;
  final int length;
  late String _deletedText; // сохраняем удалённый текст для undo

  DeleteTextCommand(this.document, this.position, this.length);

  @override
  void execute() {
    _deletedText = document.content.substring(position, position + length);
    document.delete(position, length);
  }

  @override
  void undo() => document.insert(position, _deletedText);
}

/// ИНВОКЕР (Invoker): хранит историю команд и управляет undo/redo,
/// не зная деталей конкретных команд — только интерфейс Command.
class CommandManager {
  final List<Command> _history = [];
  int _cursor = -1; // указывает на последнюю выполненную команду

  void execute(Command command) {
    command.execute();
    // При выполнении новой команды после отмены — "будущее" (redo-стек)
    // обрезается, как в большинстве текстовых редакторов.
    _history.removeRange(_cursor + 1, _history.length);
    _history.add(command);
    _cursor++;
  }

  void undo() {
    if (_cursor < 0) {
      print('Нечего отменять');
      return;
    }
    _history[_cursor].undo();
    _cursor--;
  }

  void redo() {
    if (_cursor + 1 >= _history.length) {
      print('Нечего повторять');
      return;
    }
    _cursor++;
    _history[_cursor].execute();
  }
}

void main() {
  final doc = TextDocument();
  final manager = CommandManager();

  manager.execute(InsertTextCommand(doc, 0, 'Привет, '));
  print('После вставки: "${doc.content}"');

  manager.execute(InsertTextCommand(doc, 8, 'мир!'));
  print('После вставки: "${doc.content}"');

  manager.undo();
  print('После undo: "${doc.content}"');

  manager.redo();
  print('После redo: "${doc.content}"');

  manager.execute(DeleteTextCommand(doc, 0, 7));
  print('После удаления: "${doc.content}"');

  manager.undo();
  print('После undo удаления: "${doc.content}"');
}
