import 'access.dart';

/// (новое состояние, опциональный эффект) — атомарный результат sync-команды
/// с эффектом. `effect == null` — эффект не эмитируется.
typedef SyncSideEffectResult<S, E> = (S next, E? effect);

/// Синхронная команда с атомарным возвратом нового состояния и side-эффекта.
///
/// Должна быть чистой функцией.
///
/// ```dart
/// final class IncrementCommand implements SyncSideEffect<CounterState, CounterEffect> {
///   const IncrementCommand({required this.limit});
///   final int limit;
///
///   @override
///   SyncSideEffectResult<CounterState, CounterEffect> execute(CounterState current) {
///     final next = current.copyWith(count: current.count + 1);
///     return (next, next.count >= limit ? const LimitReached() : null);
///   }
/// }
/// ```
abstract interface class SyncSideEffect<S, E> {
  SyncSideEffectResult<S, E> execute(S current);
}

/// Единичное асинхронное действие с возвратом side-эффекта.
///
/// Как и у [AsyncCommand], `writer.commit` безопасен: `HelmAsyncNotifier`
/// сам проверяет `ref.mounted` перед записью — команде не нужно делать это
/// вручную.
///
/// ```dart
/// final class LoginCommand implements AsyncSideEffect<UserState, UserEffect> {
///   const LoginCommand(this._api, this.credentials);
///   final AuthApi _api;
///   final Credentials credentials;
///
///   @override
///   Future<UserEffect?> execute(StateReader<UserState> reader, StateWriter<UserState> writer) async {
///     try {
///       final user = await _api.login(credentials);
///       writer.commit(reader.current.copyWith(user: user));
///       return const NavigateToHome();
///     } catch (e) {
///       return ShowError(e.toString());
///     }
///   }
/// }
/// ```
abstract interface class AsyncSideEffect<S, E> {
  Future<E?> execute(StateReader<S> reader, StateWriter<S> writer);
}

/// Побочный поток, каждая итерация которого может обновить состояние через
/// [writer] и/или эмитировать side-эффект. `null` из итерации — эффекта нет.
///
/// ```dart
/// final class ChatStreamCommand implements StreamSideEffect<ChatState, ChatEffect> {
///   const ChatStreamCommand(this._socket);
///   final ChatSocket _socket;
///
///   @override
///   Stream<ChatEffect?> execute(StateReader<ChatState> reader, StateWriter<ChatState> writer) =>
///       _socket.messages.map((msg) {
///         writer.commit(reader.current.copyWith(messages: [...reader.current.messages, msg]));
///         return msg.isSystem ? null : MessageReceived(msg);
///       });
/// }
/// ```
abstract interface class StreamSideEffect<S, E> {
  Stream<E?> execute(StateReader<S> reader, StateWriter<S> writer);
}
