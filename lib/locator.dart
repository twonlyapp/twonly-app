import 'package:get_it/get_it.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/user.service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator
    ..registerLazySingleton<UserService>(UserService.new)
    ..registerLazySingleton<ApiService>(ApiService.new)
    ..registerLazySingleton<TwonlyDB>(TwonlyDB.new);
}

UserService get userService => locator<UserService>();
ApiService get apiService => locator<ApiService>();
TwonlyDB get twonlyDB => locator<TwonlyDB>();
