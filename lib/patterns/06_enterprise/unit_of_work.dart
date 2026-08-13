/// ============================================================================
/// ПАТТЕРН: UNIT OF WORK (Единица работы)
/// Категория: Корпоративный (Fowler, PoEAA)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Отслеживает список объектов, затронутых бизнес-транзакцией (новые,
/// изменённые, удалённые), и координирует запись всех изменений одним
/// согласованным блоком (commit), либо откатывает их все при ошибке.
/// Позволяет не делать отдельный запрос к БД на каждое изменение объекта,
/// а накопить их и применить атомарно.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Операции, затрагивающие несколько сущностей одновременно (например,
///   оформление заказа: создать Order, обновить Inventory, создать Invoice)
///   — либо всё сохраняется, либо ничего (транзакционность).
/// - ORM-подобные слои доступа к данным (это именно то, что делает
///   DbContext в Entity Framework или Session в Hibernate).
library;

abstract class Entity {
  String get id;
}

class Customer implements Entity {
  @override
  final String id;
  String name;
  int loyaltyPoints;
  Customer(this.id, this.name, this.loyaltyPoints);
}

class Order implements Entity {
  @override
  final String id;
  final String customerId;
  double total;
  Order(this.id, this.customerId, this.total);
}

/// Простейшее хранилище — имитация таблицы в БД.
class FakeDatabase {
  final Map<String, Customer> customers = {};
  final Map<String, Order> orders = {};

  void commitCustomer(Customer c) {
    customers[c.id] = c;
    print('[DB] Customer ${c.id} записан (points: ${c.loyaltyPoints})');
  }

  void commitOrder(Order o) {
    orders[o.id] = o;
    print('[DB] Order ${o.id} записан (total: ${o.total})');
  }

  void removeOrder(String id) {
    orders.remove(id);
    print('[DB] Order $id удалён');
  }
}

/// UNIT OF WORK: отслеживает "грязные" (изменённые), новые и удалённые
/// сущности с момента последнего commit(). Реальная запись в БД происходит
/// ТОЛЬКО при вызове commit() — единым согласованным блоком.
class UnitOfWork {
  final FakeDatabase _db;
  final List<Entity> _newEntities = [];
  final List<Entity> _dirtyEntities = [];
  final List<Entity> _removedEntities = [];

  UnitOfWork(this._db);

  void registerNew(Entity entity) {
    if (_newEntities.contains(entity)) return;
    _newEntities.add(entity);
  }

  void registerDirty(Entity entity) {
    if (_newEntities.contains(entity) || _dirtyEntities.contains(entity)) {
      return;
    }
    _dirtyEntities.add(entity);
  }

  void registerRemoved(Entity entity) {
    _newEntities.remove(entity);
    _dirtyEntities.remove(entity);
    if (!_removedEntities.contains(entity)) _removedEntities.add(entity);
  }

  /// Применяет накопленные изменения одним согласованным блоком.
  /// В реальной БД здесь была бы транзакция (BEGIN/COMMIT/ROLLBACK) —
  /// если какая-то операция упадёт, откатываются ВСЕ изменения этого UoW.
  void commit() {
    print('--- Начало транзакции UnitOfWork ---');
    try {
      for (final entity in [..._newEntities, ..._dirtyEntities]) {
        _persist(entity);
      }
      for (final entity in _removedEntities) {
        _delete(entity);
      }
      print('--- Транзакция успешно зафиксирована ---');
    } catch (e) {
      print('--- ОШИБКА, откат транзакции: $e ---');
      rethrow;
    } finally {
      _newEntities.clear();
      _dirtyEntities.clear();
      _removedEntities.clear();
    }
  }

  void _persist(Entity entity) {
    if (entity is Customer) _db.commitCustomer(entity);
    if (entity is Order) _db.commitOrder(entity);
  }

  void _delete(Entity entity) {
    if (entity is Order) _db.removeOrder(entity.id);
  }
}

void main() {
  final db = FakeDatabase();
  final uow = UnitOfWork(db);

  // Бизнес-операция "оформление заказа" затрагивает две сущности:
  // новый Order + изменение loyaltyPoints у Customer.
  final customer = Customer('c1', 'Иван Иванов', 100);
  final order = Order('o1', 'c1', 250.0);

  uow.registerNew(order);
  customer.loyaltyPoints += 25; // бизнес-правило: +25 баллов за заказ
  uow.registerDirty(customer);

  // Ни одна запись ещё не попала в "БД" — они лишь отслеживаются UoW.
  print(
    'До commit(): customers в БД = ${db.customers.length}, orders = ${db.orders.length}',
  );

  uow.commit(); // атомарная фиксация всех накопленных изменений

  print(
    'После commit(): customers в БД = ${db.customers.length}, orders = ${db.orders.length}',
  );
}
