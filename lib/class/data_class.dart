typedef User = ({String name, int age});

void main() {
  // Record — как мини dataclass
  ({String name, int age}) person = (name: "Alex", age: 30);

  print(person.name); // Alex
  print(person.age); // 30
  // Но у них нет методов, поэтому это скорее «структура данных», чем полноценный класс.s

  // record + typedef для читаемости
  User u = (name: "Alex", age: 30);

  print(u);
}

// Class + (const constructor) + (==) + (hashCode) + copyWith()
// В Dart можно объявить обычный класс и переопределить == и hashCode.
// Это даёт поведение «value class» (сравнение по содержимому, а не по ссылке).

class Users {
  final String name; // все поля final
  final int age;

  const Users(this.name, this.age); // const конструктор

  // переопределения сравнения
  @override
  bool operator ==(Object other) =>
      other is Users && other.name == name && other.age == age;

  // переопределения контрольной суммы
  @override
  int get hashCode => Object.hash(name, age);
}


// Codegen библиотеки (лучший вариант)
/*
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String name,
    required int age,
  }) = _User;
}

final u1 = User(name: "Alex", age: 30);
final u2 = u1.copyWith(age: 31);

print(u1 == u2); // false
*/