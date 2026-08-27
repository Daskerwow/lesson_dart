import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'access.dart';
import 'command.dart';
import 'side_effect_command.dart';

/// Синхронный стор: состояние — чистое значение [S], меняется только через
/// [SyncCommand] / [SyncSideEffect].
///
/// Здесь нет `await`, а значит нет и разрыва, во время которого провайдер
/// мог бы успеть размонтироваться между чтением и записью — никакая
/// дополнительная защита не нужна, стор максимально простой.
class HelmSyncNotifier<S, E> extends Notifier<S> {
  HelmSyncNotifier(this._initial);
  final S _initial;

  @override
  S build() => _initial;

  /// Применяет чистую мутацию состояния.
  ///
  /// ```dart
  /// ref.read(counterProvider.notifier).dispatch(const IncrementCommand());
  /// ```
  void dispatch(SyncCommand<S> command) => state = command.execute(state);

  /// Применяет мутацию и возвращает side-эффект для одноразовой обработки —
  /// навигация, снекбар, аналитика. Эффект НЕ хранится в состоянии, применить
  /// его должен сам вызывающий код.
  ///
  /// ```dart
  /// final effect = ref.read(counterProvider.notifier)
  ///     .dispatchWithEffect(const IncrementCommand(limit: 10));
  /// if (effect is LimitReached) showSnackBar('Достигнут лимит');
  /// ```
  E? dispatchWithEffect(SyncSideEffect<S, E> command) {
    final (next, effect) = command.execute(state);
    state = next;
    return effect;
  }
}

/// Асинхронный стор поверх [AsyncNotifier].
/// // (base_command.dart):
/// ref.read(themeProvider.notifier).dispatchAsync(
///   UseUpdateAsync((current) async {
///     final updated = current.rebuild((t) => t.themeMode = mode.index);
///     await themeStore.setData(data: updated);
///     return updated;
///   }),
/// );
/// ```
///
/// Команда получает `this` как [StateReader]/[StateWriter]: `current` отдаёт
/// уже дождавшееся состояние, `commit` перед записью сам проверяет
/// `ref.mounted` — командам про это думать не нужно.
class HelmAsyncNotifier<S, E> extends AsyncNotifier<S>
    implements StateAccessor<S> {
  HelmAsyncNotifier(this._load);
  final Future<S> Function(Ref ref) _load;

  @override
  Future<S> build() => _load(ref);

  @override
  S get current => state.requireValue;

  @override
  void commit(S nextState) {
    if (!ref.mounted) return;
    state = AsyncData(nextState);
  }

  /// Выполняет [command]. Исключение внутри команды автоматически
  /// превращается в `AsyncValue.error` — этим занимается [AsyncValue.guard].
  ///
  /// ```dart
  /// ref.read(themeProvider.notifier).dispatchAsync(
  ///   UseUpdateAsync((current) async {
  ///     final updated = current.rebuild((t) => t.themeMode = mode.index);
  ///     await themeStore.setData(data: updated);
  ///     return updated;
  ///   }),
  /// );
  /// ```
  Future<void> dispatchAsync(AsyncCommand<S> command) async {
    await future; // дождаться текущего состояния, как и в ручном варианте
    if (!ref.mounted) return; // провайдер мог закрыться, пока мы ждали

    state = await AsyncValue.guard(() async {
      await command.execute(this, this); // команда сама вызовет commit
      return current;
    });
  }

  /// Как [dispatchAsync], но команда дополнительно возвращает side-эффект
  /// (навигация, тост и т.д.). Возвращает `null`, если провайдер успел
  /// размонтироваться, — применять эффект в этом случае уже некому.
  ///
  /// ```dart
  /// final effect = await ref.read(authProvider.notifier)
  ///     .dispatchAsyncWithEffect(LoginCommand(api, credentials));
  /// if (effect is NavigateToHome) context.go('/home');
  /// ```
  Future<E?> dispatchAsyncWithEffect(AsyncSideEffect<S, E> command) async {
    await future;
    if (!ref.mounted) return null;

    E? effect;
    state = await AsyncValue.guard(() async {
      effect = await command.execute(this, this);
      return current;
    });

    return ref.mounted ? effect : null;
  }
}

/// Потоковый стор поверх [StreamNotifier].
///
/// Состояние — это ОДИН поток: `Rx.merge([основной источник, канал команд])`.
/// Основной источник — внешние данные (обычно `ref.watch(someUseCase).execute()`),
/// канал команд — то, что коммитят [dispatch]/[dispatchAsync] и т.д. через
/// rxdart. Оба сведены в единый `Stream<S>`, который слушает сам Riverpod —
/// поэтому `state`, ошибки и подписку по-прежнему целиком контролирует
/// `StreamNotifier`, а не наш код вручную (`AsyncData`/`AsyncError` нигде не
/// пишутся напрямую).
///
/// ```dart
/// class CountedLayoutNotifier extends HelmStreamNotifier<CountedLayout, void> {
///   CountedLayoutNotifier() : super((ref) => ref.watch(getCountedData).execute());
///
///   Future<void> sendFilter(Filter filter) => dispatchAsync(
///     UseRun(() => ref.read(setFilterUseCase).execute(filter)),
///   );
/// }
/// ```
class HelmStreamNotifier<S, E> extends StreamNotifier<S>
    implements StateAccessor<S> {
  HelmStreamNotifier(this._source);
  final Stream<S> Function(Ref ref) _source;

  /// Канал, в который [commit] кладёт значения команд. rxdart сводит его с
  /// основным источником в единый поток — см. [build].
  final _commands = PublishSubject<S>();

  @override
  Stream<S> build() {
    ref.onDispose(_commands.close);
    return Rx.merge([_source(ref), _commands.stream]);
  }

  @override
  S get current => state.requireValue;

  @override
  void commit(S nextState) {
    if (!ref.mounted) return;
    _commands.add(nextState);
  }

  /// Применяет чистую мутацию текущего состояния.
  ///
  /// ```dart
  /// ref.read(filterProvider.notifier).dispatch(UseUpdate((s) => s.copyWith(...)));
  /// ```
  void dispatch(SyncCommand<S> command) => commit(command.execute(current));

  /// Как [dispatch], но команда дополнительно возвращает side-эффект.
  E? dispatchWithEffect(SyncSideEffect<S, E> command) {
    final (next, effect) = command.execute(current);
    commit(next);
    return effect;
  }

  /// Выполняет асинхронную команду. Исключение внутри команды становится
  /// ошибкой состояния (`AsyncError`) — так же, как если бы ошибку выбросил
  /// сам основной поток.
  Future<void> dispatchAsync(AsyncCommand<S> command) async {
    await future; // дождаться текущего состояния
    if (!ref.mounted) return;

    final result = await AsyncValue.guard(() => command.execute(this, this));
    if (ref.mounted) {
      result.whenOrNull(
        error: (error, stackTrace) => _commands.addError(error, stackTrace),
      );
    }
  }

  /// Как [dispatchAsync], но возвращает side-эффект команды. `null`, если
  /// провайдер размонтировался до завершения — применять эффект уже некому.
  Future<E?> dispatchAsyncWithEffect(AsyncSideEffect<S, E> command) async {
    await future;
    if (!ref.mounted) return null;

    E? effect;
    final result = await AsyncValue.guard(() async {
      effect = await command.execute(this, this);
    });
    if (ref.mounted) {
      result.whenOrNull(
        error: (error, stackTrace) => _commands.addError(error, stackTrace),
      );
    }
    return ref.mounted ? effect : null;
  }
}
