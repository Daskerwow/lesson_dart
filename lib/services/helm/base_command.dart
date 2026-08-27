import 'access.dart';
import 'command.dart';
import 'side_effect_command.dart';

// ---------------------------------------------------------------------------
// Sync — без эффекта
// ---------------------------------------------------------------------------

/// Заменяет состояние на заранее известное значение — без отдельного класса
/// команды на каждую тривиальную мутацию.
///
/// ```dart
/// notifier.dispatch(UseSet(FilterZone.all));
/// ```
final class UseSet<S> implements SyncCommand<S> {
  const UseSet(this.next);
  final S next;

  @override
  S execute(S current) => next;
}

/// Вычисляет новое состояние из текущего чистой функцией — `copyWith`-подобные
/// обновления без отдельного класса команды.
///
/// ```dart
/// notifier.dispatch(UseUpdate((s) => s.copyWith(isOpen: !s.isOpen)));
/// ```
final class UseUpdate<S> implements SyncCommand<S> {
  const UseUpdate(this.update);
  final S Function(S current) update;

  @override
  S execute(S current) => update(current);
}

/// Выполняет несколько синхронных команд подряд как одну — удобно, когда
/// мутация складывается из нескольких независимых шагов.
///
/// ```dart
/// notifier.dispatch(UseSequence([
///   UseUpdate((s) => s.copyWith(isLoading: false)),
///   UseUpdate((s) => s.copyWith(items: [...s.items, newItem])),
/// ]));
/// ```
final class UseSequence<S> implements SyncCommand<S> {
  const UseSequence(this.commands);
  final List<SyncCommand<S>> commands;

  @override
  S execute(S current) =>
      commands.fold(current, (state, command) => command.execute(state));
}

/// Применяет [then], только если [test] возвращает `true` для текущего
/// состояния — иначе состояние не меняется.
///
/// ```dart
/// notifier.dispatch(UseWhen((s) => !s.isLoading, UseSet(loadingState)));
/// ```
final class UseWhen<S> implements SyncCommand<S> {
  const UseWhen(this.test, this.then);
  final bool Function(S current) test;
  final SyncCommand<S> then;

  @override
  S execute(S current) => test(current) ? then.execute(current) : current;
}

final class UseNull<S> implements SyncCommand<S?> {
  @override
  S? execute(S? current) => null;
}

/// Для индекса кнопок бара навигации или любого индекса
final class UseResetIndex implements SyncCommand<int> {
  @override
  int execute(int current) => 0;
}

final class UseIndex implements SyncCommand<int> {
  const UseIndex(this.next);
  final int next;

  @override
  int execute(int current) => next;
}

final class UseIncrement implements SyncCommand<int> {
  @override
  int execute(int current) => ++current;
}

final class UseDecrement implements SyncCommand<int> {
  @override
  int execute(int current) => --current;
}

/// Для bool состояний, например раскрытие меню и т.д.
final class UseOff implements SyncCommand<bool> {
  @override
  bool execute(bool current) => false;
}

final class UseOn implements SyncCommand<bool> {
  @override
  bool execute(bool current) => true;
}

final class UseToggle implements SyncCommand<bool> {
  @override
  bool execute(bool current) => !current;
}

// ---------------------------------------------------------------------------
// Sync — с эффектом
// ---------------------------------------------------------------------------

/// Как [UseSet], но дополнительно эмитирует side-эффект.
///
/// ```dart
/// notifier.dispatchWithEffect(
///   UseSetWithEffect(loggedOutState, effect: const NavigateToLogin()),
/// );
/// ```
final class UseSetWithEffect<S, E> implements SyncSideEffect<S, E> {
  const UseSetWithEffect(this.next, {this.effect});
  final S next;
  final E? effect;

  @override
  SyncSideEffectResult<S, E> execute(S current) => (next, effect);
}

/// Как [UseUpdate], но функция сразу возвращает и состояние, и опциональный
/// эффект — для случаев, когда эффект зависит от результата.
///
/// ```dart
/// notifier.dispatchWithEffect(UseUpdateWithEffect((s) {
///   final next = s.copyWith(count: s.count + 1);
///   return (next, next.count >= s.limit ? const LimitReached() : null);
/// }));
/// ```
final class UseUpdateWithEffect<S, E> implements SyncSideEffect<S, E> {
  const UseUpdateWithEffect(this.update);
  final SyncSideEffectResult<S, E> Function(S current) update;

  @override
  SyncSideEffectResult<S, E> execute(S current) => update(current);
}

/// Эмитирует side-эффект, не трогая состояние — навигация, диалог,
/// аналитическое событие.
///
/// ```dart
/// notifier.dispatchWithEffect(UseEmitEffect(ShowSnackBar('Сохранено')));
/// ```
final class UseEmitEffect<S, E> implements SyncSideEffect<S, E> {
  const UseEmitEffect(this.effect);
  final E effect;

  @override
  SyncSideEffectResult<S, E> execute(S current) => (current, effect);
}

// ---------------------------------------------------------------------------
// Async — без эффекта
// ---------------------------------------------------------------------------

/// Загружает состояние через переданную функцию и коммитит результат целиком
/// — первичная загрузка / "перезагрузить всё".
///
/// ```dart
/// notifier.dispatchAsync(UseLoad(() => repository.fetchFilterZones()));
/// ```
final class UseLoad<S> implements AsyncCommand<S> {
  const UseLoad(this.load);
  final Future<S> Function() load;

  @override
  Future<void> execute(StateReader<S> reader, StateWriter<S> writer) async {
    writer.commit(await load());
  }
}

/// Асинхронно вычисляет новое состояние из текущего — обобщённая версия
/// паттерна "прочитать current → сделать IO → закоммитить" (ровно то, что вы
/// писали руками в `setThemeMode`), без отдельного класса команды.
///
/// ```dart
/// notifier.dispatchAsync(UseUpdateAsync((current) async {
///   final updated = current.rebuild((t) => t.themeMode = mode.index);
///   await themeStore.setData(data: updated);
///   return updated;
/// }));
/// ```
final class UseUpdateAsync<S> implements AsyncCommand<S> {
  const UseUpdateAsync(this.update);
  final Future<S> Function(S current) update;

  @override
  Future<void> execute(StateReader<S> reader, StateWriter<S> writer) async {
    writer.commit(await update(reader.current));
  }
}

/// Выполняет асинхронное действие, не трогая состояние — отправить аналитику,
/// дёрнуть API без сохранения результата и т.п. (fire-and-forget).
///
/// ```dart
/// notifier.dispatchAsync(UseRun(() => analytics.logEvent('screen_opened')));
/// ```
final class UseRun<S> implements AsyncCommand<S> {
  const UseRun(this.action);
  final Future<void> Function() action;

  @override
  Future<void> execute(StateReader<S> reader, StateWriter<S> writer) =>
      action();
}

// ---------------------------------------------------------------------------
// Async — с эффектом
// ---------------------------------------------------------------------------

/// Как [UseLoad], но дополнительно эмитирует side-эффект.
///
/// ```dart
/// notifier.dispatchAsyncWithEffect(
///   UseLoadWithEffect(() => repository.fetchZones(), effect: const ZonesLoaded()),
/// );
/// ```
final class UseLoadWithEffect<S, E> implements AsyncSideEffect<S, E> {
  const UseLoadWithEffect(this.load, {this.effect});
  final Future<S> Function() load;
  final E? effect;

  @override
  Future<E?> execute(StateReader<S> reader, StateWriter<S> writer) async {
    writer.commit(await load());
    return effect;
  }
}

/// Как [UseUpdateAsync], но функция сразу возвращает и состояние, и
/// опциональный эффект.
///
/// ```dart
/// notifier.dispatchAsyncWithEffect(UseUpdateAsyncWithEffect((current) async {
///   final user = await api.login(credentials);
///   return (current.copyWith(user: user), const NavigateToHome());
/// }));
/// ```
final class UseUpdateAsyncWithEffect<S, E> implements AsyncSideEffect<S, E> {
  const UseUpdateAsyncWithEffect(this.update);
  final Future<(S next, E? effect)> Function(S current) update;

  @override
  Future<E?> execute(StateReader<S> reader, StateWriter<S> writer) async {
    final (next, effect) = await update(reader.current);
    writer.commit(next);
    return effect;
  }
}

/// Выполняет асинхронное действие и возвращает эффект по результату, не
/// трогая состояние — например, попытка повторной отправки кода, которая
/// либо показывает тост об успехе, либо ошибку, но ничего не пишет в стор.
///
/// ```dart
/// notifier.dispatchAsyncWithEffect(UseRunWithEffect(() async {
///   try {
///     await api.resendCode();
///     return const ShowSnackBar('Код отправлен повторно');
///   } catch (e) {
///     return ShowSnackBar('Не удалось отправить: $e');
///   }
/// }));
/// ```
final class UseRunWithEffect<S, E> implements AsyncSideEffect<S, E> {
  const UseRunWithEffect(this.action);
  final Future<E?> Function() action;

  @override
  Future<E?> execute(StateReader<S> reader, StateWriter<S> writer) => action();
}
