import 'dart:async';

import 'repository.dart';
import 'clear_use.dart';
import 'exeptions.dart';
import 'data.dart';

class GetUserUseCase {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  Future<Emither<Failure, User>> call(int id) async {
    try {
      final user = await _repository.getUserById(id);
      return Succes(user);
    } on NetworkException catch (e) {
      return Error(NetworkFailure(e.message));
    } on TimeoutException catch (e) {
      return Error(TimeoutFailure(e.message!));
    } catch (e, s) {
      print('   🐛 Unexpected error: $e');
      return Error(UnknownFailure('Произошла непредвиденная ошибка'));
    }
  }
}
