import 'dart:async';

import 'clear_use.dart';
import 'exeptions.dart';
import 'use_case.dart';

abstract class UserRepository {
  Future<User> getUserById(int id);
  Future<List<User>> searchUsers(String query);
  Future<void> updateUser(User user);
}

// Data sources
abstract class UserLocalDataSource {
  Future<CachedUser?> getUser(int id);
  Future<void> saveUser(CachedUser user);
  Future<void> markAsPendingSync(int userId);
}

abstract class UserRemoteDataSource {
  Future<User> fetchUser(int id);
  Future<List<User>> searchUsers(String query);
  Future<void> updateUser(User user);
}

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _localDataSource;
  final UserRemoteDataSource _remoteDataSource;
  final Duration _cacheMaxAge;

  UserRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
    this._cacheMaxAge = const Duration(minutes: 5),
  });

  @override
  Future<User> getUserById(int id) async {
    final cached = await _localDataSource.getUser(id);

    if (cached != null && !cached.isExpired(_cacheMaxAge)) {
      print('   📦 Возвращаем из кэша: ${cached.user.name}');

      /// Я знаю, что этот процесс асинхронный, но мне не нужно ждать его завершения
      /// В Dart есть правило unawaited_futures.
      /// Оно ругается, если вы вызываете функцию, возвращающую Future,
      /// внутри async-функции, но не используете ключевое слово await
      unawaited(_refreshCacheInBackground(id));
      return cached.user;
    }

    print('   🌐 Загружаем из сети...');
    try {
      final user = await _remoteDataSource
          .fetchUser(id)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              if (cached != null) {
                print('   ⚠️ Таймаут, возвращаем устаревший кэш');
                return cached.user;
              }
              throw TimeoutException('Сервер не ответил');
            },
          );

      unawaited(_localDataSource.saveUser(CachedUser(user, DateTime.now())));
      return user;
    } on NetworkException catch (e) {
      if (cached != null) {
        print('   ⚠️ Ошибка сети, возвращаем кэш: ${e.message}');
        return cached.user;
      }
      rethrow;
    }
  }

  Future<void> _refreshCacheInBackground(int id) async {
    try {
      final freshUser = await _remoteDataSource.fetchUser(id);
      await _localDataSource.saveUser(CachedUser(freshUser, DateTime.now()));
      print('   ♻️ Кэш обновлён');
    } catch (e) {
      print('   ⚠️ Не удалось обновить кэш: $e');
    }
  }

  @override
  Future<List<User>> searchUsers(String query) {
    return _remoteDataSource
        .searchUsers(query)
        .timeout(const Duration(seconds: 8))
        .catchError((error) {
          print('   ❌ Поиск не удался: $error');
          return <User>[];
        });
  }

  @override
  Future<void> updateUser(User user) async {
    await _localDataSource.saveUser(CachedUser(user, DateTime.now()));

    try {
      await _remoteDataSource
          .updateUser(user)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      print('   ❌ Синхронизация не удалась: $e');
      await _localDataSource.markAsPendingSync(user.id);
      rethrow;
    }
  }
}

class MockUserRepository implements UserRepository {
  Future<User>? _mockedUser;
  Exception? _mockedError;

  void mockSuccess(User user) => _mockedUser = Future.value(user);
  void mockError(Exception error) => _mockedError = error;
  void mockDelay(Duration delay, User user) {
    _mockedUser = Future.delayed(delay, () => user);
  }

  @override
  Future<User> getUserById(int id) async {
    if (_mockedError != null) throw _mockedError!;
    if (_mockedUser != null) return _mockedUser!;
    throw UnimplementedError('Настройте mock перед вызовом');
  }

  @override
  Future<List<User>> searchUsers(String query) => Future.value([]);

  @override
  Future<void> updateUser(User user) => Future.value();
}

Future<void> demonstrateTestingPattern() async {
  print('\n🧪 Testing Pattern — тестируем асинхронность');

  final mockRepo = MockUserRepository();
  final useCase = GetUserUseCase(mockRepo);

  mockRepo.mockDelay(
    const Duration(milliseconds: 100),
    User(id: 1, name: 'Test User'),
  );

  final result = await useCase(1);

  // ✅ Используем метод when() для Either
  result.when(
    error: (failure) => print('   ❌ Ошибка: ${failure.message}'),
    succes: (user) => print('   ✅ Получено: ${user.name}'),
  );
}

Future<void> demonstrateCommonPitfalls() async {
  print('\n⚠️ Common Pitfalls — чего НЕ делать');

  // ❌ АНТИПАТТЕРН: "Заброшенный" Future
  {
    print('\n   ❌ Unawaited Future с ошибкой');

    // ✅ Правильно: обработчик возвращает значение того же типа (String)

    unawaited(
      Future.delayed(const Duration(milliseconds: 100), () {
        return Future.error(Exception('Ошибка'), StackTrace.current);
        // return; // неявно void
      }).catchError((er) => print('Error: $er')),
    );

    await Future.delayed(const Duration(milliseconds: 150));
  }

  // ❌ АНТИПАТТЕРН: Nested async/await
  {
    print('\n   ❌ Избыточная вложенность async/await');

    Future<String> goodStyle() async {
      return Future.value('A').then((v) => '$v+B').then((v) => '$v+C');
    }

    final result = await goodStyle();
    print('   ✅ Результат: $result');
  }

  // ❌ АНТИПАТТЕРН: Future.wait для зависимых запросов
  {
    print('\n   ❌ Future.wait для зависимых операций');

    final userId = await Future.value(42);
    final posts = await Future.delayed(
      const Duration(milliseconds: 100),
      () => ['Post 1', 'Post 2'],
    );
    print('   ✅ Загружено постов: ${posts.length} для user #$userId');
  }

  // ❌ АНТИПАТТЕРН: Игнорирование return в then()
  {
    print('\n   ❌ Потеря значения в цепочке then()');

    final result = await Future.value(10)
        .then((value) {
          return value * 2; // ✅ Явный return
        })
        .then((value) => value);

    print('   ✅ Результат: $result');
  }
}
