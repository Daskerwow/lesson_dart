class Bore {
  const Bore(this.name, this.len, this.bolt, this.create);
  final String name;
  final int len;
  final int bolt;
  final DateTime create;

  List<Object?> get props => [name, len, bolt, create];
}

void main() {
  final bore = Bore('Name', 10, 10, DateTime.now());

  final l1 = bore.props..shuffle();
  final l2 = bore.props..shuffle();

  print(
    '${identical(bore.props[1], bore.props[2])} - identical Выведет: true!',
  ); // Выведет: true!

  // Проверяем каждый элемент из l1
  for (var i = 0; i < l1.length; i++) {
    final itemFromL1 = l1[i];

    // Ищем, есть ли ТОЧНО ЭТОТ ЖЕ объект в списке l2 (по ссылке)
    bool hasExactSameReference = l2.any(
      /// identical() проверяет строгое совпадение ячейки памяти.
      (itemFromL2) => identical(itemFromL1, itemFromL2),
    );

    print(
      'Элемент $itemFromL1 найден по точной ссылке: $hasExactSameReference index $i',
    );
  }
}
