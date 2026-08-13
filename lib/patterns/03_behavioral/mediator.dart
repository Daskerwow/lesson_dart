/// ============================================================================
/// ПАТТЕРН: MEDIATOR (Посредник)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет объект, инкапсулирующий взаимодействие множества объектов.
/// Устраняет прямые связи "все со всеми" (N^2 зависимостей), заменяя их
/// связями "каждый с посредником" (N зависимостей), что снижает связность.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - UI-формы, где изменение одного поля должно влиять на другие
///   (например, выбор страны меняет список доступных городов и валюту).
/// - Чат-комнаты: участники не знают друг о друге напрямую, а общаются
///   через посредника (комнату).
/// - Управление воздушным движением — самолёты не общаются напрямую
///   друг с другом, а координируются через диспетчерскую вышку.
library;

/// Интерфейс посредника.
abstract class ChatMediator {
  void sendMessage(String message, ChatUser sender);
  void addUser(ChatUser user);
}

/// Коллеги (Colleagues) — знают только о посреднике, но не друг о друге.
abstract class ChatUser {
  final String name;

  /// Посредник
  final ChatMediator mediator;
  const ChatUser(this.name, this.mediator);

  void send(String message) => mediator.sendMessage(message, this);
  void receive(String message, String fromUser);
}

class RegularUser extends ChatUser {
  const RegularUser(super.name, super.mediator);

  /// send() не переопределяем так как он реализован в ChatUser

  @override
  void receive(String message, String fromUser) {
    print('$name получил от $fromUser: "$message"');
  }
}

/// Модератор — особый пользователь, реагирующий на определённые слова.
/// Демонстрирует, что посредник может содержать дополнительную бизнес-логику
/// координации, недоступную обычным участникам.
class ModeratorUser extends ChatUser {
  const ModeratorUser(super.name, super.mediator);

  /// send() не переопределяем так как он реализован

  @override
  void receive(String message, String fromUser) {
    print('$name (модератор) получил от $fromUser: "$message"');
    if (message.contains('спам')) {
      print(
        '$name: предупреждение пользователю $fromUser за нарушение правил!',
      );
    }
  }
}

/// КОНКРЕТНЫЙ ПОСРЕДНИК: чат-комната. Вся логика маршрутизации сообщений
/// централизована здесь — участники ничего не знают друг о друге.
class ChatRoom implements ChatMediator {
  final List<ChatUser> _roomUsers = [];

  @override
  void addUser(ChatUser user) => _roomUsers.add(user);

  @override
  void sendMessage(String message, ChatUser sender) {
    for (final user in _roomUsers) {
      // Отправитель не получает собственное сообщение.
      if (user != sender) {
        user.receive(message, sender.name);
      }
    }
  }
}

void main() {
  final chatRoom = ChatRoom();

  final alice = RegularUser('Алиса', chatRoom);
  final bob = RegularUser('Боб', chatRoom);
  final moderator = ModeratorUser('Модератор_Ирина', chatRoom);

  chatRoom.addUser(alice);
  chatRoom.addUser(bob);
  chatRoom.addUser(moderator);

  // Алиса не знает ни о Бобе, ни о модераторе напрямую —
  // всё взаимодействие идёт через ChatRoom (посредника).
  alice.send('Всем привет!');
  print('---');
  bob.send('Купите наш супер-товар, это не спам, честно!');
  moderator.send('Суки не пишите спам!');
}
