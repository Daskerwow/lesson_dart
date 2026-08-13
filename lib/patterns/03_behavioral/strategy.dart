/// ============================================================================
/// ПАТТЕРН: STRATEGY (Стратегия)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет семейство алгоритмов, инкапсулирует каждый из них и делает их
/// взаимозаменяемыми. Позволяет менять алгоритм независимо от клиента,
/// который им пользуется.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Расчёт стоимости доставки/скидок разными способами в зависимости
///   от условий (страна, тип клиента, промо-акции).
/// - Разные алгоритмы сортировки/сжатия/валидации, между которыми нужно
///   переключаться в рантайме без if/else-простыней.
/// - В Dart стратегии часто удобно передавать как функции (типизированные
///   typedef), а не только как классы — показаны оба подхода.
library;

/// --- Подход 1: классический, через интерфейс (когда стратегия сложная,
/// с состоянием или несколькими методами) ---

abstract class ShippingStrategy {
  double calculate(double weightKg, double distanceKm);
  String get name;
}

class StandardShipping implements ShippingStrategy {
  @override
  String get name => 'Стандартная доставка';
  @override
  double calculate(double weightKg, double distanceKm) =>
      5.0 + weightKg * 0.5 + distanceKm * 0.1;
}

class ExpressShipping implements ShippingStrategy {
  @override
  String get name => 'Экспресс-доставка';
  @override
  double calculate(double weightKg, double distanceKm) =>
      15.0 + weightKg * 1.2 + distanceKm * 0.3;
}

class FreeShippingOverThreshold implements ShippingStrategy {
  final double orderTotal;
  final double freeThreshold;
  FreeShippingOverThreshold(this.orderTotal, {this.freeThreshold = 100});

  @override
  String get name => 'Бесплатная от ${freeThreshold.toInt()}\$';

  @override
  double calculate(double weightKg, double distanceKm) {
    if (orderTotal >= freeThreshold) return 0.0;
    return 5.0 + weightKg * 0.5;
  }
}

/// КОНТЕКСТ: хранит ссылку на текущую стратегию и делегирует ей расчёт,
/// не зная деталей конкретного алгоритма.
class ShippingCalculator {
  ShippingStrategy strategy;
  ShippingCalculator(this.strategy);

  double calculateCost(double weightKg, double distanceKm) {
    final cost = strategy.calculate(weightKg, distanceKm);
    print('${strategy.name}: \$${cost.toStringAsFixed(2)}');
    return cost;
  }
}

/// --- Подход 2: функциональные стратегии через typedef — идиоматично
/// для Dart, когда стратегия — просто чистая функция без состояния ---

typedef DiscountStrategy = double Function(double total);

double noDiscount(double total) => total;
double tenPercentOff(double total) => total * 0.9;
double blackFridayDiscount(double total) =>
    total > 200 ? total * 0.6 : total * 0.85;

class PriceCalculator {
  DiscountStrategy discountStrategy;
  PriceCalculator(this.discountStrategy);

  double finalPrice(double total) => discountStrategy(total);
}

void main() {
  print('--- Стратегии доставки (классы) ---');
  final calculator = ShippingCalculator(StandardShipping());
  calculator.calculateCost(2.5, 300);

  calculator.strategy = ExpressShipping(); // меняем стратегию в рантайме
  calculator.calculateCost(2.5, 300);

  calculator.strategy = FreeShippingOverThreshold(150);
  calculator.calculateCost(2.5, 300);

  print('\n--- Стратегии скидок (функции) ---');
  final priceCalc = PriceCalculator(tenPercentOff);
  print('Цена со скидкой 10%: ${priceCalc.finalPrice(250)}');

  priceCalc.discountStrategy = blackFridayDiscount;
  print('Цена в Чёрную пятницу: ${priceCalc.finalPrice(250)}');
}
