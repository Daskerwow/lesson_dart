String objectName(Object? object) => object.runtimeType.toString();

class ClassName {}

void main() {
  /// Работает даже с null
  final k = ClassName();
  print(objectName(null));
  print(objectName(String));
  print(objectName(k));
  print(k.toString());
}
