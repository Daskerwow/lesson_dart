/// ============================================================================
/// ПАТТЕРН: DEPENDENCY INJECTION (Внедрение зависимостей)
/// Категория: Корпоративный / Архитектурный принцип
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Класс не создаёт свои зависимости самостоятельно (через `new`/конструктор
/// внутри себя), а получает их ИЗВНЕ — через конструктор, сеттер или
/// параметр метода. Это инверсия управления (Inversion of Control):
/// управление созданием объектов передаётся внешнему коду (DI-контейнеру
/// или вручную собранному "composition root").
///
/// ПРЕИМУЩЕСТВА:
/// - Тестируемость: в тестах легко подставить mock/fake-реализацию.
/// - Слабая связанность: класс зависит от абстракции (интерфейса), а не
///   от конкретной реализации — это принцип D из SOLID (DIP).
/// - Явные зависимости: конструктор класса "документирует", что ему нужно
///   для работы, вместо скрытых обращений к глобальным Singleton'ам.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Практически везде в приложениях среднего и большого размера.
/// - В Dart/Flutter реализуется как вручную (constructor injection —
///   показано ниже), так и через DI-контейнеры (get_it, injectable, riverpod).
library;

/// Абстракция — от неё зависят потребители, а не от конкретной реализации.
abstract class EmailSender {
  Future<void> send(String to, String subject, String body);
}

abstract class Clock {
  DateTime now();
}

/// Конкретные реализации — детали, которые можно подменить, не трогая
/// код, который их использует.
class SmtpEmailSender implements EmailSender {
  @override
  Future<void> send(String to, String subject, String body) async {
    print('[SMTP] Письмо "$subject" отправлено на $to');
  }
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// Fake-реализации для тестов — не делают реальных сетевых вызовов и
/// дают детерминированное время, что критично для воспроизводимых тестов.
class FakeEmailSender implements EmailSender {
  final List<String> sentEmails = [];
  @override
  Future<void> send(String to, String subject, String body) async {
    sentEmails.add('$to: $subject');
  }
}

class FixedClock implements Clock {
  final DateTime fixedTime;
  const FixedClock(this.fixedTime);

  @override
  DateTime now() => fixedTime;
}

/// БЕЗ DI (антипример, для сравнения) — класс сам создаёт зависимости
/// внутри себя через `new`. Это делает его негибким и нетестируемым:
/// нельзя подменить SmtpEmailSender на fake без изменения кода класса.
class BadPasswordResetService {
  final _emailSender = SmtpEmailSender(); // жёстко "вшитая" зависимость!
  final _clock = SystemClock(); // и эта тоже!

  Future<void> requestReset(String email) async {
    final expiresAt = _clock.now().add(const Duration(hours: 1));
    await _emailSender.send(
      email,
      'Сброс пароля',
      'Ссылка действительна до $expiresAt',
    );
  }
}

/// С DI (правильный подход) — зависимости передаются через конструктор.
/// Класс не знает, КАКАЯ именно реализация EmailSender/Clock используется —
/// только то, что она удовлетворяет контракту интерфейса.
class GoodPasswordResetService {
  final EmailSender emailSender;
  final Clock clock;

  // Constructor Injection — самый распространённый и рекомендуемый способ.
  GoodPasswordResetService({required this.emailSender, required this.clock});

  Future<void> requestReset(String email) async {
    final expiresAt = clock.now().add(const Duration(hours: 1));
    await emailSender.send(
      email,
      'Сброс пароля',
      'Ссылка действительна до $expiresAt',
    );
  }
}

/// Простейший "composition root" / DI-контейнер вручную — единственное
/// место в приложении, где происходит "сборка" графа зависимостей.
/// В реальном проекте эту роль обычно играет get_it или подобный пакет.
class AppContainer {
  late final EmailSender emailSender;
  late final Clock clock;
  late final GoodPasswordResetService passwordResetService;

  AppContainer({bool useFakes = false}) {
    emailSender = useFakes ? FakeEmailSender() : SmtpEmailSender();
    clock = useFakes ? FixedClock(DateTime(2026, 1, 1)) : SystemClock();
    passwordResetService = GoodPasswordResetService(
      emailSender: emailSender,
      clock: clock,
    );
  }
}

void main() async {
  print('--- Продакшен-конфигурация ---');
  final prodContainer = AppContainer(useFakes: false);
  await prodContainer.passwordResetService.requestReset('user@example.com');

  print('\n--- Тестовая конфигурация (fake-зависимости) ---');
  final testContainer = AppContainer(useFakes: true);
  await testContainer.passwordResetService.requestReset('test@example.com');

  // В юнит-тесте так же легко проверить, что письмо действительно
  // "отправлено", заглянув в fake-реализацию:
  final fakeSender = testContainer.emailSender as FakeEmailSender;
  print('Отправленные тестовые письма: ${fakeSender.sentEmails}');
}
