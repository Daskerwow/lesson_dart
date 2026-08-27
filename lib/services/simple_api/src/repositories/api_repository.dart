import '../entities/page_data.dart';

/// Единственная точка доступа к HTTP-ресурсу.
abstract interface class const ApiRepository<T>() {
  Future<PageData<T>> fetchPage({required int offset, required int limit});
  Future<T> fetchAll();
  Future<T> findById(int id);
  Future<List<T>> createMony(List<Map<String, Object?>> payload);
  Future<T> create(Map<String, Object?> payload);
  Future<List<T>> deleteMony(List<int> payload);
  Future<T> deleteById(int id);
  Future<List<T>> editMony(List<Map<String, Object?>> payload);
  Future<T> editById(int id, Map<String, Object?> payload);
}
