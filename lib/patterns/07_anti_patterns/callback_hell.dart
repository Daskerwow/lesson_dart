import 'dart:async';

/// ============================================================================
/// АНТИПАТТЕРН: CALLBACK HELL / "Пирамида судьбы" (Pyramid of Doom)
/// ============================================================================
///
/// ПРОБЛЕМА:
/// Последовательные асинхронные операции реализуются через вложенные
/// callback-функции, каждая из которых вызывает следующую внутри себя.
/// В результате код "уезжает" вправо с каждым новым шагом, формируя
/// характерную "пирамиду" из вложенных скобок и колбэков.
///
/// ПОЧЕМУ ЭТО ПЛОХО:
/// - Читаемость катастрофически падает с ростом числа шагов — сложно
///   проследить порядок выполнения и понять, где и что обрабатывается.
/// - Обработка ошибок превращается в кошмар: нужно дублировать try/catch
///   или коллбэк ошибки на КАЖДОМ уровне вложенности.
/// - Трудно комбинировать операции (например, выполнить два запроса
///   параллельно и дождаться обоих) — колбэки плохо для этого приспособлены.
///
/// К СЧАСТЬЮ: в Dart эта проблема решена на уровне языка через async/await
/// и Future — они делают асинхронный код линейным и читаемым, как
/// синхронный. Практически нет причин писать callback-based код в Dart,
/// если только не приходится работать со старым callback-based API.

// --- Имитация "callback-based" API (как было бы в старом JS-стиле) ---
typedef ResultCallback<T> = void Function(T? result, Object? error);

void fetchUser(String userId, ResultCallback<Map<String, dynamic>> callback) {
  Future.delayed(const Duration(milliseconds: 50), () {
    callback({'id': userId, 'name': 'Иван'}, null);
  });
}

void fetchOrders(String userId, ResultCallback<List<String>> callback) {
  Future.delayed(const Duration(milliseconds: 50), () {
    callback(['order1', 'order2'], null);
  });
}

void fetchOrderDetails(
  String orderId,
  ResultCallback<Map<String, dynamic>> callback,
) {
  Future.delayed(const Duration(milliseconds: 50), () {
    callback({'id': orderId, 'total': 99.99}, null);
  });
}

void sendReceipt(String orderId, ResultCallback<bool> callback) {
  Future.delayed(const Duration(milliseconds: 50), () {
    callback(true, null);
  });
}

// ============================================================================
// ПЛОХО: "пирамида судьбы" — каждый следующий асинхронный шаг вложен
// внутрь предыдущего колбэка. Обработка ошибок дублируется на каждом уровне.
// ============================================================================
void processUserOrdersCallbackHell(String userId) {
  fetchUser(userId, (user, error) {
    if (error != null) {
      print('Ошибка получения пользователя: $error');
      return;
    }
    print('Пользователь получен: ${user!['name']}');
    fetchOrders(userId, (orders, error) {
      if (error != null) {
        print('Ошибка получения заказов: $error');
        return;
      }
      print('Заказов найдено: ${orders!.length}');
      fetchOrderDetails(orders.first, (details, error) {
        if (error != null) {
          print('Ошибка получения деталей заказа: $error');
          return;
        }
        print('Детали заказа: ${details!['total']}');
        sendReceipt(orders.first, (success, error) {
          if (error != null) {
            print('Ошибка отправки чека: $error');
            return;
          }
          print('Чек отправлен: $success');
          // ...и так далее — каждый новый шаг добавляет ещё один
          // уровень вложенности "вправо".
        });
      });
    });
  });
}

// ============================================================================
// РЕФАКТОРИНГ: те же самые callback-based функции, но обёрнутые в Future
// через Completer, и использованные с async/await — линейный, читаемый код
// с ОДНИМ местом обработки ошибок (try/catch).
// ============================================================================
Future<Map<String, dynamic>> fetchUserAsync(String userId) {
  final completer = Completer<Map<String, dynamic>>();
  fetchUser(userId, (result, error) {
    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete(result);
    }
  });
  return completer.future;
}

Future<List<String>> fetchOrdersAsync(String userId) {
  final completer = Completer<List<String>>();
  fetchOrders(userId, (result, error) {
    error != null ? completer.completeError(error) : completer.complete(result);
  });
  return completer.future;
}

Future<Map<String, dynamic>> fetchOrderDetailsAsync(String orderId) {
  final completer = Completer<Map<String, dynamic>>();
  fetchOrderDetails(orderId, (result, error) {
    error != null ? completer.completeError(error) : completer.complete(result);
  });
  return completer.future;
}

Future<bool> sendReceiptAsync(String orderId) {
  final completer = Completer<bool>();
  sendReceipt(orderId, (result, error) {
    error != null ? completer.completeError(error) : completer.complete(result);
  });
  return completer.future;
}

/// Линейный, читаемый асинхронный код — каждый шаг читается сверху вниз,
/// как обычный синхронный код, с ЕДИНОЙ обработкой ошибок через try/catch.
Future<void> processUserOrdersAsyncAwait(String userId) async {
  try {
    final user = await fetchUserAsync(userId);
    print('Пользователь получен: ${user['name']}');

    final orders = await fetchOrdersAsync(userId);
    print('Заказов найдено: ${orders.length}');

    final details = await fetchOrderDetailsAsync(orders.first);
    print('Детали заказа: ${details['total']}');

    final receiptSent = await sendReceiptAsync(orders.first);
    print('Чек отправлен: $receiptSent');
  } catch (e) {
    // ОДНО место для обработки ЛЮБОЙ ошибки на любом из шагов выше.
    print('Ошибка в цепочке обработки заказа: $e');
  }
}

void main() async {
  print('--- Callback Hell ---');
  processUserOrdersCallbackHell('user1');
  await Future.delayed(const Duration(milliseconds: 300));

  print('\n--- async/await (идиоматичный Dart) ---');
  await processUserOrdersAsyncAwait('user1');
}
