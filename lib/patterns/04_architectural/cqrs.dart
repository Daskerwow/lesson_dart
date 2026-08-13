/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: CQRS (Command Query Responsibility Segregation)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Разделяет операции ИЗМЕНЕНИЯ состояния (Commands) и операции ЧТЕНИЯ
/// состояния (Queries) на разные модели, вместо единого класса-репозитория
/// с методами get/save. Команды возвращают void/результат выполнения,
/// но НЕ данные; запросы только читают, но никогда не меняют состояние.
///
/// ЗАЧЕМ: модель для записи (нормализованная, с бизнес-правилами и
/// инвариантами) и модель для чтения (денормализованная, оптимизированная
/// под конкретный UI-экран) часто должны быть РАЗНЫМИ — попытка
/// использовать одну модель для обеих целей приводит к компромиссам
/// в обе стороны.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Системы с сильно разной нагрузкой на чтение/запись, где чтение можно
///   оптимизировать отдельно (кэш, read-реплики, денормализованные
///   представления) независимо от модели записи.
/// - В сочетании с Event Sourcing (не рассматривается отдельно здесь) —
///   классическая пара паттернов в сложных корпоративных системах.
/// - В умеренном виде полезен даже в простых приложениях: явное разделение
///   "команд" и "запросов" делает код читаемее (Command-Query Separation).
library;

// ============================================================================
// WRITE MODEL — модель для команд, содержит бизнес-правила и инварианты.
// ============================================================================
class InventoryItem {
  final String sku;
  int _quantity;
  InventoryItem(this.sku, this._quantity);

  void reserve(int qty) {
    if (qty > _quantity) {
      throw StateError(
        'Недостаточно товара $sku на складе: '
        'запрошено $qty, доступно $_quantity',
      );
    }
    _quantity -= qty;
  }

  void restock(int qty) => _quantity += qty;
  int get quantity => _quantity;
}

/// Команды — намерение ИЗМЕНИТЬ состояние. Именуются в повелительном
/// наклонении (Reserve, Restock), в отличие от Domain Event (прошедшее время).
abstract class Command {
  const Command();
}

class ReserveStockCommand extends Command {
  final String sku;
  final int quantity;
  const ReserveStockCommand(this.sku, this.quantity);
}

class RestockCommand extends Command {
  final String sku;
  final int quantity;
  const RestockCommand(this.sku, this.quantity);
}

/// COMMAND HANDLER — обрабатывает команды, применяя бизнес-правила
/// write-модели. Возвращает только результат операции, НЕ данные для UI.
class InventoryCommandHandler {
  final Map<String, InventoryItem> _items;
  const InventoryCommandHandler(this._items);

  void handle(Command command) {
    switch (command) {
      case ReserveStockCommand(sku: final sku, quantity: final qty):
        final item = _items[sku];
        if (item == null) throw ArgumentError('Товар $sku не найден');
        item.reserve(qty);
        print('[Command] Зарезервировано $qty x $sku');
        break;
      case RestockCommand(sku: final sku, quantity: final qty):
        final item = _items[sku];
        if (item == null) throw ArgumentError('Товар $sku не найден');
        item.restock(qty);
        print('[Command] Пополнено $qty x $sku');
        break;
    }
  }
}

// ============================================================================
// READ MODEL — отдельная, денормализованная модель, оптимизированная
// под конкретный экран/отчёт. В реальных системах часто строится
// асинхронно из потока Domain Events (Event Sourcing + CQRS).
// ============================================================================
class InventoryDashboardRow {
  final String sku;
  final int quantity;
  final String stockStatus; // "В наличии" / "Заканчивается" / "Нет в наличии"

  const InventoryDashboardRow(this.sku, this.quantity, this.stockStatus);

  @override
  String toString() => '$sku: $quantity шт. [$stockStatus]';
}

/// QUERY HANDLER — читает данные и формирует представление,
/// специально заточенное под UI (например, дашборд склада),
/// без бизнес-логики изменения состояния.
class InventoryQueryHandler {
  final Map<String, InventoryItem> _items;
  const InventoryQueryHandler(this._items);

  List<InventoryDashboardRow> getDashboard() {
    return _items.values.map((item) {
      final status = item.quantity == 0
          ? 'Нет в наличии'
          : item.quantity < 5
          ? 'Заканчивается'
          : 'В наличии';
      return InventoryDashboardRow(item.sku, item.quantity, status);
    }).toList();
  }

  InventoryDashboardRow? getBySku(String sku) {
    final item = _items[sku];
    if (item == null) return null;
    return getDashboard().firstWhere((row) => row.sku == sku);
  }
}

void main() {
  final items = {
    'sku-1': InventoryItem('sku-1', 10),
    'sku-2': InventoryItem('sku-2', 3),
  };

  // Разные "входные точки" для записи и чтения — команды не возвращают
  // данные, запросы не имеют побочных эффектов.
  final commandHandler = InventoryCommandHandler(items);
  final queryHandler = InventoryQueryHandler(items);

  print('--- Дашборд до операций ---');
  queryHandler.getDashboard().forEach(print);

  commandHandler.handle(ReserveStockCommand('sku-1', 4));
  commandHandler.handle(ReserveStockCommand('sku-2', 2));

  print('\n--- Дашборд после резервирования ---');
  queryHandler.getDashboard().forEach(print);

  commandHandler.handle(RestockCommand('sku-2', 20));

  print('\n--- Дашборд после пополнения ---');
  queryHandler.getDashboard().forEach(print);
}
