void main(List<String> args) {
  print(
    12.bitLength,
  ); // 4 → количество бит, необходимых для представления числа 12
  print(1.hashCode); // 1 → хэш-код числа
  print(1.isEven); // false → число 1 нечетное
  print(1.isFinite); // true → конечное значение
  print(1.isInfinite); // false → не бесконечность
  print(1.isNaN); // false → не "не число"
  print(23.isNegative); // false → число положительное
  print(12.isOdd); // false → число четное
  print(89.runtimeType); // int → тип объекта
  print(55.sign); // 1 → знак числа (положительное)

  //print(22.toJS);            // нет такого метода в Dart

  // методы
  print(24.abs()); // 24 → модуль числа
  print(24.22.ceil()); // 25 → округление вверх
  print(45.ceilToDouble()); // 45.0 → округление вверх в double
  print(456.clamp(345, 590)); // 456 → ограничение в диапазоне [345, 590]
  print(4.compareTo(5)); // -1 → 4 < 5
  print(5.compareTo(4)); // 1 → 5 > 4
  print(4.compareTo(4)); // 0 → равны

  print(444.floor()); // 444 → округление вниз
  print(567.gcd(34)); // 1 → НОД (наибольший общий делитель)
  print(7.modInverse(2)); // 1 → мультипликативная обратная по модулю
  print(2.modPow(1, 2)); // 0 → 2^1 mod 2
  print(3.remainder(2)); // 1 → остаток от деления
  print(4.45.round()); // 4 → округление до ближайшего целого
  print(4.45.roundToDouble()); // 4.0 → округление до ближайшего double
  print(2.toDouble()); // 2.0 → преобразование в double
  print(2.12.toInt()); // 2 → преобразование в int (усечение)
  // Представление числа в заданной системе счисления
  print(4.toRadixString(2)); // "100" → строка в двоичной системе
  print(34.toSigned(2)); // -2 → представление числа с ограничением по битам
  print(-134.toUnsigned(2)); // 2 → представление числа как беззнакового
  print(4.22.floorToDouble()); // 4.0 → округление вниз в double

  print(4.45.truncate()); // 4 → усечение дробной части
  print(4.truncateToDouble()); // 4.0 → усечение в double

  print(
    int.parse('10', radix: 2),
  ); // 2 → парсинг строки "10" как двоичного числа
  print(
    int.tryParse('10', radix: 8),
  ); // 8 → парсинг строки "10" как восьмеричного числа
}
