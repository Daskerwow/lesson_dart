/// ============================================================================
/// ПАТТЕРН: FACADE (Фасад)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Предоставляет унифицированный, простой интерфейс к сложной подсистеме,
/// состоящей из множества классов. Фасад не запрещает прямой доступ к
/// подсистеме, но избавляет большинство клиентов от необходимости знать
/// её внутреннее устройство.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Оформление заказа в интернет-магазине: проверка склада, списание
///   оплаты, создание доставки, отправка уведомления — 4+ подсистемы,
///   которые клиенту (контроллеру/UI) неудобно оркестрировать напрямую.
/// - Обёртка над сложной легаси-библиотекой или набором микросервисов.
library;

// --- Сложные подсистемы, о которых клиент не должен ничего знать ---

/// Выбор товара
class InventoryService {
  bool reserve(String sku, int qty) {
    print('[Inventory] Резервируем $qty x $sku');
    return true; // упрощённо: товар всегда в наличии
  }
}

/// Оплата
class PaymentService {
  bool charge(String customerId, double amount) {
    print('[Payment] Списываем \$${amount.toStringAsFixed(2)} с $customerId');
    return true; // упрощённо: всегда есть деньги
  }
}

/// Доставка
class ShippingService {
  String createShipment(String address) {
    final trackingId = 'TRACK-${DateTime.now().millisecondsSinceEpoch}';
    print('[Shipping] Создана доставка $trackingId на адрес: $address');
    return trackingId;
  }
}

/// Уведомления
class NotificationService {
  void sendOrderConfirmation(String customerId, String trackingId) {
    print('[Notify] $customerId: заказ подтверждён, трек-номер $trackingId');
  }
}

/// Проверка оплаты
class FraudCheckService {
  bool isSafe(String customerId, double amount) {
    print('[Fraud] Проверка $customerId на сумму \$$amount... OK');
    return true; // упрощённо: оплата всегда проходит
  }
}

/// ФАСАД: единая точка входа "оформить заказ", скрывающая оркестрацию
/// пяти независимых подсистем за одним простым методом.
class CheckoutFacade {
  final InventoryService _inventory = InventoryService();
  final PaymentService _payment = PaymentService();
  final ShippingService _shipping = ShippingService();
  final NotificationService _notification = NotificationService();
  final FraudCheckService _fraudCheck = FraudCheckService();

  /// Клиент вызывает один метод и не заботится о порядке и деталях
  /// работы пяти сервисов — фасад инкапсулирует всю бизнес-логику
  /// оркестрации оформления заказа.
  bool placeOrder({
    required String customerId,
    required String sku,
    required int quantity,
    required double amount,
    required String shippingAddress,
  }) {
    if (!_fraudCheck.isSafe(customerId, amount)) {
      print('Заказ отклонён: подозрение на мошенничество');
      return false;
    }
    if (!_inventory.reserve(sku, quantity)) {
      print('Заказ отклонён: товара нет на складе');
      return false;
    }
    if (!_payment.charge(customerId, amount)) {
      print('Заказ отклонён: платёж не прошёл');
      return false;
    }
    final trackingId = _shipping.createShipment(shippingAddress);
    _notification.sendOrderConfirmation(customerId, trackingId);
    print('Заказ успешно оформлен!');
    return true;
  }
}

void main() {
  final checkout = CheckoutFacade();

  // Клиентский код — одна строка вместо оркестрации пяти сервисов.
  checkout.placeOrder(
    customerId: 'cust_42',
    sku: 'SKU-BOOK-001',
    quantity: 2,
    amount: 39.98,
    shippingAddress: 'ул. Пушкина, д. 1, Москва',
  );
}
