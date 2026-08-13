int index = 0;

/// Описываем
typedef Factory = String Function(String, int);

Factory factory(String name, int power) {
  final model = '$name Microwave-RX-003$index';
  index++;

  return (String dish, int mode) {
    final str = StringBuffer('Микроволновка $model мощностью $power Вт');
    str.write(', греет блюдо $dish в режиме $mode');
    return str.toString();
  };
}

void main() {
  final microWave = factory('LG', 700);
  print(microWave('Бощь', 5));
}
