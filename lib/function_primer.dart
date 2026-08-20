import 'dart:async';

abstract class BlocEventSink<Event extends Object?> implements ErrorSink {
  void add(Event event);
}

class ErrorSink {}

typedef EventHandler<Event, State> =
    FutureOr<void> Function(Event event, Emitter<State> emit);

typedef Emmit<T> = void Function(T);

class Emitter<T> {}

typedef EventMapper<Event> = Stream<Event> Function(Event event);

typedef EventTransformer<Event> =
    Stream<Event> Function(Stream<Event> events, EventMapper<Event> mapper);

abstract class Bloc<Event, State> extends BlocBase<State>
    implements BlocEventSink<Event> {
  Bloc(State initialState) : super();

  /// The current [BlocObserver] instance.
  static BlocObserver observer = const _DefaultBlocObserver();

  static EventTransformer<dynamic> transformer = (events, mapper) {
    return events
        .map(mapper)
        .transform<dynamic>(const _FlatMapStreamTransformer<dynamic>());
  };

  final _eventController = StreamController<Event>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _emitters = <_Emitter<dynamic>>[];
  final _eventTransformer = Bloc.transformer;

  bool get isClosed => false;

  Null get state => null;

  bool get _emitted => false;

  //*************** ВАЖНОСТЬ В ЭТОЙ ФУНКЦИИ */
  void on<E extends Event>(
    EventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) {
    // Выбираем одну из функций (transformer ?? _eventTransformer)
    // Сразу ее вызываем и передаем ей параметры (transformer ?? _eventTransformer)(params)
    // Прослушиваем (transformer ?? _eventTransformer)(params).listen(null);
    final subscription = (transformer ?? _eventTransformer)(
      _eventController.stream.where((event) => event is E).cast<E>(),
      (dynamic event) {
        void onEmit(State state) {
          if (isClosed) return;
          if (this.state == state && _emitted) return;
          onTransition(
            Transition(
              currentState: this.state,
              event: event as E,
              nextState: state,
            ),
          );
          emit(state);
        }

        final emitter = _Emitter(onEmit);
        final controller = StreamController<E>.broadcast(
          sync: true,
          onCancel: emitter.cancel,
        );

        Future<void> handleEvent() async {
          void onDone() {
            emitter.complete();
            _emitters.remove(emitter);
            if (!controller.isClosed) controller.close();
          }

          try {
            _emitters.add(emitter);
            await handler(event as E, emitter as Emitter<State>);
          } catch (error, stackTrace) {
            onError(error, stackTrace);
            rethrow;
          } finally {
            onDone();
          }
        }

        handleEvent();
        return controller.stream;
      },
    ).listen(null);
    _subscriptions.add(subscription);
  }

  void onError(Object error, StackTrace stackTrace) {}

  void onTransition(Object transition) {}

  void emit(State state) {}
}

class Transition {
  Transition({
    required this.currentState,
    required this.event,
    required this.nextState,
  });
  final Object? currentState;
  final Object? event;
  final Object? nextState;
}

class _Emitter<T> {
  final Emmit<T> _emit;
  _Emitter(this._emit);

  void Function()? get cancel => null;

  void complete() {
    print(_emit);
  }
}

class BlocBase<T> {}

class _DefaultBlocObserver extends BlocObserver {
  const _DefaultBlocObserver();
}

class BlocObserver {
  const BlocObserver();
}

class _FlatMapStreamTransformer<T> extends StreamTransformerBase<Stream<T>, T> {
  const _FlatMapStreamTransformer();

  @override
  Stream<T> bind(Stream<Stream<T>> stream) {
    final controller = StreamController<T>.broadcast(sync: true);

    controller.onListen = () {
      final subscriptions = <StreamSubscription<dynamic>>[];

      final outerSubscription = stream.listen((inner) {
        final subscription = inner.listen(
          controller.add,
          onError: controller.addError,
        );

        subscription.onDone(() {
          subscriptions.remove(subscription);
          if (subscriptions.isEmpty) controller.close();
        });

        subscriptions.add(subscription);
      }, onError: controller.addError);

      outerSubscription.onDone(() {
        subscriptions.remove(outerSubscription);
        if (subscriptions.isEmpty) controller.close();
      });

      subscriptions.add(outerSubscription);

      controller.onCancel = () {
        if (subscriptions.isEmpty) return null;
        final cancels = [for (final s in subscriptions) s.cancel()];
        return Future.wait(cancels).then((_) {});
      };
    };

    return controller.stream;
  }
}
