/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: MVP (Model-View-Presenter)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Развитие MVC, где View становится максимально "пассивной" (passive view):
/// она не знает о Model вообще и лишь делегирует все действия пользователя
/// Presenter'у, а Presenter явно вызывает методы View для обновления
/// интерфейса. В отличие от MVC, здесь нет прямой подписки View на Model —
/// вся связь идёт ЧЕРЕЗ Presenter, что делает View легко тестируемой через мок.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Экраны с сложной логикой валидации/оркестрации, где важно
///   протестировать логику презентации без реального UI (unit-тесты
///   Presenter'а с mock-View).
/// - Android-разработка исторически часто использовала MVP; в Flutter/Dart
///   применим для изоляции тестируемой логики от виджетов.
library;

// --- MODEL ---
class User {
  final String email;
  final String passwordHash;
  const User(this.email, this.passwordHash);
}

class AuthRepository {
  // Имитация "базы данных" пользователей.
  final Map<String, User> _users = {
    'test@example.com': User('test@example.com', _hash('password123')),
  };

  static String _hash(String raw) => 'hash($raw)'; // упрощённо для примера

  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100)); // имитация сети
    final user = _users[email];
    if (user != null && user.passwordHash == _hash(password)) {
      return user;
    }
    return null;
  }
}

// --- VIEW: пассивный интерфейс, Presenter им управляет "снаружи".
// View не содержит НИКАКОЙ логики — только реагирует на команды Presenter'а.
abstract class LoginView {
  void showLoading(bool isLoading);
  void showError(String message);
  void navigateToHome(String userEmail);
  void showValidationError(String field, String message);
}

// --- PRESENTER: вся логика презентации живёт здесь и полностью
// тестируема без реального UI — достаточно передать mock-реализацию LoginView.
class LoginPresenter {
  final AuthRepository repository;
  final LoginView view;

  LoginPresenter(this.repository, this.view);

  Future<void> onLoginButtonPressed(String email, String password) async {
    // Валидация — часть логики презентации, а не Model и не View.
    if (!email.contains('@')) {
      view.showValidationError('email', 'Некорректный email');
      return;
    }
    if (password.length < 6) {
      view.showValidationError('password', 'Пароль должен быть от 6 символов');
      return;
    }

    view.showLoading(true);
    final user = await repository.login(email, password);
    view.showLoading(false);

    if (user == null) {
      view.showError('Неверный email или пароль');
    } else {
      view.navigateToHome(user.email);
    }
  }
}

// --- Конкретная реализация View (в реальном Flutter-проекте это был бы
// StatefulWidget/State, реализующий LoginView) ---
class ConsoleLoginView implements LoginView {
  @override
  void showLoading(bool isLoading) =>
      print(isLoading ? '[UI] Показываем спиннер...' : '[UI] Скрываем спиннер');

  @override
  void showError(String message) => print('[UI] Ошибка: $message');

  @override
  void navigateToHome(String userEmail) =>
      print('[UI] Переход на главный экран, добро пожаловать, $userEmail!');

  @override
  void showValidationError(String field, String message) =>
      print('[UI] Ошибка валидации поля "$field": $message');
}

void main() async {
  final view = ConsoleLoginView();
  final presenter = LoginPresenter(AuthRepository(), view);

  print('--- Попытка с невалидным email ---');
  await presenter.onLoginButtonPressed('not-an-email', '123456');

  print('\n--- Попытка с неверным паролем ---');
  await presenter.onLoginButtonPressed('test@example.com', 'wrongpass');

  print('\n--- Успешный вход ---');
  await presenter.onLoginButtonPressed('test@example.com', 'password123');
}
