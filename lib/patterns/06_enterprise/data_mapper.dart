/// ============================================================================
/// ПАТТЕРН: DATA MAPPER (Преобразователь данных)
/// Категория: Корпоративный (Fowler, PoEAA)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Перемещает данные между объектами домена и БД, сохраняя их независимость
/// друг от друга: доменный объект НИЧЕГО не знает о том, как он сохраняется
/// (нет методов save()/load() внутри самой сущности — в отличие от паттерна
/// Active Record). Вся логика преобразования "объект <-> строка таблицы"
/// вынесена в отдельный класс-маппер.
///
/// ОТЛИЧИЕ ОТ ACTIVE RECORD: Active Record смешивает данные и способ их
/// хранения в одном классе (`user.save()`); Data Mapper держит доменную
/// модель "чистой" — она не зависит от деталей персистентности, что
/// облегчает unit-тестирование и соответствует Clean Architecture.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Сложные доменные модели, где бизнес-логика должна быть независима
///   от способа хранения (легко подменить БД или формат сериализации).
/// - Именно так работают "тяжёлые" ORM (Hibernate, Doctrine) под капотом.
library;

/// ЧИСТАЯ доменная сущность — не содержит НИКАКИХ методов персистентности,
/// не знает о существовании БД/SQL/JSON.
class Employee {
  final String id;
  String fullName;
  double salary;
  DateTime hiredAt;

  Employee({
    required this.id,
    required this.fullName,
    required this.salary,
    required this.hiredAt,
  });

  /// Чистая бизнес-логика домена, не связанная с персистентностью.
  double get yearsOfService =>
      DateTime.now().difference(hiredAt).inDays / 365.0;

  bool get isEligibleForBonus => yearsOfService >= 1.0;
}

/// "Строка таблицы" — представление данных ровно в том виде, в каком
/// они физически хранятся (имитация ResultSet из SQL-запроса).
class EmployeeRow {
  final String id;
  final String fullName;
  final double salary;
  final String hiredAtIso;

  EmployeeRow(this.id, this.fullName, this.salary, this.hiredAtIso);
}

/// Имитация таблицы в БД.
class FakeEmployeeTable {
  final Map<String, EmployeeRow> _rows = {};

  EmployeeRow? findById(String id) => _rows[id];
  List<EmployeeRow> findAll() => _rows.values.toList();
  void insert(EmployeeRow row) => _rows[row.id] = row;
  void update(EmployeeRow row) => _rows[row.id] = row;
  void delete(String id) => _rows.remove(id);
}

/// DATA MAPPER: единственное место, знающее, КАК преобразовать Employee
/// (доменный объект) в EmployeeRow (представление БД) и обратно.
/// Employee и EmployeeRow ничего не знают друг о друге напрямую.
class EmployeeMapper {
  final FakeEmployeeTable _table;
  EmployeeMapper(this._table);

  Employee? findById(String id) {
    final row = _table.findById(id);
    if (row == null) return null;
    return _rowToDomain(row);
  }

  List<Employee> findAll() => _table.findAll().map(_rowToDomain).toList();

  void insert(Employee employee) {
    _table.insert(_domainToRow(employee));
    print('[Mapper] Employee ${employee.id} вставлен');
  }

  void update(Employee employee) {
    _table.update(_domainToRow(employee));
    print('[Mapper] Employee ${employee.id} обновлён');
  }

  void delete(String id) {
    _table.delete(id);
    print('[Mapper] Employee $id удалён');
  }

  // --- Преобразования туда-обратно инкапсулированы ЗДЕСЬ, а не внутри
  // доменного класса Employee ---
  Employee _rowToDomain(EmployeeRow row) => Employee(
    id: row.id,
    fullName: row.fullName,
    salary: row.salary,
    hiredAt: DateTime.parse(row.hiredAtIso),
  );

  EmployeeRow _domainToRow(Employee employee) => EmployeeRow(
    employee.id,
    employee.fullName,
    employee.salary,
    employee.hiredAt.toIso8601String(),
  );
}

void main() {
  final table = FakeEmployeeTable();
  final mapper = EmployeeMapper(table);

  final employee = Employee(
    id: 'e1',
    fullName: 'Мария Петрова',
    salary: 85000,
    hiredAt: DateTime.now().subtract(const Duration(days: 400)),
  );

  mapper.insert(employee);

  final loaded = mapper.findById('e1')!;
  print(
    'Загружен: ${loaded.fullName}, стаж: '
    '${loaded.yearsOfService.toStringAsFixed(1)} лет, '
    'право на бонус: ${loaded.isEligibleForBonus}',
  );

  loaded.salary += 5000; // изменение чистого доменного объекта
  mapper.update(loaded); // явное сохранение через mapper, а не loaded.save()
}
