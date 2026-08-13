// Exceptions
class ApiException implements Exception {
  final String message;
  final int? code;
  const ApiException(this.message, {this.code});
  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
  @override
  String toString() => 'DatabaseException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'NetworkException: $message';
}

class OperationCancelledException implements Exception {
  final Object? reason;
  const OperationCancelledException([this.reason]);
  @override
  String toString() {
    // ✅ Используем интерполяцию вместо конкатенации
    return 'OperationCancelledException: $reason';
  }
}
