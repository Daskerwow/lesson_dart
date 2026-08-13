import 'dart:async';

final user = Stopwatch();

void main() {
  runZoned(
    () {
      print('object');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => print('object'),
    ),
  );
}
