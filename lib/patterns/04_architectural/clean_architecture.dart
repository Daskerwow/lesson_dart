/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: CLEAN ARCHITECTURE (Роберт Мартин)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Организует код в концентрические слои с ЖЁСТКИМ правилом зависимостей:
/// внутренние слои НИЧЕГО не знают о внешних. Зависимости всегда направлены
/// внутрь: Presentation -> Domain <- Data. Domain (бизнес-логика) не зависит
/// ни от UI, ни от способа хранения данных — это делает бизнес-логику
/// тестируемой и независимой от фреймворков/БД/API.
///
/// СЛОИ (от внутреннего к внешнему):
/// 1. Domain (Entities, Use Cases, Repository-интерфейсы) — ядро, без
///    зависимостей от Flutter/HTTP/БД.
/// 2. Data (реализации репозиториев, источники данных: API, БД, кэш).
/// 3. Presentation (UI, ViewModel/BLoC, виджеты).
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Средние и крупные приложения, где бизнес-логика должна пережить смену
///   UI-фреймворка или источника данных (например, миграция REST -> GraphQL).
/// - Проекты с высокими требованиями к unit-тестируемости бизнес-правил.
library;

// ============================================================================
// СЛОЙ DOMAIN — ядро приложения, не знает о Data и Presentation.
// ============================================================================

/// Entity — чистая бизнес-сущность без привязки к JSON/БД.
class Order {
  final String id;
  final double totalAmount;
  final List<String> itemIds;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.totalAmount,
    required this.itemIds,
    required this.createdAt,
  });

  /// Бизнес-правило внутри Entity: заказ считается крупным, если сумма
  /// выше порога. Такая логика должна жить в Domain, а не в UI или API-слое.
  bool get isLargeOrder => totalAmount > 500;
}

/// Repository-ИНТЕРФЕЙС определён в Domain-слое (Dependency Inversion) —
/// Domain диктует контракт, а не зависит от конкретной реализации.
/// Конкретную реализацию (поход в БД/API) предоставит слой Data.
abstract class OrderRepository {
  Future<List<Order>> getOrders(String userId);
  Future<void> placeOrder(Order order);
}

/// Use Case (Interactor) — инкапсулирует ОДНУ бизнес-операцию.
/// Каждый Use Case — отдельный класс с единственным методом `execute`,
/// что делает бизнес-логику легко читаемой и тестируемой по отдельности.
class GetLargeOrdersUseCase {
  final OrderRepository repository;
  GetLargeOrdersUseCase(this.repository);

  Future<List<Order>> execute(String userId) async {
    final orders = await repository.getOrders(userId);
    return orders.where((o) => o.isLargeOrder).toList();
  }
}

class PlaceOrderUseCase {
  final OrderRepository repository;
  PlaceOrderUseCase(this.repository);

  Future<void> execute(Order order) async {
    if (order.itemIds.isEmpty) {
      throw ArgumentError('Заказ должен содержать хотя бы один товар');
    }
    await repository.placeOrder(order);
  }
}

// ============================================================================
// СЛОЙ DATA — реализует интерфейсы из Domain, знает про API/БД,
// но Domain о слое Data ничего не знает (依赖 направлена внутрь).
// ============================================================================

/// DTO — модель "сырых" данных ровно в том виде, в каком их отдаёт API.
class OrderDto {
  final String id;
  final double total;
  final List<String> items;
  final String createdAtIso;

  OrderDto(this.id, this.total, this.items, this.createdAtIso);

  /// Маппинг DTO -> Domain Entity. Именно этот слой отвечает за
  /// преобразование "внешнего" формата во "внутренний".
  Order toEntity() => Order(
    id: id,
    totalAmount: total,
    itemIds: items,
    createdAt: DateTime.parse(createdAtIso),
  );
}

/// Источник данных — имитация похода в удалённый API.
class OrderRemoteDataSource {
  Future<List<OrderDto>> fetchOrders(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      OrderDto('o1', 120.0, ['item1'], '2026-01-01T10:00:00Z'),
      OrderDto('o2', 750.0, ['item2', 'item3'], '2026-02-01T10:00:00Z'),
    ];
  }

  Future<void> sendOrder(OrderDto dto) async {
    await Future.delayed(const Duration(milliseconds: 100));
    print('[API] Заказ ${dto.id} отправлен на сервер');
  }
}

/// КОНКРЕТНАЯ реализация Repository-интерфейса из Domain.
/// Знает про DTO и DataSource — но сама интерфейс не диктует, а реализует.
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  OrderRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Order>> getOrders(String userId) async {
    final dtos = await remoteDataSource.fetchOrders(userId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<void> placeOrder(Order order) async {
    final dto = OrderDto(
      order.id,
      order.totalAmount,
      order.itemIds,
      order.createdAt.toIso8601String(),
    );
    await remoteDataSource.sendOrder(dto);
  }
}

// ============================================================================
// СЛОЙ PRESENTATION — использует Use Cases, ничего не знает о Data-слое
// напрямую (только через абстракции Domain).
// ============================================================================

class OrdersScreenController {
  final GetLargeOrdersUseCase getLargeOrders;
  final PlaceOrderUseCase placeOrder;

  OrdersScreenController(this.getLargeOrders, this.placeOrder);

  Future<void> onScreenOpened(String userId) async {
    final orders = await getLargeOrders.execute(userId);
    print('[UI] Крупных заказов: ${orders.length}');
    for (final o in orders) {
      print('  Заказ ${o.id}: \$${o.totalAmount}');
    }
  }
}

void main() async {
  // Композиция зависимостей (в реальном проекте — через DI-контейнер,
  // см. 06_enterprise/dependency_injection.dart).
  final dataSource = OrderRemoteDataSource();
  final repository = OrderRepositoryImpl(dataSource);
  final getLargeOrders = GetLargeOrdersUseCase(repository);
  final placeOrder = PlaceOrderUseCase(repository);
  final controller = OrdersScreenController(getLargeOrders, placeOrder);

  await controller.onScreenOpened('user_1');

  // Domain-слой можно протестировать с FAKE-репозиторием, вообще не трогая
  // сеть — это и есть главное преимущество Clean Architecture.
}
