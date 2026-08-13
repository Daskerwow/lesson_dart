/// ============================================================================
/// ПАТТЕРН: PROTOTYPE (Прототип)
/// Категория: Порождающий (Creational) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет копировать объекты, не привязываясь к их конкретным классам —
/// новый объект создаётся клонированием существующего "прототипа", а не
/// вызовом конструктора с нуля. Полезно, когда создание объекта "с нуля"
/// дорого, а нужен объект, почти идентичный уже существующему.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Игровые сущности: клонирование шаблонов врагов/юнитов с небольшими
///   вариациями вместо повторной тяжёлой инициализации.
/// - Кэш "заготовок" документов/конфигов, которые часто нужно немного
///   модифицировать перед использованием.
/// - Когда объект имеет много вложенных полей и вы хотите избежать
///   ручного копирования каждого поля в конструкторе.
library;

/// Абстрактный прототип объявляет метод клонирования.
abstract class Cloneable<T> {
  T clone();
}

/// Вложенный объект — демонстрирует важность ГЛУБОКОГО копирования:
/// если просто скопировать ссылку на Inventory, оба юнита будут делить
/// один и тот же список предметов, что приведёт к трудноуловимым багам.
class Inventory {
  final List<String> items;
  Inventory(this.items);

  Inventory deepCopy() => Inventory(List<String>.from(items));

  @override
  String toString() => items.toString();
}

/// Конкретный прототип: шаблон игрового юнита.
class GameUnit implements Cloneable<GameUnit> {
  final String type;
  final int health;
  final int damage;
  final Inventory inventory;
  final Map<String, double> position;

  const GameUnit({
    required this.type,
    required this.health,
    required this.damage,
    required this.inventory,
    required this.position,
  });

  /// Реализация клонирования — ключевой момент паттерна.
  /// ВАЖНО: делаем ГЛУБОКУЮ копию изменяемых полей (Inventory, position),
  /// иначе клон и оригинал будут делить одно и то же состояние.
  @override
  GameUnit clone() {
    return GameUnit(
      type: type,
      health: health,
      damage: damage,
      inventory: inventory.deepCopy(), // глубокая копия!
      position: Map<String, double>.from(position), // глубокая копия!
    );
  }

  @override
  String toString() =>
      '$type(hp:$health, dmg:$damage, inv:$inventory, pos:$position)';
}

/// Реестр прототипов — типичное дополнение к паттерну: хранит "эталонные"
/// шаблоны юнитов, из которых клонируются экземпляры для спавна на карте.
/// Это избавляет от повторной тяжёлой инициализации (загрузка моделей,
/// анимаций, статов из конфиг-файлов) при каждом спавне юнита.
class UnitPrototypeRegistry {
  final Map<String, GameUnit> _prototypes = {};

  void register(String key, GameUnit prototype) {
    _prototypes[key] = prototype;
  }

  /// Создаёт новый юнит клонированием зарегистрированного шаблона.
  GameUnit spawn(String key) {
    final prototype = _prototypes[key];

    if (prototype == null) {
      throw ArgumentError('Прототип "$key" не зарегистрирован');
    }

    return prototype.clone();
  }
}

void main() {
  final prototype = UnitPrototypeRegistry();

  // Эталонные шаблоны создаются один раз, "дорого" (представим, что тут
  // грузятся текстуры, анимации, баланс из JSON).
  prototype.register(
    'orc_warrior',
    GameUnit(
      type: 'Орк-воин',
      health: 120,
      damage: 15,
      inventory: Inventory(['Топор', 'Щит']),
      position: {'x': 0, 'y': 0},
    ),
  );

  // Дешёвое клонирование при каждом спавне на карте.
  final orc1 = prototype.spawn('orc_warrior')..position['x'] = 10;
  final orc2 = prototype.spawn('orc_warrior')..position['x'] = 25;

  orc1.inventory.items.add('Зелье лечения'); // не влияет на orc2!

  print('Орк 1: $orc1');
  print('Орк 2: $orc2');
  print('Инвентари независимы: ${!identical(orc1.inventory, orc2.inventory)}');
}
