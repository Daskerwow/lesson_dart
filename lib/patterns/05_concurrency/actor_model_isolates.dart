/// ============================================================================
/// ПАТТЕРН КОНКУРЕНТНОСТИ: ACTOR MODEL через Dart Isolates
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Модель акторов: независимые единицы вычисления ("акторы"), каждая со
/// своим приватным состоянием, которые общаются ИСКЛЮЧИТЕЛЬНО через обмен
/// сообщениями — никакой общей изменяемой памяти. Dart реализует это
/// нативно через Isolate: каждый изолят имеет свою кучу памяти и общается
/// с другими только через SendPort/ReceivePort, что полностью исключает
/// гонки данных (data races) без необходимости в мьютексах/локах.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Тяжёлые CPU-bound вычисления (парсинг больших JSON, обработка
///   изображений, шифрование) — вынос в изолят не блокирует основной
///   поток событий (в UI-приложении — не блокирует отрисовку кадров).
/// - Изоляция ненадёжного/подверженного сбоям кода: падение изолята не
///   роняет всё приложение.
library;

import 'dart:isolate';

/// Сообщения, которыми "актор" обменивается со своим владельцем —
/// явный протокол взаимодействия, как и положено в модели акторов.
sealed class WorkerMessage {
  const WorkerMessage();
}

class ComputeTask extends WorkerMessage {
  final List<int> numbers;
  final SendPort replyTo;
  const ComputeTask(this.numbers, this.replyTo);
}

class ComputeResult extends WorkerMessage {
  final int sum;
  final int primeCount;
  ComputeResult(this.sum, this.primeCount);
}

/// Точка входа "актора" — выполняется в ОТДЕЛЬНОМ изоляте с собственной
/// памятью. Не имеет доступа к переменным основного изолята напрямую —
/// только к тому, что явно передано через сообщение.
void _workerEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  // Сообщаем главному изоляту, как отправлять нам сообщения.
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is ComputeTask) {
      final sum = message.numbers.fold(0, (a, b) => a + b);
      final primeCount = message.numbers.where(_isPrime).length;
      // Актор отвечает ТОЛЬКО через явный SendPort — никакого общего
      // состояния с вызывающим кодом.
      message.replyTo.send(ComputeResult(sum, primeCount));
    }
  });
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

/// "Прокси" для взаимодействия с актором из основного изолята —
/// скрывает детали протокола ReceivePort/SendPort за удобным API.
class ComputeWorkerActor {
  late Isolate _isolate;
  late SendPort _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();

  Future<void> spawn() async {
    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      _mainReceivePort.sendPort,
    );
    // Первое сообщение от воркера — его SendPort, чтобы мы могли слать задачи.
    _workerSendPort = await _mainReceivePort.first as SendPort;
  }

  Future<ComputeResult> compute(List<int> numbers) async {
    final responsePort = ReceivePort();
    _workerSendPort.send(ComputeTask(numbers, responsePort.sendPort));
    final result = await responsePort.first as ComputeResult;
    responsePort.close();
    return result;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _mainReceivePort.close();
  }
}

void main() async {
  final actor = ComputeWorkerActor();
  await actor.spawn();
  print('Актор (изолят) запущен');

  // Тяжёлое вычисление выполняется в ОТДЕЛЬНОМ изоляте, не блокируя
  // основной поток событий (в реальном Flutter-приложении это значит —
  // UI продолжает отрисовывать кадры во время вычисления).
  final numbers = List.generate(200000, (i) => i + 1);
  final result = await actor.compute(numbers);

  print('Сумма: ${result.sum}');
  print('Количество простых чисел: ${result.primeCount}');

  actor.dispose();
}
