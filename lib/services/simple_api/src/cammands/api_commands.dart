import 'package:lesson_dart/services/helm/helm.dart';
import 'package:lesson_dart/services/simple_api/simple_api.dart';

/// Общий паттерн всех команд ниже: показать индикатор загрузки, не теряя
/// текущий список → выполнить IO → закоммитить результат либо ошибку.
/// Ошибка НЕ пробрасывается наружу — она оседает в `state.error`, а не рушит
/// весь `AsyncValue` (иначе пропал бы уже показанный список).
Future<void> _runLoad<T>(
  StateReader<StateDataList<T>> reader,
  StateWriter<StateDataList<T>> writer,
  DataListStatus loadingStatus,
  Future<StateDataList<T>> Function(StateDataList<T> current) load,
) async {
  writer.commit(
    reader.current.copyWith(status: loadingStatus, clearError: true),
  );
  try {
    writer.commit(await load(reader.current));
  } catch (e) {
    writer.commit(reader.current.copyWith(status: .error, error: e));
  }
}

// ─── Загрузка страниц ───────────────────────────────────────────────────────

/// Дозагружает следующую порцию и добавляет её в конец списка
/// (бесконечный скролл).
final class const LoadMoreCommand<T>(final ApiRepository<T> _repository)
    implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    if (reader.current.isLoading || reader.current.isLoadingMore) return;
    if (!reader.current.hasMore) return;

    await _runLoad<T>(reader, writer, .loadingMore, (current) async {
      final nextOffset = current.offset + current.items.length;
      final page = await _repository.fetchPage(
        offset: nextOffset,
        limit: current.limit,
      );

      final items = [...current.items, ...page.items];

      return current.copyWith(
        items: items,
        total: page.total,
        status: (current.offset + items.length) < page.total
            ? .loaded
            : .loadedAll,
      );
    });
  }
}

/// Переход на страницу по номеру (кнопки пагинации в UI) — заменяет список
/// содержимым конкретной страницы, а не дозагружает.
final class const GoToPageCommand<T>(
  final int page,
  final ApiRepository<T> _repository,
) implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    if (page < 1) return;
    if (reader.current.isLoading || reader.current.isLoadingMore) return;

    await _runLoad<T>(reader, writer, .loading, (current) async {
      final newOffset = (page - 1) * current.limit;
      final result = await _repository.fetchPage(
        offset: newOffset,
        limit: current.limit,
      );

      return current.copyWith(
        items: result.items,
        total: result.total,
        offset: newOffset,
        status: (newOffset + result.items.length) < result.total
            ? .loaded
            : .loadedAll,
      );
    });
  }
}

/// Тихий рефреш текущей страницы (pull-to-refresh) — список остаётся на
/// экране, пока идёт загрузка.
final class const ManualRefreshCommand<T>(final ApiRepository<T> _repository)
    implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    if (reader.current.isLoading || reader.current.isLoadingMore) return;

    await _runLoad(reader, writer, .loadingMore, (current) async {
      final result = await _repository.fetchPage(
        offset: current.offset,
        limit: current.limit,
      );

      return current.copyWith(
        items: result.items,
        total: result.total,
        status: (current.offset + result.items.length) < result.total
            ? .loaded
            : .loadedAll,
      );
    });
  }
}

// ─── Мутации отдельных элементов ────────────────────────────────────────────

/// Создаёт новость и локально дописывает её в начало списка — без полной
/// перезагрузки страницы.
final class const CreateCommand<T>(
  final ApiRepository<T> _repository,
  final Map<String, Object?> payload,
) implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    try {
      final created = await _repository.create(payload);
      // состояние ПОСЛЕ await, без гонок
      final fresh = reader.current;
      final newTotal = fresh.total + 1;

      writer.commit(
        fresh.copyWith(
          items: [created, ...fresh.items],
          total: newTotal,
          clearError: true,
        ),
      );
    } catch (e) {
      writer.commit(reader.current.copyWith(status: .error, error: e));
    }
  }
}

/// Удаляет новость и локально убирает её из списка.
final class const DeleteCommand<T>(
  final ApiRepository<T> _repository,
  final int id,
  final bool Function(T) diff,
) implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    try {
      await _repository.deleteById(id);
      final fresh = reader.current;
      final newTotal = fresh.total > 0 ? fresh.total - 1 : 0;

      writer.commit(
        fresh.copyWith(
          items: fresh.items.where(diff).toList(),
          total: newTotal,
          clearError: true,
        ),
      );
    } catch (e) {
      writer.commit(reader.current.copyWith(status: .error, error: e));
    }
  }
}

/// Удаляет новость и локально убирает её из списка.
final class const EditCommand<T>(
  final ApiRepository<T> _repository,
  final int id,
  final Map<String, Object?> payload,
  final bool Function(T) diff,
) implements AsyncCommand<StateDataList<T>> {
  @override
  Future<void> execute(
    StateReader<StateDataList<T>> reader,
    StateWriter<StateDataList<T>> writer,
  ) async {
    try {
      await _repository.editById(id, payload);
      final fresh = reader.current;
      final newTotal = fresh.total > 0 ? fresh.total - 1 : 0;

      writer.commit(
        fresh.copyWith(
          items: fresh.items.where(diff).toList(),
          total: newTotal,
          clearError: true,
        ),
      );
    } catch (e) {
      writer.commit(reader.current.copyWith(status: .error, error: e));
    }
  }
}
