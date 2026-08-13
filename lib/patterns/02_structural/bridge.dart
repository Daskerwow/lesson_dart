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

/// РЕАЛИЗАЦИЯ (Implementor) — интерфейс канала доставки сообщений.
abstract class MessageChannel {
  Future<void> send(String recipient, String subject, String body);
}

/// Реализация Транспорта Сообщений
class EmailChannel implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('EMAIL -> $recipient\nТема: $subject\n$body\n');
  }
}

class SmsChannel implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('SMS -> $recipient\n$subject: $body\n');
  }
}

class PushChannel implements MessageChannel {
  @override
  Future<void> send(String recipient, String subject, String body) async {
    print('PUSH -> device:$recipient\n$subject | $body\n');
  }
}

/// АБСТРАКЦИЯ (Abstraction) — типы уведомлений.
/// Хранит ССЫЛКУ на реализацию (MessageChannel) вместо наследования от конкретного канала —
/// это и есть "мост" между двумя иерархиями.
abstract class Notification {
  /// channel -> это Мост (связь) через интерфейс
  final MessageChannel channel;
  const Notification(this.channel);

  Future<void> notify(String recipient, String message);
}

class RegularNotification extends Notification {
  const RegularNotification(super.channel);

  @override
  Future<void> notify(String recipient, String message) =>
      channel.send(recipient, 'Уведомление', message);
}

class UrgentNotification extends Notification {
  const UrgentNotification(super.channel);

  @override
  Future<void> notify(String recipient, String message) =>
      channel.send(recipient, 'СРОЧНО', message.toUpperCase());
}

class PromoNotification extends Notification {
  final String promoCode;
  const PromoNotification(super.channel, this.promoCode);

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
