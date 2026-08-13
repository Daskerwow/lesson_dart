/// Статус каждого осужденного пропускаемого через КПП
enum Status {
  /// Где находится
  home,
  inIndustrialZone,
  delayed,
  notArrived,

  /// Группы в которые включен
  overtime,
  study,
}

/// Данные конкретного осужденного
class PrisonerCardOrder {
  final String name;
  final String nameShort;
  final String photo;
  final int brigadeNumber;
  final String pu;
  final String shift; // Смена, в которой трудится
  final String startJob;
  final String endJob;
  final String siteName; // Участок труда
  final Status status; // Статус: на производстве или нет
  final String location;
  final String note; // Пометки (Инвалид, Больничный ...)
  final List<Status> groups; // В каких группах состоит

  const PrisonerCardOrder(
    this.name,
    this.nameShort,
    this.photo,
    this.brigadeNumber,
    this.pu,
    this.shift,
    this.startJob,
    this.endJob,
    this.siteName,
    this.status,
    this.location,
    this.note,
    this.groups,
  );
}

void main() {
  const n = 1000000;
  final args = [
    'a',
    'b',
    'http://',
    122,
    '',
    '1-Смена',
    '08:40',
    '16:00',
    'ДОЦ',
    Status.notArrived,
    'Жилая',
    '',
    <Status>[],
  ];

  var sink = 0;

  // 1. Прямой вызов конструктора
  final sw1 = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final o = PrisonerCardOrder(
      'a',
      'b',
      'http://',
      122,
      '',
      '1-Смена',
      '08:40',
      '16:00',
      'ДОЦ',
      Status.notArrived,
      'Жилая',
      '',
      <Status>[],
    );
    sink += o.hashCode;
  }
  sw1.stop();

  // 2. Function.apply
  final sw2 = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    final o = Function.apply(PrisonerCardOrder.new, args) as PrisonerCardOrder;
    sink += o.hashCode;
  }
  sw2.stop();

  print('direct:  ${sw1.elapsedMicroseconds} us, sink=$sink');
  print('apply:   ${sw2.elapsedMicroseconds} us, sink=$sink');
}
