/// ============================================================================
/// ПАТТЕРН: FACTORY METHOD (Фабричный метод)
/// Категория: Порождающий (Creational) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет интерфейс для создания объекта, но оставляет подклассам решение
/// о том, какой класс инстанцировать. Позволяет классу делегировать создание
/// экземпляров своим наследникам.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Когда заранее неизвестно, объекты каких именно типов нужно создавать.
/// - Когда логика создания объекта сложна и должна быть инкапсулирована
///   отдельно от бизнес-логики, использующей объект.
/// - Классический продакшен-кейс: парсинг платёжных провайдеров, драйверы
///   БД, парсеры разных форматов файлов (JSON/XML/CSV) по расширению.
library;

/// Транспортный объект
class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;

  const PaymentResult(this.success, this.transactionId, this.message);

  @override
  String toString() =>
      'PaymentResult(success: $success, id: $transactionId, "$message")';
}

/// Общий интерфейс продукта — все "платёжные методы" умеют обрабатывать платёж.
abstract class PaymentProcessor {
  Future<PaymentResult> pay(double amount, String currency);
}

/// Конкретный продукт: оплата картой.
class CreditCardProcessor implements PaymentProcessor {
  final String cardNumberMasked;
  const CreditCardProcessor(this.cardNumberMasked);

  @override
  Future<PaymentResult> pay(double amount, String currency) async {
    // В реальном проекте здесь был бы вызов Stripe/PayPal SDK и т.п.
    await Future.delayed(const Duration(milliseconds: 100));
    return PaymentResult(
      true,
      'CC-${DateTime.now().millisecondsSinceEpoch}',
      'Списано $amount $currency с карты $cardNumberMasked',
    );
  }
}

/// Конкретный продукт: оплата криптовалютой.
class CryptoProcessor implements PaymentProcessor {
  final String walletAddress;
  const CryptoProcessor(this.walletAddress);

  @override
  Future<PaymentResult> pay(double amount, String currency) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return PaymentResult(
      true,
      'CRYPTO-${DateTime.now().millisecondsSinceEpoch}',
      'Отправлено $amount $currency на кошелёк $walletAddress',
    );
  }
}

/// Конкретный продукт: банковский перевод.
class BankTransferProcessor implements PaymentProcessor {
  final String iban;
  const BankTransferProcessor(this.iban);

  @override
  Future<PaymentResult> pay(double amount, String currency) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return PaymentResult(
      true,
      'IBAN-${DateTime.now().millisecondsSinceEpoch}',
      'Перевод $amount $currency на счёт $iban',
    );
  }
}

/// АБСТРАКТНЫЙ СОЗДАТЕЛЬ (Creator).
/// Объявляет фабричный метод `createProcessor`, который подклассы обязаны
/// реализовать. Сам Creator не знает конкретных классов продуктов —
/// он оперирует только абстракцией PaymentProcessor.
abstract class PaymentGatewayCreator {
  const PaymentGatewayCreator();

  /// Фабричный метод — точка расширения для наследников.
  PaymentProcessor createProcessor();

  /// Шаблон использования продукта: Creator использует то, что создаёт
  /// фабричный метод, не зная конкретного класса.
  Future<PaymentResult> processPayment(double amount, String currency) async {
    final processor = createProcessor();
    return processor.pay(amount, currency);
  }
}

class CreditCardGateway extends PaymentGatewayCreator {
  final String maskedCard;

  const CreditCardGateway(this.maskedCard);

  @override
  PaymentProcessor createProcessor() => CreditCardProcessor(maskedCard);
}

class CryptoGateway extends PaymentGatewayCreator {
  final String wallet;

  const CryptoGateway(this.wallet);

  @override
  PaymentProcessor createProcessor() => CryptoProcessor(wallet);
}

class BankTransferGateway extends PaymentGatewayCreator {
  final String iban;

  const BankTransferGateway(this.iban);

  @override
  PaymentProcessor createProcessor() => BankTransferProcessor(iban);
}

/// Тип платёжного метода, известный бизнес-логике (не деталям реализации).
enum PaymentMethod { creditCard, crypto, bankTransfer }

/// Вспомогательная "простая фабрика" (упрощённый вариант паттерна,
/// часто встречающийся в реальных проектах) — выбирает Gateway по enum,
/// избавляя вызывающий код от if/else цепочек по всей кодовой базе.
class PaymentGatewayFactory {
  static PaymentGatewayCreator create(
    PaymentMethod method,
    Map<String, String> params,
  ) {
    switch (method) {
      case .creditCard:
        return CreditCardGateway(params['card']!);
      case .crypto:
        return CryptoGateway(params['wallet']!);
      case .bankTransfer:
        return BankTransferGateway(params['iban']!);
    }
  }
}

/// --- ИНТЕРФЕЙС ПРОДУКТА ---
/// Определяет контракт для всех типов логгеров в системе.
abstract interface class Logger {
  Future<void> log(String msg);
  Future<void> error(String msg, [Object? err, StackTrace? stackTrace]);
}

/// --- КОНКРЕТНЫЕ ПРОДУКТЫ ---
/// Реализация логгера для отправки данных на удаленный сервер аналитики.
class RemoteAnalyticsLogger implements Logger {
  final Uri apiEndpoint;
  final String apiKey;

  const RemoteAnalyticsLogger({
    required this.apiEndpoint,
    required this.apiKey,
  });

  @override
  Future<void> log(String msg) async => print(
    // В реальном продакшене здесь было бы отправка HTTP-запроса
    '[Remote Analytics] Sending payload: {"msg": "$msg"} to $apiEndpoint',
  );

  @override
  Future<void> error(String msg, [Object? err, StackTrace? stackTrace]) async =>
      print('[Remote Analytics ERROR] $msg. Details: $error');
}

/// Реализация логгера для записи логов в локальный файл.
class LocalFileLogger implements Logger {
  final String filePath;

  const LocalFileLogger({required this.filePath});

  @override
  Future<void> log(String msg) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[File Logger] Written to $filePath: [$timestamp] $msg');
  }

  @override
  Future<void> error(String msg, [Object? err, StackTrace? stackTrace]) async {
    final timestamp = DateTime.now().toIso8601String();
    print('[File Logger ERROR] TO $filePath: [$timestamp] $msg. Error: $error');
  }
}

/// --- БАЗОВЫЙ КЛАСС СОЗДАТЕЛЯ (CREATOR) ---
/// Объявляет фабричный метод, который должен возвращать объект класса Logger.
abstract class LoggerConfigurationCreator {
  /// Тот самый фабричный метод который будет создавать наб нужный логер
  Logger createLogger();

  const LoggerConfigurationCreator();

  // Бизнес-логика, которая полагается на созданный продукт,
  // не зная его конкретной реализации.
  void initializeAndLogStatus() {
    final logger = createLogger();
    logger.log(
      'Приложение успешно запущено. Инициализация базовых модулей... ${logger.runtimeType}',
    );
  }
}

/// --- КОНКРЕТНЫЕ СОЗДАТЕЛИ (CONCRETE CREATORS) ---
/// Фабрика для настройки удаленного логирования (например, для Production среды)
class ProductionLoggerConfig extends LoggerConfigurationCreator {
  final Uri _endpoint;
  final String _token;

  const ProductionLoggerConfig({required this._endpoint, required this._token});

  @override
  Logger createLogger() =>
      RemoteAnalyticsLogger(apiEndpoint: _endpoint, apiKey: _token);
}

/// Фабрика для локального логирования (например, для Dev/Staging среды)
class DevelopmentLoggerConfig extends LoggerConfigurationCreator {
  final String _logFileName;

  const DevelopmentLoggerConfig({this._logFileName = 'dev_logs.txt'});

  @override
  Logger createLogger() =>
      LocalFileLogger(filePath: '/var/log/app/$_logFileName');
}

bool isProduction() => false;

/// --- ДЕМОНСТРАЦИЯ ИСПОЛЬЗОВАНИЯ ---
void main() async {
  // Представим, что мы прочитали конфигурацию окружения (Environment)
  late final LoggerConfigurationCreator config;

  if (isProduction()) {
    config = ProductionLoggerConfig(
      endpoint: Uri.parse('https://api.analytics.internal/v1/logs'),
      token: 'prod_secure_token_abc123',
    );
  } else {
    config = DevelopmentLoggerConfig();
  }

  // Клиентский код работает исключительно через абстракцию LoggerConfigurationCreator
  // Он не знает, какой именно логгер создается внутри.
  config.initializeAndLogStatus();

  final activeLogger = config.createLogger();
  activeLogger.log('Выполнен важный финансовый транзакционный шаг.');

  /// Пример с платежами
  final gateway = PaymentGatewayFactory.create(.creditCard, {
    'card': '**** **** **** 4242',
  });

  final result = await gateway.processPayment(149.99, 'USD');

  print(result);

  final cryptoGateway = PaymentGatewayFactory.create(.crypto, {
    'wallet': 'bc1qxyz...',
  });

  print(await cryptoGateway.processPayment(0.005, 'BTC'));
}
