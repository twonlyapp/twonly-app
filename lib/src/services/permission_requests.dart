import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

/// The platform permission manager permits only one dialog request at a time.
/// Share this lock across camera, recording and notification entry points.
final _permissionRequests = Mutex();

Future<Map<Permission, PermissionStatus>> requestPermissions(
  List<Permission> permissions,
) => _permissionRequests.protect(() => permissions.request());
