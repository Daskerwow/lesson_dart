/// ============================================================================
/// ПАТТЕРН: INTERPRETER (Интерпретатор)
/// Категория: Поведенческий (Behavioral) — GoF
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Определяет грамматику языка и интерпретатор, который использует эту
/// грамматику для разбора и вычисления предложений на этом языке.
/// Каждое правило грамматики представляется отдельным классом.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Простые предметно-ориентированные языки (DSL): вычисление формул,
///   правила бизнес-валидации, фильтры поиска ("price > 100 AND
///   category = 'books'"), парсинг простых булевых выражений.
/// - НЕ подходит для сложных языков — там нужны полноценные парсеры
///   (ANTLR, парсер-комбинаторы), т.к. Interpreter плохо масштабируется.
library;

/// Контекст интерпретации: переменные, доступные выражениям.
class Context {
  final Map<String, double> variables;
  const Context(this.variables);
}

/// Абстрактное выражение грамматики.
abstract class Expression {
  double interpret(Context context);
}

/// Терминальное выражение: числовой литерал.
class NumberExpression implements Expression {
  final double value;
  const NumberExpression(this.value);

  @override
  double interpret(Context context) => value;
}

/// Терминальное выражение: переменная.
class VariableExpression implements Expression {
  final String name;
  const VariableExpression(this.name);

  @override
  double interpret(Context context) {
    final value = context.variables[name];
    if (value == null) {
      throw ArgumentError('Переменная "$name" не определена в контексте');
    }
    return value;
  }
}

/// Нетерминальное выражение: сложение — комбинирует два подвыражения.
class AddExpression implements Expression {
  final Expression left;
  final Expression right;
  const AddExpression(this.left, this.right);

  @override
  double interpret(Context context) =>
      left.interpret(context) + right.interpret(context);
}

class SubtractExpression implements Expression {
  final Expression left;
  final Expression right;
  const SubtractExpression(this.left, this.right);

  @override
  double interpret(Context context) =>
      left.interpret(context) - right.interpret(context);
}

class MultiplyExpression implements Expression {
  final Expression left;
  final Expression right;
  const MultiplyExpression(this.left, this.right);

  @override
  double interpret(Context context) =>
      left.interpret(context) * right.interpret(context);
}

/// Простой парсер для нотации вида "a + b - c" (левоассоциативно,
/// без учёта приоритета операторов — для демонстрации паттерна).
/// В реальном продакшене для сложных выражений использовали бы
/// полноценную библиотеку парсинга, а не писали Interpreter руками.
class SimpleExpressionParser {
  Expression parse(String expression) {
    /// Разбераем строку команд по частям
    final tokens = expression.split(' ');

    /// Берем первый операнд
    Expression result = _parseOperand(tokens[0]);

    for (var i = 1; i < tokens.length; i += 2) {
      final operator = tokens[i];
      final operand = _parseOperand(tokens[i + 1]);
      switch (operator) {
        case '+':
          result = AddExpression(result, operand);
          break;
        case '-':
          result = SubtractExpression(result, operand);
          break;
        case '*':
          result = MultiplyExpression(result, operand);
          break;
        default:
          throw ArgumentError('Неизвестный оператор: $operator');
      }
    }
    return result;
  }

  Expression _parseOperand(String token) {
    final number = double.tryParse(token);
    return number != null
        ? NumberExpression(number)
        : VariableExpression(token);
  }
}

void main() {
  final parser = SimpleExpressionParser();
  final context = Context({'x': 10, 'y': 5, 'discount': 0.15});

  // Формула бизнес-правила: "цена x - скидка * y"
  final expr1 = parser.parse('x - discount * y');
  print('x - discount * y = ${expr1.interpret(context)}');

  final expr2 = parser.parse('x + y + 100');
  print('x + y + 100 = ${expr2.interpret(context)}');
}
