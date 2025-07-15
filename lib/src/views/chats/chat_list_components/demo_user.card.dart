import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class DemoUserCard extends StatelessWidget {
  const DemoUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDarkMode(context) ? Colors.white : Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            'This is a Demo-Preview.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: !isDarkMode(context) ? Colors.white : Colors.black,
              fontSize: 18,
            ),
          ),
          FilledButton(
            onPressed: () async {
              await deleteLocalUserData();
              await Restart.restartApp(
                notificationTitle: 'Demo-Mode exited.',
                notificationBody: 'Click here to open the app again',
              );
            },
            child: const Text('Register'),
          )
        ],
      ),
    );
  }
}
