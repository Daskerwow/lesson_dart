/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: MVC (Model-View-Controller)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Разделяет приложение на три слоя: Model (данные и бизнес-логика),
/// View (отображение), Controller (обработка ввода пользователя, связывает
/// Model и View). Цель — разделение ответственности: View не содержит
/// бизнес-логики, Model не знает о View.
///
/// КЛАССИЧЕСКАЯ СХЕМА: Controller получает пользовательский ввод, изменяет
/// Model; View подписывается на изменения Model и перерисовывается;
/// Controller может напрямую выбирать View для отображения.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Backend-фреймворки (в Dart — например, структура проекта на Shelf/
///   Aqueduct-подобных серверных фреймворках): Controller обрабатывает
///   HTTP-запрос, Model — работа с БД, View — сериализация ответа.
/// - Реже используется "в чистом виде" в мобильной разработке (Flutter
///   обычно тяготеет к MVVM/BLoC), но полезно понимать как базу для
///   остальных архитектурных паттернов.
library;

import 'dart:async';

// --- MODEL: данные и бизнес-логика, ничего не знает о UI ---
class TodoItem {
  final String id;
  String title;
  bool isDone;
  TodoItem(this.id, this.title, {this.isDone = false});
}

class TodoModel {
  final List<TodoItem> _items = [];
  final _controller = StreamController<List<TodoItem>>.broadcast();

  Stream<List<TodoItem>> get onChange => _controller.stream;

  void addItem(String title) {
    _items.add(
      TodoItem(DateTime.now().millisecondsSinceEpoch.toString(), title),
    );
    _notify();
  }

  void toggleItem(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.isDone = !item.isDone;
    _notify();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _notify();
  }

  List<TodoItem> get items => List.unmodifiable(_items);

  void _notify() => _controller.add(items);

  void dispose() => _controller.close();
}

// --- VIEW: отвечает ТОЛЬКО за отображение, не содержит бизнес-логики ---
abstract class TodoView {
  void render(List<TodoItem> items);
}

class ConsoleTodoView implements TodoView {
  @override
  void render(List<TodoItem> items) {
    print('--- Список задач (${items.length}) ---');
    for (final item in items) {
      print('${item.isDone ? "[x]" : "[ ]"} ${item.title} (id: ${item.id})');
    }
  }
}

// --- CONTROLLER: обрабатывает "пользовательский ввод", связывает Model и View ---
class TodoController {
  final TodoModel model;
  final TodoView view;
  StreamSubscription? _subscription;

  TodoController(this.model, this.view) {
    // Controller подписывает View на изменения Model — при любом
    // изменении данных View автоматически перерисовывается.
    _subscription = model.onChange.listen(view.render);
  }

  // "Действия пользователя" — в реальном приложении это были бы
  // обработчики нажатий кнопок / HTTP-роуты.
  void onAddTodoRequested(String title) {
    if (title.trim().isEmpty) {
      print('Ошибка: название задачи не может быть пустым');
      return;
    }
    model.addItem(title);
  }

  void onToggleRequested(String id) => model.toggleItem(id);
  void onRemoveRequested(String id) => model.removeItem(id);

  void dispose() {
    _subscription?.cancel();
    model.dispose();
  }
}

void main() {
  final model = TodoModel();
  final view = ConsoleTodoView();
  final controller = TodoController(model, view);

  controller.onAddTodoRequested('Изучить MVC');
  controller.onAddTodoRequested('Изучить MVVM');
  controller.onAddTodoRequested('Написать статью');

  final firstId = model.items.first.id;
  controller.onToggleRequested(firstId);
  controller.onRemoveRequested(model.items.last.id);

  controller.dispose();
}
