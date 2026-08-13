# Паттерны проектирования на Dart

Полная коллекция паттернов проектирования с продакшен-уровня примерами на Dart.
Каждый паттерн — отдельный `.dart`-файл с подробной документацией в комментариях
(роль, цель, где использовать) и рабочим примером с `main()`.

Файлы можно запускать напрямую: `dart run путь/к/файлу.dart`

## Структура

### 01_creational — Порождающие паттерны (GoF)
Отвечают за гибкое и удобное создание объектов.

| Файл | Паттерн |
|---|---|
| `singleton.dart` | Singleton — единственный экземпляр класса |
| `factory_method.dart` | Factory Method — делегирование создания объекта подклассам |
| `abstract_factory.dart` | Abstract Factory — создание семейств связанных объектов |
| `builder.dart` | Builder — пошаговое построение сложных объектов |
| `prototype.dart` | Prototype — создание объектов клонированием |

### 02_structural — Структурные паттерны (GoF)
Отвечают за построение удобных, гибких связей между объектами.

| Файл | Паттерн |
|---|---|
| `adapter.dart` | Adapter — приведение несовместимых интерфейсов к общему |
| `bridge.dart` | Bridge — разделение абстракции и реализации |
| `composite.dart` | Composite — древовидные структуры "часть-целое" |
| `decorator.dart` | Decorator — динамическое добавление обязанностей объекту |
| `facade.dart` | Facade — упрощённый интерфейс к сложной подсистеме |
| `flyweight.dart` | Flyweight — экономия памяти через разделяемое состояние |
| `proxy.dart` | Proxy — контроль доступа к объекту через заместителя |

### 03_behavioral — Поведенческие паттерны (GoF)
Отвечают за эффективное и безопасное взаимодействие между объектами.

| Файл | Паттерн |
|---|---|
| `chain_of_responsibility.dart` | Chain of Responsibility — цепочка обработчиков запроса |
| `command.dart` | Command — инкапсуляция запроса в объект (+ undo/redo) |
| `interpreter.dart` | Interpreter — интерпретация простого языка/грамматики |
| `iterator.dart` | Iterator — последовательный обход коллекции |
| `mediator.dart` | Mediator — централизация взаимодействия объектов |
| `memento.dart` | Memento — сохранение и восстановление состояния |
| `observer.dart` | Observer — уведомление подписчиков об изменениях |
| `state.dart` | State — изменение поведения в зависимости от состояния |
| `strategy.dart` | Strategy — взаимозаменяемые алгоритмы |
| `template_method.dart` | Template Method — скелет алгоритма с переопределяемыми шагами |
| `visitor.dart` | Visitor — новые операции над иерархией без её изменения |

### 04_architectural — Архитектурные паттерны
Организация приложения на уровне слоёв и модулей.

| Файл | Паттерн |
|---|---|
| `mvc.dart` | MVC — Model-View-Controller |
| `mvp.dart` | MVP — Model-View-Presenter (пассивная View) |
| `mvvm.dart` | MVVM — Model-View-ViewModel (реактивный data binding) |
| `clean_architecture.dart` | Clean Architecture — слои Domain/Data/Presentation |
| `bloc_cubit.dart` | BLoC/Cubit — Event → State поток (Flutter-стандарт) |
| `redux_flux.dart` | Redux/Flux — единый Store и чистые редьюсеры |
| `repository.dart` | Repository — абстракция источника данных |
| `ddd.dart` | DDD Building Blocks — Entity, Value Object, Aggregate, Domain Event |
| `cqrs.dart` | CQRS — разделение команд и запросов |

### 05_concurrency — Паттерны конкурентности
Работа с асинхронностью, изолятами и параллелизмом в Dart.

| Файл | Паттерн |
|---|---|
| `producer_consumer.dart` | Producer-Consumer — очередь с обратным давлением |
| `actor_model_isolates.dart` | Actor Model — изоляты с обменом сообщениями |
| `future_stream_pipeline.dart` | Future/Stream Pipeline — конвейер асинхронной обработки |
| `object_pool.dart` | Object Pool — переиспользование дорогих ресурсов |
| `isolate_pool.dart` | Isolate Pool — пул воркеров-изолятов |

### 06_enterprise — Корпоративные паттерны (Fowler, PoEAA)
Организация доступа к данным и бизнес-логике в приложениях.

| Файл | Паттерн |
|---|---|
| `unit_of_work.dart` | Unit of Work — атомарная фиксация набора изменений |
| `data_mapper.dart` | Data Mapper — независимость домена от персистентности |
| `dto.dart` | DTO — объекты передачи данных между слоями |
| `service_layer.dart` | Service Layer — граница операций приложения |
| `dependency_injection.dart` | Dependency Injection — явные, тестируемые зависимости |

### 07_anti_patterns — Антипаттерны
Распространённые ошибки проектирования: как распознать и как рефакторить.
Каждый файл содержит ПЛОХОЙ пример и его РЕФАКТОРИНГ в правильный.

| Файл | Антипаттерн |
|---|---|
| `god_object.dart` | God Object — класс с избыточной ответственностью |
| `spaghetti_code.dart` | Spaghetti Code — запутанная вложенная логика |
| `singleton_abuse.dart` | Singleton Abuse — скрытые зависимости через глобальное состояние |
| `anemic_domain_model.dart` | Anemic Domain Model — данные без поведения |
| `callback_hell.dart` | Callback Hell — вложенные асинхронные колбэки вместо async/await |

## Как читать

Каждый файл самодостаточен и содержит:
1. **Заголовок** — название паттерна и категория.
2. **Роль и цель** — что паттерн решает.
3. **Где использовать** — реальные продакшен-сценарии применения.
4. **Полный код примера** с построчными комментариями, объясняющими "зачем",
   а не только "что".
5. **`main()`** — рабочая демонстрация, которую можно запустить.

## Требования

Dart SDK 3.0+ (используется switch-выражения с pattern matching, sealed classes).
