import 'package:equatable/equatable.dart';

/// Статус загрузки списка новостей.
enum ApiDataStatus { idle, loading, loadingMore, loaded, loadedAll, error }

/// Состояние списка новостей с offset/limit-пагинацией.
///
/// В отличие от record-based `PaginationState<T>` — обычный immutable-класс
/// с одним `copyWith` вместо россыпи одинаковых по форме методов
/// (`setLoadingNext`/`setError`/`clearError`/`replace`/`reset`/...), которые
/// на деле все делают одно и то же: пересобирают record с одним изменённым
/// полем. Тут это просто `copyWith`, вычисляемые поля — геттеры.
final class ApiDataState<T> extends Equatable {
  const ApiDataState({
    required this.items,
    required this.total,
    required this.offset,
    required this.limit,
    required this.status,
    this.error,
  });

  const new initial({this.limit = 20})
    : items = const [],
      total = 0,
      offset = 0,
      status = .idle,
      error = null;

  final List<T> items;
  final int total;
  final int offset;
  final int limit;
  final ApiDataStatus status;
  final Object? error;

  bool get isLoading => status == .loading;
  bool get isLoadingMore => status == .loadingMore;
  bool get hasError => status == .error;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Есть ли ещё данные за пределами уже загруженного диапазона.
  bool get hasMore => offset + items.length < total;

  int get currentPage => limit == 0 ? 1 : (offset / limit).floor() + 1;
  int get totalPages => total == 0 || limit == 0 ? 1 : (total / limit).ceil();

  ApiDataState<T> copyWith({
    List<T>? items,
    int? total,
    int? offset,
    int? limit,
    ApiDataStatus? status,
    Object? error,
    bool clearError = false,
  }) => ApiDataState<T>(
    items: items ?? this.items,
    total: total ?? this.total,
    offset: offset ?? this.offset,
    limit: limit ?? this.limit,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [items, total, offset, limit, status, error];
}
