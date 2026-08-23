import 'package:get_it/get_it.dart';
import 'package:twonly/src/database/signal.db.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/news.service.dart';
import 'package:twonly/src/services/user.service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator
    ..registerLazySingleton<UserService>(UserService.new)
    ..registerLazySingleton<ApiService>(ApiService.new)
    ..registerLazySingleton<TwonlyDB>(TwonlyDB.new)
    ..registerLazySingleton<SignalDB>(SignalDB.new)
    ..registerLazySingleton<NewsService>(NewsService.new);
}

UserService get userService => locator<UserService>();
ApiService get apiService => locator<ApiService>();
TwonlyDB get twonlyDB => locator<TwonlyDB>();
SignalDB get signalDB => locator<SignalDB>();
NewsService get newsService => locator<NewsService>();
