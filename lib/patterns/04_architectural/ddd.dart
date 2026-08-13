/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: DDD Building Blocks
/// (Entity, Value Object, Aggregate, Domain Event, Domain Service)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Domain-Driven Design — набор тактических паттернов моделирования
/// сложной бизнес-логики так, чтобы код отражал язык предметной области
/// (Ubiquitous Language):
/// - Entity — объект с уникальным ИД, идентичность важнее атрибутов
///   (два заказа с одинаковыми полями — разные заказы, если у них разный id).
/// - Value Object — объект БЕЗ идентичности, сравнивается по значению
///   (два объекта Money(10, 'USD') взаимозаменяемы).
/// - Aggregate — кластер связанных Entity/VO с единой границей транзакционной
///   согласованности; изменения идут только через Aggregate Root.
/// - Domain Event — факт, произошедший в прошлом, важный для бизнеса.
/// - Domain Service — бизнес-логика, которая не принадлежит ни одной сущности.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Сложные предметные области с богатыми бизнес-правилами (банкинг,
///   логистика, e-commerce с промо/скидками/резервированием склада).
/// - НЕ стоит применять для CRUD-приложений с простой логикой — DDD
///   добавляет сложность, которая окупается только в "сложном ядре".
library;

// ============================================================================
// VALUE OBJECT: неизменяем, сравнивается по значению, а не по ссылке.
// Хорошая практика — валидация инвариантов прямо в конструкторе.
// ============================================================================
class Money {
  final int amountInCents; // храним в центах, чтобы избежать ошибок float
  final String currency;

  Money(this.amountInCents, this.currency) {
    if (amountInCents < 0) {
      throw ArgumentError('Сумма не может быть отрицательной');
    }
  }

  Money operator +(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Нельзя складывать разные валюты: $currency и ${other.currency}',
      );
    }
    return Money(amountInCents + other.amountInCents, currency);
  }

  double get asDouble => amountInCents / 100;

  // Value Object сравнивается ПО ЗНАЧЕНИЮ полей, а не по ссылке (identity).
  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountInCents == amountInCents &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountInCents, currency);

  @override
  String toString() => '${asDouble.toStringAsFixed(2)} $currency';
}

/// Ещё один Value Object — адрес доставки. Неизменяем и сравнивается
/// по значению всех полей.
class ShippingAddress {
  final String street;
  final String city;
  final String postalCode;

  const ShippingAddress(this.street, this.city, this.postalCode);

  @override
  bool operator ==(Object other) =>
      other is ShippingAddress &&
      other.street == street &&
      other.city == city &&
      other.postalCode == postalCode;

  @override
  int get hashCode => Object.hash(street, city, postalCode);

  @override
  String toString() => '$street, $city, $postalCode';
}

// ============================================================================
// DOMAIN EVENT: неизменяемый факт "что-то произошло", часто рассылается
// другим частям системы (через Event Bus / очередь сообщений).
// ============================================================================
base class DomainEvent {
  final DateTime occurredAt;
  DomainEvent() : occurredAt = DateTime.now();
}

final class OrderPlacedEvent extends DomainEvent {
  final String orderId;
  final Money total;
  OrderPlacedEvent(this.orderId, this.total);

  @override
  String toString() => 'OrderPlacedEvent(orderId: $orderId, total: $total)';
}

// ============================================================================
// ENTITY: (сущность) имеет уникальный идентификатор, сравнивается по нему.
// ============================================================================
class OrderLine {
  final String productId;
  final Money unitPrice;
  int quantity;

  OrderLine(this.productId, this.quantity, this.unitPrice);

  Money get subtotal =>
      Money(unitPrice.amountInCents * quantity, unitPrice.currency);
}

// ============================================================================
// AGGREGATE ROOT: единственная точка входа для изменения всего кластера
// связанных объектов (Order + список OrderLine). Внешний код не должен
// напрямую модифицировать OrderLine — только через методы Order,
// которые поддерживают инварианты всего агрегата.
// ============================================================================
class Order {
  final String id; // идентичность Entity/Aggregate Root
  final List<OrderLine> _lines = [];
  ShippingAddress? _shippingAddress;
  final List<DomainEvent> _domainEvents = [];
  bool _isPlaced = false;

  Order(this.id);

  /// Все изменения агрегата идут через методы Aggregate Root — это
  /// гарантирует, что инварианты (например, "нельзя изменить заказ
  /// после оформления") никогда не нарушаются.
  void addLine(String productId, int quantity, Money unitPrice) {
    if (_isPlaced) {
      throw StateError('Нельзя изменить оформленный заказ');
    }
    _lines.add(OrderLine(productId, quantity, unitPrice));
  }

  void setShippingAddress(ShippingAddress address) {
    if (_isPlaced) {
      throw StateError('Нельзя изменить адрес оформленного заказа');
    }
    _shippingAddress = address;
  }

  Money get total {
    if (_lines.isEmpty) return Money(0, 'USD');
    return _lines.map((l) => l.subtotal).reduce((a, b) => a + b);
  }

  /// Бизнес-операция агрегата: проверяет все инварианты и, при успехе,
  /// публикует Domain Event — факт, интересный остальной системе
  /// (например, для отправки на склад, аналитики, уведомлений).
  void place() {
    if (_lines.isEmpty) {
      throw StateError('Нельзя оформить пустой заказ');
    }
    if (_shippingAddress == null) {
      throw StateError('Не указан адрес доставки');
    }
    _isPlaced = true;
    _domainEvents.add(OrderPlacedEvent(id, total));
  }

  List<DomainEvent> pullDomainEvents() {
    final events = List<DomainEvent>.from(_domainEvents);
    _domainEvents.clear();
    return events;
  }
}

// ============================================================================
// DOMAIN SERVICE: бизнес-логика, которая не принадлежит естественно
// ни одной конкретной сущности (например, сравнение цен между заказами
// разных покупателей, расчёт скидки на основе внешних правил).
// ============================================================================
class LoyaltyDiscountService {
  /// Правило скидки зависит от истории ЗАКАЗОВ клиента — это не свойство
  /// одного Order, поэтому логика вынесена в отдельный Domain Service.
  Money calculateDiscount(List<Order> customerOrderHistory, Order newOrder) {
    final placedOrdersCount = customerOrderHistory.length;
    if (placedOrdersCount >= 5) {
      // Скидка 10% для постоянных клиентов.
      final discountCents = (newOrder.total.amountInCents * 0.1).round();
      return Money(discountCents, newOrder.total.currency);
    }
    return Money(0, newOrder.total.currency);
  }
}

void main() {
  final order = Order('order-123');
  order.addLine('sku-1', 2, Money(1500, 'USD')); // $15.00 x 2
  order.addLine('sku-2', 1, Money(4999, 'USD')); // $49.99
  order.setShippingAddress(
    const ShippingAddress('ул. Ленина, 5', 'Москва', '101000'),
  );

  print('Итого до оформления: ${order.total}');
  order.place();
  print('Заказ оформлен!');

  // После place() агрегат защищает свои инварианты:
  try {
    order.addLine('sku-3', 1, Money(1000, 'USD'));
  } on StateError catch (e) {
    print('Ошибка (ожидаемо): $e');
  }

  // Domain Events публикуются наружу для остальной системы.
  for (final event in order.pullDomainEvents()) {
    print('Опубликовано событие: $event');
  }

  final loyaltyService = LoyaltyDiscountService();
  final history = List.generate(6, (i) => Order('past-$i'));
  final discount = loyaltyService.calculateDiscount(history, order);
  print('Скидка постоянного клиента: $discount');
}
