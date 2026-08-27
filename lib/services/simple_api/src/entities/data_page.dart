import 'package:equatable/equatable.dart';

/// Одна страница списка новостей — сырой результат запроса, ещё не привязан
/// к [NewsListState] (это забота репозитория/команд).
final class const DataPage<T>({
  required final List<T> items,
  required final int total,
  required final int limit,
  required final int offset,
}) extends Equatable {
  @override
  List<Object?> get props => [items, total, limit, offset];
}
