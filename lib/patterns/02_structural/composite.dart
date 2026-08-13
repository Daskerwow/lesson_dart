/// ============================================================================
/// ПАТТЕРН: COMPOSITE (Компоновщик)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Объединяет объекты в древовидные структуры для представления иерархии
/// "часть-целое". Позволяет клиенту работать единообразно как с отдельными
/// объектами, так и с их композициями через общий интерфейс.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Файловая система (файлы и папки), дерево виджетов UI, оргструктура
///   компании, дерево категорий товаров в интернет-магазине.
/// - Когда нужно применять одну и ту же операцию (посчитать размер,
///   отрендерить, посчитать стоимость) рекурсивно ко всему дереву.
library;

/// Общий компонент — как "лист" (файл), так и "контейнер" (папка)
/// реализуют один и тот же интерфейс.
abstract class FileSystemEntry {
  const FileSystemEntry();

  String get name;
  int get sizeInBytes;

  void printTree([String indent = '']);
}

/// ЛИСТ (Leaf) — не имеет дочерних элементов.
class FileEntry implements FileSystemEntry {
  @override
  final String name;

  @override
  final int sizeInBytes;

  const FileEntry(this.name, this.sizeInBytes);

  @override
  void printTree([String indent = '']) {
    print('$indent[file] $name (${sizeInBytes}B)');
  }
}

/// КОНТЕЙНЕР (Composite) — хранит дочерние FileSystemEntry и делегирует
/// им операции, суммируя результат.
class DirectoryEntry implements FileSystemEntry {
  @override
  final String name;

  @override
  int get sizeInBytes =>
      _children.fold(0, (sum, child) => sum + child.sizeInBytes);

  final List<FileSystemEntry> _children = [];

  DirectoryEntry(this.name);

  void add(FileSystemEntry entry) => _children.add(entry);
  void remove(FileSystemEntry entry) => _children.remove(entry);

  @override
  void printTree([String indent = '']) {
    print('$indent[dir] $name/ (${sizeInBytes}B итого)');

    for (final child in _children) {
      child.printTree('$indent  ');
    }
  }
}

void main() {
  final root = DirectoryEntry('project');

  final src = DirectoryEntry('src');

  src.add(FileEntry('main.dart', 1200));
  src.add(FileEntry('utils.dart', 340));

  final tests = DirectoryEntry('test');

  tests.add(FileEntry('main_test.dart', 800));

  final nested = DirectoryEntry('widgets');

  nested.add(FileEntry('button.dart', 560));
  src.add(nested);

  root.add(src);
  root.add(tests);
  root.add(FileEntry('pubspec.yaml', 210));

  root.printTree();
  print('\nОбщий размер проекта: ${root.sizeInBytes} байт');
}
