/// Право только на чтение состояния — передаётся запросам и наблюдателям.
abstract interface class StateReader<S> {
  S get current;
}

/// Право только на запись состояния — передаётся командам.
///
/// Принцип минимальных привилегий (ISP): команда не может прочитать
/// устаревший снапшот мимо [StateReader], а наблюдатель не может изменить
/// состояние.
///
/// Конкретная реализация [commit] сама решает, применять ли запись —
/// например, `HelmAsyncNotifier` перед записью проверяет `ref.mounted` и
/// молча игнорирует `commit`, если провайдер уже размонтирован. Команде
/// не нужно знать об этом и что-либо проверять вручную.
abstract interface class StateWriter<S> {
  void commit(S nextState);
}

/// Полный доступ: чтение и запись.
abstract interface class StateAccessor<S>
    implements StateReader<S>, StateWriter<S> {}
