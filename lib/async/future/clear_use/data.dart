/// Either-тип с методом when() для pattern matching
sealed class Emither<L, R> {
  const Emither();

  // ✅ Добавляем метод when() для обработки результатов
  T when<T>({
    required T Function(L value) error,
    required T Function(R value) succes,
  }) {
    return switch (this) {
      Error<L, R>(value: final e) => error(e),
      Succes<L, R>(value: final s) => succes(s),
    };
  }
}

class Error<L, R> extends Emither<L, R> {
  final L value;
  const Error(this.value);
}

class Succes<L, R> extends Emither<L, R> {
  final R value;
  const Succes(this.value);
}

/// Для описания видов ошибок
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
