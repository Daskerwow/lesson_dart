import 'access.dart';

/// Мгновенная синхронная мутация состояния — без IO и side-эффектов.
///
/// Должна быть чистой функцией. Выполняется атомарно, без `await`,
/// поэтому проблемы "провайдер размонтирован между чтением и записью"
/// здесь в принципе не существует — она возможна только там, где есть
/// разрыв на `await` (см. [AsyncCommand]).
///
/// ```dart
/// final class ToggleThemeCommand implements SyncCommand<AppState> {
///   const ToggleThemeCommand();
///   @override
///   AppState execute(AppState current) => current.copyWith(isDark: !current.isDark);
/// }
/// ```
abstract interface class SyncCommand<S> {
  S execute(S current);
}

/// Единичное асинхронное действие без side-эффекта.
///
/// [writer] безопасен по умолчанию: `HelmAsyncNotifier` перед каждой записью
/// сам проверяет `ref.mounted` и молча игнорирует `commit`, если провайдер
/// уже размонтирован. Команде НЕ нужно ничего проверять вручную — только
/// вызвать `writer.commit`, когда новый снапшот состояния готов.
///
/// ```dart
/// final class FetchUserCommand implements AsyncCommand<UserState> {
///   const FetchUserCommand(this._api);
///   final UserApi _api;
///
///   @override
///   Future<void> execute(StateReader<UserState> reader, StateWriter<UserState> writer) async {
///     final user = await _api.fetchUser();
///     writer.commit(reader.current.copyWith(user: user));
///   }
/// }
/// ```
abstract interface class AsyncCommand<S> {
  Future<void> execute(StateReader<S> reader, StateWriter<S> writer);
}

/// Побочный поток, коммитящий значения через [writer] по мере поступления.
///
/// `HelmStreamNotifier` управляет подпиской: активна только одна побочная
/// команда одновременно — повторный `dispatchStream` отменяет предыдущую
/// подписку, `cancelStream()` отменяет её явно, закрытие провайдера отменяет
/// её тоже.
///
/// ```dart
/// final class LocationStreamCommand implements StreamCommand<MapState> {
///   const LocationStreamCommand(this._gps);
///   final GpsService _gps;
///
///   @override
///   Stream<void> execute(StateReader<MapState> reader, StateWriter<MapState> writer) =>
///       _gps.positions.map((pos) => writer.commit(reader.current.copyWith(position: pos)));
/// }
///
/// notifier.dispatchStream(LocationStreamCommand(_gps));
/// notifier.cancelStream();
/// ```
abstract interface class StreamCommand<S> {
  Stream<void> execute(StateReader<S> reader, StateWriter<S> writer);
}
