/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: REDUX / FLUX
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Централизует ВСЁ состояние приложения в едином неизменяемом Store.
/// Единственный способ изменить состояние — отправить (dispatch) объект
/// Action, который обрабатывается чистой функцией Reducer(state, action) ->
/// newState. Однонаправленный поток данных: Action -> Reducer -> new State
/// -> UI, без исключений и побочных обходов.
///
/// ОТЛИЧИЕ ОТ BLoC: Redux — ОДИН глобальный Store для всего приложения
/// с ЧИСТЫМИ функциями-редьюсерами (без побочных эффектов внутри); BLoC —
/// обычно множество локальных Bloc/Cubit на разные фичи/экраны, допускающих
/// side-эффекты внутри обработки событий.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Приложения с сильно взаимосвязанным глобальным состоянием (например,
///   состояние сессии, корзины, темы, влияющие на множество экранов).
/// - Когда критична предсказуемость (чистые редьюсеры легко тестировать)
///   и time-travel debugging / undo глобального состояния.
library;

import 'dart:async';

// --- STATE: единое неизменяемое состояние всего приложения ---
class AppState {
  final int cartItemCount;
  final double cartTotal;
  final bool isDarkTheme;
  final String? currentUserId;

  const AppState({
    this.cartItemCount = 0,
    this.cartTotal = 0,
    this.isDarkTheme = false,
    this.currentUserId,
  });

  AppState copyWith({
    int? cartItemCount,
    double? cartTotal,
    bool? isDarkTheme,
    String? currentUserId,
  }) {
    return AppState(
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotal: cartTotal ?? this.cartTotal,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  String toString() =>
      'AppState(cart: $cartItemCount шт. на \$$cartTotal, '
      'theme: ${isDarkTheme ? "dark" : "light"}, user: $currentUserId)';
}

// --- ACTIONS: неизменяемые объекты, описывающие "что произошло" ---
abstract class Action {}

class AddToCartAction extends Action {
  final double itemPrice;
  AddToCartAction(this.itemPrice);
}

class ClearCartAction extends Action {}

class ToggleThemeAction extends Action {}

class LoginAction extends Action {
  final String userId;
  LoginAction(this.userId);
}

// --- REDUCER: ЧИСТАЯ функция (state, action) -> new state.
// Никаких side-эффектов (сеть, БД, print) внутри — только вычисление
// нового состояния. Это гарантирует предсказуемость и тестируемость.
AppState appReducer(AppState state, Action action) {
  return switch (action) {
    AddToCartAction(itemPrice: final price) => state.copyWith(
      cartItemCount: state.cartItemCount + 1,
      cartTotal: state.cartTotal + price,
    ),
    ClearCartAction() => state.copyWith(cartItemCount: 0, cartTotal: 0),
    ToggleThemeAction() => state.copyWith(isDarkTheme: !state.isDarkTheme),
    LoginAction(userId: final id) => state.copyWith(currentUserId: id),
    _ => state,
  };
}

/// STORE: единственный держатель состояния приложения. Предоставляет
/// dispatch() для отправки действий и stream состояния для подписки UI.
class Store<S> {
  S _state;
  final S Function(S state, Action action) _reducer;
  final _controller = StreamController<S>.broadcast();
  final List<Middleware<S>> _middlewares;

  Store(this._reducer, S initialState, {List<Middleware<S>>? middlewares})
    : _state = initialState,
      _middlewares = middlewares ?? [] {
    _controller.add(_state);
  }

  S get state => _state;
  Stream<S> get stream => _controller.stream;

  void dispatch(Action action) {
    // Middleware-цепочка выполняется ДО того, как action дойдёт до reducer —
    // удобно для логирования, аналитики, асинхронных side-эффектов.
    for (final middleware in _middlewares) {
      middleware(this, action);
    }
    _state = _reducer(_state, action);
    _controller.add(_state);
  }

  void dispose() => _controller.close();
}

/// Middleware — точка расширения без изменения чистоты reducer'а.
typedef Middleware<S> = void Function(Store<S> store, Action action);

/// Пример middleware логирования — типичный продакшен-кейс для Redux.
void loggingMiddleware<S>(Store<S> store, Action action) {
  print('[Redux LOG] Action: ${action.runtimeType}, State до: ${store.state}');
}

void main() async {
  final store = Store<AppState>(
    appReducer,
    const AppState(),
    middlewares: [loggingMiddleware],
  );

  store.stream.listen((state) => print('[UI] Новое состояние: $state'));

  store.dispatch(LoginAction('user_42'));
  store.dispatch(AddToCartAction(29.99));
  store.dispatch(AddToCartAction(15.50));
  store.dispatch(ToggleThemeAction());
  store.dispatch(ClearCartAction());

  await Future.delayed(const Duration(milliseconds: 10));
  store.dispose();
}
