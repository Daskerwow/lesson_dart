/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: BLoC / Cubit (Business Logic Component)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Разделяет бизнес-логику и UI через явный поток Событий (Events) на входе
/// и Состояний (States) на выходе: UI -> Event -> Bloc -> State -> UI.
/// Cubit — упрощённая версия BLoC без явных событий: методы вызываются
/// напрямую, но состояние по-прежнему публикуется как поток.
///
/// ОТЛИЧИЕ ОТ MVVM: BLoC явно формализует ВХОД как поток событий (а не
/// произвольные вызовы методов), что даёт полную трассируемость "что
/// произошло -> как изменилось состояние" — удобно для логирования,
/// time-travel debugging, тестирования через bloc_test.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Стандарт де-факто в крупных Flutter-приложениях (пакет flutter_bloc).
/// - Когда важна строгая трассируемость переходов состояний и/или общая
///   логика переиспользуется между несколькими экранами.
library;

import 'dart:async';

// ============================================================================
// ЧАСТЬ 1: CUBIT — упрощённый вариант, методы вызываются напрямую.
// ============================================================================

sealed class CounterState {
  final int value;
  const CounterState(this.value);
}

class CounterIdle extends CounterState {
  const CounterIdle(super.value);
}

class CounterLimitReached extends CounterState {
  const CounterLimitReached(super.value);
}

/// Cubit: минималистичный контейнер состояния с методами-командами.
/// Публикует Stream<CounterState>, на который подписывается View.
class CounterCubit {
  final int maxValue;
  final _controller = StreamController<CounterState>.broadcast();
  int _value = 0;

  CounterCubit({this.maxValue = 5}) {
    _controller.add(CounterIdle(_value));
  }

  Stream<CounterState> get stream => _controller.stream;

  void increment() {
    if (_value >= maxValue) {
      _controller.add(CounterLimitReached(_value));

      /// Покинуть метод чтобы не инкриментировать
      return;
    }

    /// Иначе
    _value++;
    _controller.add(
      _value == maxValue ? CounterLimitReached(_value) : CounterIdle(_value),
    );
  }

  void dispose() => _controller.close();
}

// ============================================================================
// ЧАСТЬ 2: BLoC — формализованный поток Event -> State.
// ============================================================================

/// СОБЫТИЯ (Events) — единственный способ повлиять на BLoC "снаружи".
/// Явное перечисление событий даёт полную трассируемость: в логах видно
/// РОВНО что произошло, а не просто "вызван метод X".
sealed class SearchEvent {
  const SearchEvent();
}

class QueryChanged extends SearchEvent {
  final String query;
  const QueryChanged(this.query);
}

class SearchCleared extends SearchEvent {}

/// СОСТОЯНИЯ (States) — единственный способ BLoC сообщить о себе "наружу".
sealed class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<String> results;
  const SearchLoaded(this.results);
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

/// BLoC: принимает поток событий на вход через add(), трансформирует их
/// в поток состояний на выход через stream.
class SearchBloc {
  final _eventController = StreamController<SearchEvent>();
  final _stateController = StreamController<SearchState>.broadcast();

  Stream<SearchState> get stream => _stateController.stream;

  SearchBloc() {
    _stateController.add(SearchInitial());
    // Внутренняя "машина событий": каждое входящее событие обрабатывается
    // последовательно через _mapEventToState.
    _eventController.stream.listen(_mapEventToState);
  }

  /// Единственная точка входа для UI — вместо вызова произвольных методов
  /// UI просто "диспатчит" событие.
  void add(SearchEvent event) => _eventController.add(event);

  Future<void> _mapEventToState(SearchEvent event) async {
    switch (event) {
      case QueryChanged(query: final query):
        if (query.isEmpty) {
          _stateController.add(SearchInitial());
          return;
        }
        _stateController.add(SearchLoading());
        try {
          // Имитация похода в API поиска.
          await Future.delayed(const Duration(milliseconds: 150));
          final results = List.generate(3, (i) => '$query результат ${i + 1}');
          _stateController.add(SearchLoaded(results));
        } catch (e) {
          _stateController.add(SearchError('Ошибка поиска: $e'));
        }
        break;
      case SearchCleared():
        _stateController.add(SearchInitial());
        break;
    }
  }

  void dispose() {
    _eventController.close();
    _stateController.close();
  }
}

void main() async {
  print('=== Cubit ===');
  final cubit = CounterCubit(maxValue: 3);

  cubit.stream.listen((state) {
    final label = state is CounterLimitReached ? 'ЛИМИТ ДОСТИГНУТ' : 'обычное';
    print('[Cubit] value=${state.value} ($label)');
  });
  for (var i = 0; i < 5; i++) {
    cubit.increment();
  }
  await Future.delayed(const Duration(milliseconds: 10));
  cubit.dispose();

  print('\n=== BLoC ===');
  final bloc = SearchBloc();
  bloc.stream.listen((state) {
    switch (state) {
      case SearchInitial():
        print('[BLoC] Начальное состояние');
        break;
      case SearchLoading():
        print('[BLoC] Загрузка...');
        break;
      case SearchLoaded(results: final results):
        print('[BLoC] Найдено: $results');
        break;
      case SearchError(message: final message):
        print('[BLoC] Ошибка: $message');
        break;
    }
  });

  bloc.add(QueryChanged('dart patterns'));
  await Future.delayed(const Duration(milliseconds: 200));
  bloc.add(SearchCleared());
  await Future.delayed(const Duration(milliseconds: 50));
  bloc.dispose();
}
