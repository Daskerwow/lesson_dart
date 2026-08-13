/// ============================================================================
/// АРХИТЕКТУРНЫЙ ПАТТЕРН: REPOSITORY (Репозиторий)
/// ============================================================================
///
/// РОЛЬ И ЦЕЛЬ:
/// Инкапсулирует логику доступа к данным за интерфейсом, похожим на
/// коллекцию в памяти. Скрывает от бизнес-логики детали того, ОТКУДА
/// приходят данные (сеть, локальная БД, кэш) — бизнес-логика работает
/// с абстракцией Repository, а не с конкретным HTTP-клиентом/SQL.
///
/// ГДЕ ИСПОЛЬЗОВАТЬ:
/// - Практически любое приложение с данными: изолирует Domain/UseCase-слой
///   от источника данных, упрощает подмену источника (переход с REST на
///   GraphQL) и тестирование (fake-репозиторий вместо реальной сети).
/// - Реализация оффлайн-first приложений: Repository комбинирует
///   локальный кэш и удалённый источник, отдавая наилучший доступный
///   результат ("cache then network").
library;

/// Доменная модель. (Entities)
class Article {
  final String id;
  final String title;
  final String body;
  const Article(this.id, this.title, this.body);

  @override
  String toString() => 'Article($id, "$title")';
}

/// Абстракция репозитория — то, с чем работает бизнес-логика.
abstract class ArticleRepository {
  Future<List<Article>> getAll();
  Future<Article?> getById(String id);
  Future<void> save(Article article);
  Future<void> delete(String id);
}

/// Источник данных №1: удалённый API.
class ArticleRemoteDataSource {
  Future<List<Article>> fetchAll() async {
    print('[Remote] Запрос списка статей по сети...');
    await Future.delayed(const Duration(milliseconds: 200));
    return List.generate(
      10,
      (item) => Article('$item', 'Паттерны в Dart', 'Контент статьи $item...'),
    );
  }
}

/// Источник данных №2: локальный кэш (имитация БД/SharedPreferences).
class ArticleLocalDataSource {
  final Map<String, Article> _cache = {};

  Future<List<Article>> getCached() async => _cache.values.toList();

  Future<void> cacheAll(List<Article> articles) async {
    for (final a in articles) {
      _cache[a.id] = a;
    }
  }

  Future<Article?> getCachedById(String id) async => _cache[id];

  Future<void> put(Article article) async => _cache[article.id] = article;

  Future<void> remove(String id) async => _cache.remove(id);
}

/// КОНКРЕТНАЯ реализация Repository: комбинирует локальный кэш и удалённый
/// источник по стратегии "cache-then-network" — типичный оффлайн-first
/// подход в продакшен-приложениях.
class ArticleRepositoryImpl implements ArticleRepository {
  final ArticleRemoteDataSource remote;
  final ArticleLocalDataSource local;

  const ArticleRepositoryImpl(this.remote, this.local);

  @override
  Future<List<Article>> getAll() async {
    // Сначала пробуем отдать из кэша быстро, затем обновляем в фоне.
    final cached = await local.getCached();
    if (cached.isNotEmpty) {
      print('[Repository] Отдаём ${cached.length} статей из кэша');
      return cached;
    }
    final fresh = await remote.fetchAll();
    await local.cacheAll(fresh);
    return fresh;
  }

  @override
  Future<Article?> getById(String id) async {
    final cached = await local.getCachedById(id);
    if (cached != null) return cached;
    final all = await remote.fetchAll();
    await local.cacheAll(all);
    final matches = all.where((a) => a.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<void> save(Article article) async {
    // В реальном проекте здесь также был бы вызов remote API для
    // синхронизации, с обработкой конфликтов и повторными попытками.
    await local.put(article);
    print('[Repository] Статья ${article.id} сохранена');
  }

  @override
  Future<void> delete(String id) async {
    await local.remove(id);
    print('[Repository] Статья $id удалена');
  }
}

void main() async {
  final repository = ArticleRepositoryImpl(
    ArticleRemoteDataSource(),
    ArticleLocalDataSource(),
  );

  // Бизнес-логика работает только с ArticleRepository — ей неважно,
  // что "под капотом" два разных источника данных.
  final articles = await repository.getAll();
  print('Получено: $articles');

  // Второй вызов пойдёт из кэша, минуя сеть.
  final cachedArticles = await repository.getAll();
  print('Из кэша: $cachedArticles');

  await repository.save(Article('3', 'Repository паттерн', 'Новая статья'));
  final found = await repository.getById('3');
  print('Найдено по id: $found');
}
