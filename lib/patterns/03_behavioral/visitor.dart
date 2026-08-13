/// ============================================================================
/// ПАТТЕРН: VISITOR (Посетитель)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет добавлять новые операции над объектами существующей иерархии
/// классов, не изменяя сами классы. Реализуется через технику "двойной
/// диспетчеризации" (double dispatch): элемент вызывает visit-метод
/// посетителя, передавая себя (this), а конкретный тип элемента определяет,
/// какая перегрузка visit() будет вызвана.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Когда структура объектов (например, AST — абстрактное синтаксическое
///   дерево) стабильна, но над ней часто нужно выполнять НОВЫЕ операции
///   (подсчёт стоимости, экспорт в разные форматы, валидация, оптимизация).
/// - Обход разнородного дерева документа (HTML/XML) с разными операциями:
///   рендеринг, подсчёт слов, проверка орфографии — без раздувания самих
///   классов узлов документа этой логикой.
///
/// ВАЖНО: если иерархия классов элементов часто меняется (добавляются новые
/// типы), Visitor становится неудобным — придётся обновлять ВСЕХ посетителей.
/// Паттерн хорош, когда стабильна структура, а не операции над ней.
library;

/// Элементы иерархии — товары интернет-магазина разных типов.
abstract class Product {
  /// Метод accept — точка входа "двойной диспетчеризации": элемент сам
  /// решает, какой метод посетителя вызвать, основываясь на своём типе.
  T accept<T>(ProductVisitor<T> visitor);
}

class Book extends Product {
  final String title;
  final double price;
  final double weightKg;
  Book(this.title, this.price, this.weightKg);

  @override
  T accept<T>(ProductVisitor<T> visitor) => visitor.visitBook(this);
}

class Electronics extends Product {
  final String name;
  final double price;
  final int warrantyMonths;
  Electronics(this.name, this.price, this.warrantyMonths);

  @override
  T accept<T>(ProductVisitor<T> visitor) => visitor.visitElectronics(this);
}

class Groceries extends Product {
  final String name;
  final double price;
  final DateTime expiryDate;
  Groceries(this.name, this.price, this.expiryDate);

  @override
  T accept<T>(ProductVisitor<T> visitor) => visitor.visitGroceries(this);
}

/// Абстрактный посетитель объявляет visit-метод для КАЖДОГО конкретного
/// типа элемента иерархии.
abstract class ProductVisitor<T> {
  T visitBook(Book book);
  T visitElectronics(Electronics electronics);
  T visitGroceries(Groceries groceries);
}

/// Конкретный посетитель №1: расчёт стоимости доставки (разная логика
/// для разных типов товаров — книги дешевле, электроника застрахована,
/// продукты требуют охлаждённой доставки).
class ShippingCostVisitor implements ProductVisitor<double> {
  @override
  double visitBook(Book book) => book.weightKg * 0.5;

  @override
  double visitElectronics(Electronics electronics) =>
      15.0 + electronics.price * 0.02; // + страховка

  @override
  double visitGroceries(Groceries groceries) => 8.0; // фикс. охлаждённая доставка
}

/// Конкретный посетитель №2: генерация текстового описания для каталога —
/// СОВЕРШЕННО ДРУГАЯ операция над той же иерархией, добавленная без
/// изменения классов Book/Electronics/Groceries.
class CatalogDescriptionVisitor implements ProductVisitor<String> {
  @override
  String visitBook(Book book) => '📖 "${book.title}" — \$${book.price}';

  @override
  String visitElectronics(Electronics electronics) =>
      '💻 ${electronics.name} — \$${electronics.price} '
      '(гарантия ${electronics.warrantyMonths} мес.)';

  @override
  String visitGroceries(Groceries groceries) =>
      '🥦 ${groceries.name} — \$${groceries.price} '
      '(годен до ${groceries.expiryDate.toIso8601String().split('T').first})';
}

void main() {
  final products = <Product>[
    Book('Чистый код', 25.0, 0.6),
    Electronics('Ноутбук', 999.0, 24),
    Groceries('Молоко', 2.5, DateTime(2026, 8, 1)),
  ];

  final shippingVisitor = ShippingCostVisitor();
  final catalogVisitor = CatalogDescriptionVisitor();

  double totalShipping = 0;
  for (final product in products) {
    // accept() сам выберет нужный метод visit* в зависимости от типа.
    print(product.accept(catalogVisitor));
    final cost = product.accept(shippingVisitor);
    totalShipping += cost;
    print('  Доставка: \$${cost.toStringAsFixed(2)}');
  }

  print('\nИтого доставка: \$${totalShipping.toStringAsFixed(2)}');
}
