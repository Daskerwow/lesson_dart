import 'dart:async';

void getDataFromCallback(Function(String) onSucces, Function(Object) onError) =>
    Future.delayed(const Duration(seconds: 2), () => onSucces('Все ок'));

Future<String> getData() {
  /// Создаем объект для управления
  final completer = Completer<String>();

  getDataFromCallback(
    /// Завершить с результатом
    (res) => completer.complete(res),

    /// Завершить с ошибкой
    (err) => completer.completeError(err),
  );

  /// Вернуть Future которым мы управляем в функции getDataFromCallback
  /// при помощи complete() -> Ok и completeError() Err
  return completer.future;
}

/// Хороший пример использования синхронного коплитера
Future<T> any<T>(Iterable<Future<T>> futures) {
  var completer = Completer<T>.sync();

  void onValue(T value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void onError(Object error, StackTrace stack) {
    if (!completer.isCompleted) completer.completeError(error, stack);
  }

  /// Как только первый из асинхронных объектов станет в состояние (Завершен)
  /// completer сработает и мы получим первый выполненный асинхронный результат
  for (var future in futures) {
    future.then(onValue, onError: onError);
  }

  return completer.future;
}

void main() async {
  final result = await getData();

  print(result);
}
