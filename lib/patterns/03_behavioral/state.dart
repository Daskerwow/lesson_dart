/// ============================================================================
/// ПАТТЕРН: STATE (Состояние)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Позволяет объекту изменять своё поведение в зависимости от внутреннего
/// состояния — так, будто объект сменил класс. Заменяет длинные цепочки
/// switch/if по полю "статус" на полиморфизм: каждое состояние — свой класс.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Жизненный цикл заказа (создан -> оплачен -> отправлен -> доставлен ->
///   отменён), где в каждом статусе доступны разные действия.
/// - Конечные автоматы (state machines) любого рода: медиаплеер
///   (играет/пауза/стоп), состояние сетевого соединения, workflow-движки.
library;

/// Контекст — заказ, который делегирует поведение текущему состоянию.
class Order {
  OrderState _state = CreatedState();
  final List<String> _log = [];

  void transitionTo(OrderState newState) {
    _log.add('${_state.runtimeType} -> ${newState.runtimeType}');
    _state = newState;
  }

  // Публичные операции делегируются текущему состоянию — Order сам
  // не содержит бизнес-логики переходов, только хранит текущее состояние.
  void pay() => _state.pay(this);
  void ship() => _state.ship(this);
  void deliver() => _state.deliver(this);
  void cancel() => _state.cancel(this);

  String get statusName => _state.runtimeType.toString();
  List<String> get transitionLog => List.unmodifiable(_log);
}

/// Абстрактное состояние объявляет все возможные операции. По умолчанию
/// каждая операция в конкретном состоянии либо выполняет переход, либо
/// сообщает, что действие недопустимо в этом состоянии.
abstract class OrderState {
  void pay(Order order) => _invalid('оплатить');
  void ship(Order order) => _invalid('отправить');
  void deliver(Order order) => _invalid('доставить');
  void cancel(Order order) => _invalid('отменить');

  void _invalid(String action) {
    print('Ошибка: нельзя "$action" заказ в состоянии $runtimeType');
  }
}

class CreatedState extends OrderState {
  @override
  void pay(Order order) {
    print('Заказ оплачен');
    order.transitionTo(PaidState());
  }

  @override
  void cancel(Order order) {
    print('Заказ отменён (был не оплачен)');
    order.transitionTo(CancelledState());
  }
}

class PaidState extends OrderState {
  @override
  void ship(Order order) {
    print('Заказ передан в доставку');
    order.transitionTo(ShippedState());
  }

  @override
  void cancel(Order order) {
    print('Заказ отменён, инициирован возврат средств');
    order.transitionTo(CancelledState());
  }
}

class ShippedState extends OrderState {
  @override
  void deliver(Order order) {
    print('Заказ доставлен получателю');
    order.transitionTo(DeliveredState());
  }

  // Обратите внимание: cancel() здесь не переопределён — отменить
  // уже отправленный заказ нельзя, сработает "недопустимое действие"
  // из базового класса. Это и есть суть паттерна: набор допустимых
  // операций определяется КЛАССОМ состояния, а не условиями внутри Order.
}

class DeliveredState extends OrderState {
  // Финальное состояние — все операции недопустимы (используется поведение
  // по умолчанию из базового класса).
}

class CancelledState extends OrderState {
  // Финальное состояние.
}

void main() {
  final order = Order();
  print('Начальный статус: ${order.statusName}');

  order.ship(); // недопустимо: заказ ещё не оплачен
  order.pay();
  print('Статус: ${order.statusName}');

  order.ship();
  print('Статус: ${order.statusName}');

  order.cancel(); // недопустимо: заказ уже отправлен
  order.deliver();
  print('Статус: ${order.statusName}');

  print('\nИстория переходов:');
  order.transitionLog.forEach(print);
}
