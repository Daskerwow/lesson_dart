/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: MVVM (Model-View-ViewModel)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// ViewModel предоставляет данные и команды для View через механизм
/// привязки данных (data binding) — обычно реактивный (Stream/ChangeNotifier
/// в Dart/Flutter). В отличие от MVP, ViewModel не хранит прямую ссылку
/// на View и не вызывает её методы — View сама подписывается на потоки/
/// уведомления ViewModel. Это делает ViewModel полностью независимой от UI.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Стандартная архитектура для Flutter-приложений (ViewModel часто
///   реализуется через ChangeNotifier + Provider, либо через Stream/Riverpod).
/// - Когда нужна максимальная тестируемость логики экрана без UI И
///   при этом не хочется вручную дёргать методы View, как в MVP —
///   View сама реагирует на изменения состояния.
library;

import 'dart:async';

// --- MODEL ---
class Product {
  const Product(this.id, this.name, this.price);

  final String id;
  final String name;
  final double price;
}

class ProductRepository {
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      Product('1', 'Клавиатура', 49.99),
      Product('2', 'Мышь', 19.99),
      Product('3', 'Монитор', 299.99),
    ];
  }
}

/// Неизменяемое состояние экрана — ViewModel всегда испускает НОВЫЙ объект
/// состояния целиком (иммутабельность упрощает отладку и предотвращает
/// рассинхронизацию UI).
class ProductListState {
  final bool isLoading;
  final List<Product> products;
  final String? errorMessage;
  final double cartTotal;

  const ProductListState({
    this.isLoading = false,
    this.products = const [],
    this.errorMessage,
    this.cartTotal = 0,
  });

  ProductListState copyWith({
    bool? isLoading,
    List<Product>? products,
    String? errorMessage,
    double? cartTotal,
  }) {
    return ProductListState(
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      errorMessage: errorMessage,
      cartTotal: cartTotal ?? this.cartTotal,
    );
  }
}

/// VIEWMODEL: экспортирует поток состояния (Stream<ProductListState>).
/// View подписывается на этот поток и перерисовывается при каждом новом
/// значении — ViewModel НИЧЕГО не знает о View, только публикует состояние.
class ProductListViewModel {
  final ProductRepository _repository;
  final _stateController = StreamController<ProductListState>.broadcast();
  ProductListState _state = const ProductListState();
  final Set<String> _cartIds = {};

  ProductListViewModel(this._repository) {
    _emit(_state);
  }

  Stream<ProductListState> get state$ => _stateController.stream;

  void _emit(ProductListState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// "Команда" от View — ViewModel обрабатывает намерение пользователя
  /// и публикует новое состояние; View просто вызывает метод и ждёт
  /// обновления через state$.
  Future<void> loadProducts() async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final products = await _repository.fetchProducts();
      _emit(_state.copyWith(isLoading: false, products: products));
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: 'Не удалось загрузить товары',
        ),
      );
    }
  }

  void toggleInCart(Product product) {
    if (_cartIds.contains(product.id)) {
      _cartIds.remove(product.id);
    } else {
      _cartIds.add(product.id);
    }
    final total = _state.products
        .where((p) => _cartIds.contains(p.id))
        .fold(0.0, (sum, p) => sum + p.price);
    _emit(_state.copyWith(cartTotal: total));
  }

  void dispose() => _stateController.close();
}

// --- VIEW (в реальном Flutter это StreamBuilder + Widget) ---
void bindView(ProductListViewModel viewModel) {
  viewModel.state$.listen((state) {
    // "Реактивная перерисовка" — вызывается автоматически при каждом
    // новом состоянии, View не дёргает ViewModel напрямую для чтения.
    if (state.isLoading) {
      print('[View] Загрузка...');
      return;
    }
    if (state.errorMessage != null) {
      print('[View] Ошибка: ${state.errorMessage}');
      return;
    }
    print('[View] Товары: ${state.products.map((p) => p.name).join(', ')}');
    print('[View] Сумма корзины: \$${state.cartTotal.toStringAsFixed(2)}');
  });
}

void main() async {
  final viewModel = ProductListViewModel(ProductRepository());
  bindView(viewModel);

  await viewModel.loadProducts();
  // Даём event loop обработать поток перед следующими действиями.
  await Future.delayed(const Duration(milliseconds: 10));

  viewModel.toggleInCart(Product('1', 'Клавиатура', 49.99));
  await Future.delayed(const Duration(milliseconds: 10));

  viewModel.toggleInCart(Product('3', 'Монитор', 299.99));
  await Future.delayed(const Duration(milliseconds: 10));

  viewModel.dispose();
}
