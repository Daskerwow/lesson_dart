// ============================================================================
// 🏗️ 6. CLEAN ARCHITECTURE INTEGRATION
// ============================================================================

// ============================================================================
// 🧩 HELPER CLASSES
// ============================================================================

import 'repository.dart';

class User {
  final int id;
  final String name;

  const User({required this.id, required this.name});

  @override
  String toString() => 'User(id: $id, name: $name)';
}

class CachedUser {
  final User user;
  final DateTime cachedAt;

  CachedUser(this.user, this.cachedAt);

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

void main() async {
  print('🚀 FUTURE CHEAT SHEET v2.1 — Запуск демо');
  print('═' * 60);
  await demonstrateTestingPattern();
  await demonstrateCommonPitfalls();

  print('\n${'═' * 60}');
  print('✅ Все демонстрации завершены!');
  print('💡 Совет: комментируйте ненужные секции в main() для фокуса');
}
