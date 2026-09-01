import 'package:get_it/get_it.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/news.service.dart';
import 'package:twonly/src/services/user.service.dart';

export 'package:twonly/core/bridge/api.dart';
export 'package:twonly/src/services/api/rust_api_result.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Called both from `main` (before the first frame, so the theme can be read)
  // and from `twonlyMinimumInitialization`, which background entry points use
  // on their own. Registering twice throws, so the second call is a no-op.
  if (locator.isRegistered<UserService>()) return;
  locator
    ..registerLazySingleton<UserService>(UserService.new)
    ..registerLazySingleton<ApiService>(ApiService.new)
    ..registerLazySingleton<TwonlyDB>(TwonlyDB.new)
    ..registerLazySingleton<NewsService>(NewsService.new);
}

UserService get userService => locator<UserService>();
ApiService get apiService => locator<ApiService>();
TwonlyDB get twonlyDB => locator<TwonlyDB>();
NewsService get newsService => locator<NewsService>();
