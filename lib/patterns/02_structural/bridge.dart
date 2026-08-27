/// ============================================================================
/// ПАТТЕРН: BRIDGE (Мост)
/// Категория: Структурный (Structural) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Разделяет абстракцию и реализацию так, чтобы они могли изменяться
/// независимо друг от друга. Вместо одной большой иерархии наследования
/// "N абстракций x M реализаций" (что даёт N*M классов), Bridge оставляет
/// две независимые иерархии, соединённые композицией.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Когда нужно избежать "взрыва классов" при комбинации нескольких
///   измерений изменчивости (например: тип уведомления x канал доставки).
/// - Продакшен-кейс: система уведомлений, где "что отправлять"
///   (Уведомление: обычное/срочное/промо) должно комбинироваться с
///   "как отправлять" (Канал: Email/SMS/Push) — без Bridge пришлось бы
///   создавать EmailUrgentNotification, SmsUrgentNotification и т.д.
///
library;

import 'package:meta/meta.dart';

/// РЕАЛИЗАЦИЯ (Implementor) — интерфейс канала доставки сообщений.
abstract class const MessageChannel() {
  Future<void> send(String recipient, String subject, String body);
}

/// Реализация Транспорта Сообщений
class const EmailChannel() implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('EMAIL -> $recipient\nТема: $subject\n$body\n');
  }
}

class const SmsChannel() implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('SMS -> $recipient\n$subject: $body\n');
  }
}

class const PushChannel() implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('PUSH -> device:$recipient\n$subject | $body\n');
  }
}

/// АБСТРАКЦИЯ (Abstraction) — типы уведомлений.
/// Хранит ССЫЛКУ на реализацию (MessageChannel) вместо наследования от конкретного канала —
/// это и есть "мост" между двумя иерархиями.
/// channel -> это Мост (связь) через интерфейс
///
/// А это абстрактный класс а не интерфейс что бы мы могли наследоваться от него
@immutable
abstract class const Notification(final MessageChannel channel) {
  Future<void> notify(String recipient, String message);
}

/// Здесь мы наследуемся а не реализуем интерфейс
@immutable
class const RegularNotification(super.channel) extends Notification {
  @override
  Future<void> notify(String recipient, String message) =>
      channel.send(recipient, 'Уведомление', message);
}

@immutable
class const UrgentNotification(super.channel) extends Notification {
  @override
  Future<void> notify(String recipient, String message) =>
      channel.send(recipient, 'СРОЧНО', message.toUpperCase());
}

@immutable
class const PromoNotification(super.channel, final String promoCode)
    extends Notification {
  @override
  Future<void> notify(String recipient, String message) => channel.send(
    recipient,
    'Специальное предложение',
    '$message Промокод: $promoCode',
  );
}

void main() async {
  final urgentBySms = UrgentNotification(SmsChannel());
  await urgentBySms.notify('+79991234567', 'Ваш аккаунт скомпрометирован');

  final promoByEmail = PromoNotification(EmailChannel(), 'SUMMER2026');
  await promoByEmail.notify('user@example.com', 'Скидка 20% только сегодня!');

  final regularByPush = RegularNotification(PushChannel());
  await regularByPush.notify('device_token_abc', 'Ваш заказ готов к выдаче');
}
