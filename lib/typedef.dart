/*
 * Псевдоним типа — часто называемый typedef, потому что он 
 * объявляется с помощью ключевого слова typedef — это краткий способ обращения к типу. 
 */

typedef IntList = List<int>;
IntList il = [1, 2, 3];

/// Псевдоним типа может содержать параметры типа <T>:
typedef ListMapper<X> = Map<X, List<X>>;
Map<String, List<String>> m1 = {}; // Длинный способ.
ListMapper<String> m2 = {}; // сокращенный

/// В большинстве случаев мы рекомендуем использовать встроенные типы
/// функций вместо псевдонимов типов для функций. Однако псевдонимы
/// типов функций всё ещё могут быть полезны:
typedef Compare<T> = int Function(T a, T b);

int sort(int a, int b) => a - b;

void main() {
  // ignore: unnecessary_type_check
  assert(sort is Compare<int>); // True!
}

/// В Dart, если вы хотите использовать функциональный тип в качестве аргумента поля,
/// переменной или обобщенного типа, вы можете определить typedef для  этого функционального типа.
/// Однако Dart поддерживает синтаксис встроенных  функциональных типов,
/// который можно использовать везде, где разрешена аннотация типа:

class Event {}

class FilteredObservable {
  final bool Function(Event) _predicate;
  final List<void Function(Event)> _observers;

  FilteredObservable(this._predicate, this._observers);

  void Function(Event)? notify(Event event) {
    if (!_predicate(event)) return null;

    void Function(Event)? last;
    for (final observer in _observers) {
      observer(event);
      last = observer;
    }

    return last;
  }
}

/// Определение типа данных (typedef) может быть оправдано, если тип функции особенно длинный 
/// или используется часто. Но в большинстве случаев пользователи хотят видеть, 
/// какой именно тип функции используется, прямо там, где он применяется, и синтаксис типов функций 
/// обеспечивает им эту ясность.