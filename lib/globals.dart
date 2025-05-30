import 'package:camera/camera.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/api.service.dart';

late ApiService apiService;

// uses for background notification
late TwonlyDatabase twonlyDB;

List<CameraDescription> gCameras = <CameraDescription>[];
