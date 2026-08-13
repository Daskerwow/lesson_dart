/// ============================================================================
/// ПАТТЕРН: DTO (Data Transfer Object)
/// Категория: Корпоративный (Fowler, PoEAA)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Простой объект без бизнес-логики, предназначенный ИСКЛЮЧИТЕЛЬНО для
/// передачи данных между слоями/процессами (например, между API и клиентом,
/// между микросервисами). Снижает число вызовов между удалёнными системами,
/// объединяя несколько полей в один "плоский" объект для передачи.
///
/// ОТЛИЧИЕ ОТ DOMAIN ENTITY: DTO не содержит поведения/бизнес-правил —
/// только данные и (де)сериализацию. Domain Entity, наоборот, инкапсулирует
/// бизнес-логику и часто скрывает часть полей. Смешивание этих двух ролей
/// в одном классе — частая причина "утечки" деталей API в доменную модель.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Контракты REST/GraphQL API (request/response модели).
/// - Передача данных между Presentation и Domain слоями в Clean Architecture
///   (см. также OrderDto в clean_architecture.dart).
library;

/// DTO для запроса создания пользователя через REST API — форма, в которой
/// клиент присылает данные (может не совпадать со структурой Domain Entity).
class CreateUserRequestDto {
  final String email;
  final String password;
  final String? referralCode;

  CreateUserRequestDto({
    required this.email,
    required this.password,
    this.referralCode,
  });

  /// Десериализация из JSON — типичная обязанность DTO.
  factory CreateUserRequestDto.fromJson(Map<String, dynamic> json) {
    return CreateUserRequestDto(
      email: json['email'] as String,
      password: json['password'] as String,
      referralCode: json['referral_code'] as String?,
    );
  }
}

/// DTO ответа API — намеренно НЕ содержит чувствительных полей
/// (например, passwordHash), в отличие от полной Domain Entity.
/// Это "проекция" доменной модели, безопасная для отправки клиенту.
class UserResponseDto {
  final String id;
  final String email;
  final String displayName;
  final String createdAtIso;

  UserResponseDto({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAtIso,
  });

  /// Сериализация в JSON для отправки по сети.
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'created_at': createdAtIso,
  };
}

/// Доменная сущность (для контраста) — содержит бизнес-логику и приватные
/// данные, которых НЕТ в DTO.
class UserEntity {
  final String id;
  final String email;
  final String passwordHash; // конфиденциальные данные — не для DTO!
  final DateTime createdAt;
  bool isEmailVerified;

  UserEntity({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    this.isEmailVerified = false,
  });

  String get displayName => email.split('@').first;

  bool get canLogin => isEmailVerified; // бизнес-правило, которого нет в DTO
}

/// Сервис, который использует DTO на границе и Entity внутри —
/// демонстрирует типичный поток: DTO -> Entity -> бизнес-логика -> DTO.
class UserService {
  final Map<String, UserEntity> _storage = {};

  UserResponseDto createUser(CreateUserRequestDto request) {
    // Валидация и бизнес-логика работают с промежуточными данными,
    // но результат — полноценная Domain Entity.
    final entity = UserEntity(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      email: request.email,
      // в реальности — bcrypt/argon2
      passwordHash: 'hashed(${request.password})',
      createdAt: DateTime.now(),
    );
    _storage[entity.id] = entity;

    // На выходе из сервиса — снова DTO, безопасный для отправки клиенту,
    // БЕЗ passwordHash.
    return UserResponseDto(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      createdAtIso: entity.createdAt.toIso8601String(),
    );
  }
}

void main() {
  final service = UserService();

  final request = CreateUserRequestDto.fromJson({
    'email': 'ivan@example.com',
    'password': 'super_secret_123',
    'referral_code': 'FRIEND10',
  });

  final response = service.createUser(request);

  print('Ответ API (безопасный для клиента): ${response.toJson()}');
  // response.toJson() НЕ содержит passwordHash — DTO явно определяет
  // границу того, что можно передавать наружу.
}
