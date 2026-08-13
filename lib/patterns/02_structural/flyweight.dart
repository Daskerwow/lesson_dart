/// ============================================================================
/// ПАТТЕРН: FLYWEIGHT (Приспособленец / Легковес)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет вместить большее количество объектов в отведённую оперативную
/// память за счёт разделения общего (intrinsic) состояния между множеством
/// объектов, вместо хранения его в каждом объекте отдельно. Уникальное
/// (extrinsic) состояние передаётся снаружи при каждом использовании.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Рендеринг текста: миллионы символов на экране, но уникальных
///   "глифов" (шрифт+начертание+размер) всего несколько десятков.
/// - Игры с большим числом однотипных объектов (деревья в лесу, частицы,
///   пули) — общая модель/текстура одна, а позиция и поворот — уникальны.
/// - Пул строк/объектов с ограниченным набором значений.
library;

/// FLYWEIGHT: неизменяемое разделяемое (intrinsic) состояние — то, что
/// одинаково для множества объектов дерева одного вида: текстура, модель,
/// параметры анимации. Такой объект дорог в создании, поэтому переиспользуется.
class TreeType {
  final String name;
  final String textureId; // условно "тяжёлые" данные — путь к текстуре
  final String meshId; // условно "тяжёлые" данные — 3D-модель

  TreeType(this.name, this.textureId, this.meshId) {
    // Имитация дорогой загрузки ресурсов при создании нового типа.
    print('Загружаем тяжёлые ресурсы для типа дерева "$name"...');
  }

  void render(double x, double y, double scale) {
    print(
      'Рендер "$name" в ($x, $y) масштаб=$scale '
      '[текстура: $textureId, модель: $meshId]',
    );
  }
}

/// FLYWEIGHT FACTORY: гарантирует переиспользование TreeType — если тип
/// с таким набором параметров уже создан, возвращает существующий объект
/// вместо создания нового (и повторной дорогой загрузки ресурсов).
class TreeTypeFactory {
  static final Map<String, TreeType> _cache = {};

  static TreeType getTreeType(String name, String textureId, String meshId) {
    final key = '$name|$textureId|$meshId';
    return _cache.putIfAbsent(key, () => TreeType(name, textureId, meshId));
  }

  static int get cachedTypesCount => _cache.length;
}

/// CONTEXT: хранит только уникальное (extrinsic) состояние — позицию
/// конкретного дерева на карте — и ссылку на разделяемый Flyweight.
/// Таких объектов на карте могут быть миллионы, но памяти они занимают
/// мало, т.к. "тяжёлые" данные не дублируются.
class TreeInstance {
  final double x;
  final double y;
  final double scale;
  final TreeType type; // ссылка на разделяемый flyweight

  TreeInstance(this.x, this.y, this.scale, this.type);

  void render() => type.render(x, y, scale);
}

/// Лес — коллекция миллионов TreeInstance, но всего нескольких TreeType.
class Forest {
  final List<TreeInstance> _trees = [];

  void plantTree(
    double x,
    double y,
    double scale,
    String name,
    String textureId,
    String meshId,
  ) {
    /// Берем тяжелые данные из кеша
    final type = TreeTypeFactory.getTreeType(name, textureId, meshId);

    _trees.add(TreeInstance(x, y, scale, type));
  }

  void render() {
    for (final tree in _trees) {
      tree.render();
    }
  }

  int get treeCount => _trees.length;
}

void main() {
  final forest = Forest();

  // Сажаем 6 деревьев, но типов всего 2 — "Дуб" и "Сосна".
  // Тяжёлые ресурсы (текстуры/модели) загрузятся только 2 раза,
  // а не 6, благодаря переиспользованию Flyweight.
  forest.plantTree(10, 20, 1.0, 'Дуб', 'oak.png', 'oak.mesh');
  forest.plantTree(15, 25, 1.2, 'Дуб', 'oak.png', 'oak.mesh');
  forest.plantTree(30, 40, 0.9, 'Сосна', 'pine.png', 'pine.mesh');
  forest.plantTree(35, 45, 1.1, 'Сосна', 'pine.png', 'pine.mesh');
  forest.plantTree(50, 60, 1.0, 'Дуб', 'oak.png', 'oak.mesh');
  forest.plantTree(55, 65, 1.3, 'Сосна', 'pine.png', 'pine.mesh');

  print('---');
  forest.render();

  print('\nВсего деревьев в лесу: ${forest.treeCount}');
  print(
    'Уникальных типов (flyweight) в кэше: '
    '${TreeTypeFactory.cachedTypesCount}',
  );
}
