/// ============================================================================
/// АНТИПАТТЕРН: GOD OBJECT (Божественный объект)
/// ============================================================================
///
/// ПРОБЛЕМА:
/// Один класс берёт на себя слишком много ответственностей — знает и умеет
/// "всё": валидацию, бизнес-логику, доступ к БД, отправку email, логирование,
/// форматирование вывода. Нарушает Single Responsibility Principle (SRP).
///
/// ПОЧЕМУ ЭТО ПЛОХО:
/// - Любое изменение в ЛЮБОЙ части системы требует правки этого класса —
///   он становится "бутылочным горлышком" для всей команды разработки.
/// - Невозможно протестировать одну обязанность изолированно — тесты
///   на бизнес-логику требуют поднимать БД, email-сервис и т.д.
/// - Класс невозможно переиспользовать частично — берёшь либо всё, либо ничего.
/// - Высокая связанность (coupling): изменение формата email может
///   случайно сломать логику расчёта скидок, если они в одном классе.
///
/// КАК РАСПОЗНАТЬ: класс с 500+ строк, десятками полей и методов,
/// названием вроде "Manager", "Processor", "Helper", "Utils", "System".
library;

// ============================================================================
// ПЛОХО: один класс делает ВСЁ — валидацию, расчёты, "БД", email, логи.
// ============================================================================
class OrderGodObject {
  final Map<String, dynamic> _fakeDb = {};
  final List<String> _log = [];

  // Отвечает за валидацию...
  bool validateOrder(Map<String, dynamic> orderData) {
    if (orderData['items'] == null || (orderData['items'] as List).isEmpty) {
      _log.add('Валидация не пройдена: пустой заказ');
      return false;
    }
    return true;
  }

  // ...и за расчёт цены (бизнес-логика)...
  double calculateTotal(List<Map<String, dynamic>> items, {String? promoCode}) {
    var total = items.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as double),
    );
    if (promoCode == 'SALE10') total *= 0.9;
    return total;
  }

  // ...и за доступ к "БД"...
  void saveOrderToDatabase(String orderId, Map<String, dynamic> orderData) {
    _fakeDb[orderId] = orderData;
    _log.add('Заказ $orderId сохранён в БД');
  }

  // ...и за отправку email...
  void sendConfirmationEmail(String customerEmail, String orderId) {
    print(
      '[Email] Отправка подтверждения на $customerEmail для заказа $orderId',
    );
  }

  // ...и за логирование...
  void logActivity(String message) {
    _log.add('[${DateTime.now()}] $message');
  }

  // ...и за форматирование чека для печати...
  String formatReceipt(String orderId, double total) {
    return '=== ЧЕК ===\nЗаказ: $orderId\nИтого: \$${total.toStringAsFixed(2)}\n===========';
  }

  // Один метод дёргает ВСЁ перечисленное выше — при любом изменении
  // требований (формат чека, провайдер email, структура БД) придётся
  // трогать этот же гигантский класс.
  void processOrder(
    String orderId,
    String customerEmail,
    List<Map<String, dynamic>> items, {
    String? promoCode,
  }) {
    if (!validateOrder({'items': items})) return;
    final total = calculateTotal(items, promoCode: promoCode);
    saveOrderToDatabase(orderId, {'items': items, 'total': total});
    sendConfirmationEmail(customerEmail, orderId);
    logActivity('Заказ $orderId обработан на сумму $total');
    print(formatReceipt(orderId, total));
  }
}

// ============================================================================
// РЕФАКТОРИНГ: разбиваем God Object на классы с ОДНОЙ ответственностью
// каждый (см. также 06_enterprise/service_layer.dart и repository.dart —
// это те же принципы в действии).
// ============================================================================

class OrderValidator {
  bool validate(List<Map<String, dynamic>> items) => items.isNotEmpty;
}

class PriceCalculator {
  double calculateTotal(List<Map<String, dynamic>> items, {String? promoCode}) {
    var total = items.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as double),
    );
    if (promoCode == 'SALE10') total *= 0.9;
    return total;
  }
}

abstract class OrderRepository {
  void save(String orderId, Map<String, dynamic> data);
}

class InMemoryOrderRepository implements OrderRepository {
  final Map<String, dynamic> _storage = {};
  @override
  void save(String orderId, Map<String, dynamic> data) {
    _storage[orderId] = data;
    print('[Repository] Заказ $orderId сохранён');
  }
}

abstract class EmailNotifier {
  void notifyOrderConfirmed(String email, String orderId);
}

class SmtpEmailNotifier implements EmailNotifier {
  @override
  void notifyOrderConfirmed(String email, String orderId) {
    print('[Email] Подтверждение заказа $orderId отправлено на $email');
  }
}

class ReceiptFormatter {
  String format(String orderId, double total) =>
      '=== ЧЕК ===\nЗаказ: $orderId\nИтого: \$${total.toStringAsFixed(2)}\n===========';
}

/// Каждая зависимость внедряется извне (см. dependency_injection.dart) —
/// класс оркестрирует, но не реализует детали сам.
class OrderProcessor {
  final OrderValidator validator;
  final PriceCalculator calculator;
  final OrderRepository repository;
  final EmailNotifier notifier;
  final ReceiptFormatter formatter;

  OrderProcessor({
    required this.validator,
    required this.calculator,
    required this.repository,
    required this.notifier,
    required this.formatter,
  });

  void process(
    String orderId,
    String customerEmail,
    List<Map<String, dynamic>> items, {
    String? promoCode,
  }) {
    if (!validator.validate(items)) {
      print('Ошибка валидации заказа $orderId');
      return;
    }
    final total = calculator.calculateTotal(items, promoCode: promoCode);
    repository.save(orderId, {'items': items, 'total': total});
    notifier.notifyOrderConfirmed(customerEmail, orderId);
    print(formatter.format(orderId, total));
  }
}

void main() {
  print('=== ПЛОХО: God Object ===');
  OrderGodObject().processOrder('order-1', 'client@example.com', [
    {'price': 50.0},
    {'price': 30.0},
  ], promoCode: 'SALE10');

  print('\n=== ХОРОШО: разделение ответственности ===');
  final processor = OrderProcessor(
    validator: OrderValidator(),
    calculator: PriceCalculator(),
    repository: InMemoryOrderRepository(),
    notifier: SmtpEmailNotifier(),
    formatter: ReceiptFormatter(),
  );
  processor.process('order-2', 'client@example.com', [
    {'price': 50.0},
    {'price': 30.0},
  ], promoCode: 'SALE10');
  // Теперь каждый класс тестируется отдельно, PriceCalculator можно
  // переиспользовать без БД и email, EmailNotifier легко подменить
  // на fake в тестах.
}
