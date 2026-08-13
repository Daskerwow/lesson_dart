/// ============================================================================
/// ПАТТЕРН: OBSERVER (Наблюдатель)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет зависимость "один-ко-многим" между объектами так, что при
/// изменении состояния одного объекта (Subject/Publisher) все зависимые
/// от него объекты (Observers/Subscribers) уведомляются автоматически.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Реактивные UI-фреймворки (ChangeNotifier в Flutter — прямая реализация
///   этого паттерна), event-driven архитектуры, системы уведомлений.
/// - В Dart идиоматичная реализация "потокового" Observer — через Stream
///   и StreamController, что и показано ниже как второй пример.
library;

import 'dart:async';

// -----------------------------------------------------------------------
// ПРИМЕР 1: классический GoF Observer — вручную, без Stream API.
// Полезно понимать "механику" паттерна до того, как перейти к
// идиоматичному Stream-варианту ниже.
// -----------------------------------------------------------------------

abstract class StockObserver {
  void onPriceChanged(String ticker, double oldPrice, double newPrice);
}

class StockSubject {
  final List<StockObserver> _observers = [];
  final Map<String, double> _prices = {};

  void subscribe(StockObserver observer) => _observers.add(observer);
  void unsubscribe(StockObserver observer) => _observers.remove(observer);

  void updatePrice(String ticker, double newPrice) {
    final oldPrice = _prices[ticker] ?? newPrice;
    _prices[ticker] = newPrice;
    // Уведомляем всех подписчиков об изменении — Subject не знает,
    // сколько их и что именно они делают с этой информацией.
    for (final observer in List.of(_observers)) {
      observer.onPriceChanged(ticker, oldPrice, newPrice);
    }
  }
}

class PriceAlertObserver implements StockObserver {
  final double threshold;
  PriceAlertObserver(this.threshold);

  @override
  void onPriceChanged(String ticker, double oldPrice, double newPrice) {
    final change = ((newPrice - oldPrice) / oldPrice * 100).abs();
    if (change >= threshold) {
      print(
        '[Alert] $ticker изменился на ${change.toStringAsFixed(1)}%! '
        '($oldPrice -> $newPrice)',
      );
    }
  }
}

class PortfolioObserver implements StockObserver {
  final Map<String, double> holdings; // ticker -> кол-во акций
  PortfolioObserver(this.holdings);

  @override
  void onPriceChanged(String ticker, double oldPrice, double newPrice) {
    final qty = holdings[ticker];
    if (qty == null) return;
    final delta = (newPrice - oldPrice) * qty;
    print(
      '[Portfolio] Изменение стоимости позиции $ticker: '
      '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}\$',
    );
  }
}

// -----------------------------------------------------------------------
// ПРИМЕР 2: идиоматичный Dart-подход через Stream — то, как Observer
// реализуется в реальных продакшен-проектах на Dart/Flutter.
// -----------------------------------------------------------------------

class ReactiveStockTicker {
  final StreamController<MapEntry<String, double>> _controller =
      StreamController.broadcast();

  /// Публичный Stream — любое число подписчиков может слушать изменения,
  /// не влияя друг на друга (broadcast-режим).
  Stream<MapEntry<String, double>> get priceUpdates => _controller.stream;

  void updatePrice(String ticker, double price) {
    _controller.add(MapEntry(ticker, price));
  }

  void dispose() => _controller.close();
}

void main() {
  print('=== Классический Observer ===');
  final subject = StockSubject();
  subject.subscribe(PriceAlertObserver(5.0));
  subject.subscribe(PortfolioObserver({'AAPL': 10, 'GOOG': 5}));

  subject.updatePrice('AAPL', 150.0);
  subject.updatePrice('AAPL', 160.0); // рост >5% -> сработает алерт

  print('\n=== Реактивный Observer через Stream ===');
  final ticker = ReactiveStockTicker();
  final subscription = ticker.priceUpdates.listen((update) {
    print('[Stream Subscriber] ${update.key} = ${update.value}');
  });

  ticker.updatePrice('TSLA', 700.0);
  ticker.updatePrice('TSLA', 715.0);

  subscription.cancel();
  ticker.dispose();
}
