/// ============================================================================
/// АНТИПАТТЕРН: SPAGHETTI CODE (Спагетти-код)
/// ============================================================================
///
/// ПРОБЛЕМА:
/// Код с запутанной, непрозрачной структурой управления: глубоко вложенные
/// условия, дублирующаяся логика, отсутствие чёткого разделения на функции/
/// модули, побочные эффекты, разбросанные где попало. Логика "переплетена"
/// настолько, что невозможно проследить путь выполнения без построчной
/// трассировки.
///
/// ПОЧЕМУ ЭТО ПЛОХО:
/// - Крайне сложно вносить изменения — правка одного места ломает другое
///   в неочевидном месте ("эффект бабочки").
/// - Невозможно писать unit-тесты — логика не разбита на изолированные,
///   тестируемые единицы.
/// - Высокая когнитивная нагрузка: чтобы понять код, надо держать в голове
///   весь путь выполнения целиком.
///
/// КАК РАСПОЗНАТЬ: вложенность if больше 3-4 уровней, функции на
/// 100+ строк, дублирующиеся куски кода, "магические числа"/строки без
/// объяснения, смешение уровней абстракции в одной функции.
library;

// ============================================================================
// ПЛОХО: глубоко вложенная, непрозрачная логика расчёта скидки на заказ.
// ============================================================================
double calculateDiscountSpaghetti(
  String customerType,
  double orderTotal,
  int itemCount,
  bool isHoliday,
  String? couponCode,
  int customerYears,
) {
  double discount = 0;
  if (customerType == 'vip') {
    if (orderTotal > 1000) {
      if (isHoliday) {
        if (couponCode != null && couponCode.startsWith('VIP')) {
          discount = orderTotal * 0.3;
        } else {
          if (customerYears > 5) {
            discount = orderTotal * 0.25;
          } else {
            discount = orderTotal * 0.2;
          }
        }
      } else {
        if (itemCount > 10) {
          discount = orderTotal * 0.15;
        } else {
          discount = orderTotal * 0.1;
        }
      }
    } else {
      if (couponCode != null) {
        discount = orderTotal * 0.05;
      } else {
        discount = 0;
      }
    }
  } else {
    if (customerType == 'regular') {
      if (isHoliday) {
        if (orderTotal > 500) {
          discount = orderTotal * 0.1;
        } else {
          discount = 0;
        }
      } else {
        if (couponCode != null && couponCode == 'SAVE5') {
          discount = orderTotal * 0.05;
        }
      }
    }
    // ...и так далее, каждое новое бизнес-правило добавляет ещё уровень
    // вложенности, "спагетти" из условий продолжает расти бесконтрольно.
  }
  return discount;
}

// ============================================================================
// РЕФАКТОРИНГ: явные, именованные, тестируемые правила вместо вложенных if.
// Используем комбинацию "ранних выходов" (guard clauses), вынесенных
// констант и, в идеале, паттерна Strategy (см. 03_behavioral/strategy.dart)
// для полностью расширяемого набора правил.
// ============================================================================

class DiscountContext {
  final String customerType;
  final double orderTotal;
  final int itemCount;
  final bool isHoliday;
  final String? couponCode;
  final int customerYears;

  DiscountContext({
    required this.customerType,
    required this.orderTotal,
    required this.itemCount,
    required this.isHoliday,
    this.couponCode,
    required this.customerYears,
  });
}

/// Каждое правило — маленькая, изолированная, ЛЕГКО ТЕСТИРУЕМАЯ функция
/// с говорящим именем. Порядок применения правил явный и читаемый.
abstract class DiscountRule {
  /// Возвращает применимую скидку или null, если правило не подходит.
  double? apply(DiscountContext ctx);
}

class VipHolidayCouponDiscount implements DiscountRule {
  @override
  double? apply(DiscountContext ctx) {
    final isVipCoupon = ctx.couponCode?.startsWith('VIP') ?? false;
    if (ctx.customerType == 'vip' &&
        ctx.orderTotal > 1000 &&
        ctx.isHoliday &&
        isVipCoupon) {
      return ctx.orderTotal * 0.3;
    }
    return null;
  }
}

class VipLoyaltyHolidayDiscount implements DiscountRule {
  @override
  double? apply(DiscountContext ctx) {
    if (ctx.customerType != 'vip' || ctx.orderTotal <= 1000 || !ctx.isHoliday) {
      return null;
    }
    return ctx.customerYears > 5 ? ctx.orderTotal * 0.25 : ctx.orderTotal * 0.2;
  }
}

class VipBulkOrderDiscount implements DiscountRule {
  @override
  double? apply(DiscountContext ctx) {
    if (ctx.customerType != 'vip' || ctx.orderTotal <= 1000 || ctx.isHoliday) {
      return null;
    }
    return ctx.itemCount > 10 ? ctx.orderTotal * 0.15 : ctx.orderTotal * 0.1;
  }
}

class RegularHolidayDiscount implements DiscountRule {
  @override
  double? apply(DiscountContext ctx) {
    if (ctx.customerType != 'regular' ||
        !ctx.isHoliday ||
        ctx.orderTotal <= 500) {
      return null;
    }
    return ctx.orderTotal * 0.1;
  }
}

/// Оркестратор применяет правила по очереди и берёт первое подходящее —
/// новое правило добавляется без изменения существующих (Open/Closed).
class DiscountCalculator {
  final List<DiscountRule> rules;
  DiscountCalculator(this.rules);

  double calculate(DiscountContext ctx) {
    for (final rule in rules) {
      final discount = rule.apply(ctx);
      if (discount != null) return discount;
    }
    return 0;
  }
}

void main() {
  final ctx = DiscountContext(
    customerType: 'vip',
    orderTotal: 1200,
    itemCount: 5,
    isHoliday: true,
    customerYears: 7,
  );

  print(
    'Спагетти-версия: ${calculateDiscountSpaghetti(ctx.customerType, ctx.orderTotal, ctx.itemCount, ctx.isHoliday, ctx.couponCode, ctx.customerYears)}',
  );

  final calculator = DiscountCalculator([
    VipHolidayCouponDiscount(),
    VipLoyaltyHolidayDiscount(),
    VipBulkOrderDiscount(),
    RegularHolidayDiscount(),
  ]);
  print('Рефакторинг: ${calculator.calculate(ctx)}');
  // Каждое правило теперь можно протестировать ИЗОЛИРОВАННО, не собирая
  // все 6 параметров функции сразу для каждого теста.
}
