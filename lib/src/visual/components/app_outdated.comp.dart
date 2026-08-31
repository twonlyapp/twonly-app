import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:url_launcher/url_launcher.dart';

class AppOutdatedComp extends StatefulWidget {
  const AppOutdatedComp({super.key});

  @override
  State<AppOutdatedComp> createState() => _AppOutdatedCompState();
}

class _AppOutdatedCompState extends State<AppOutdatedComp> {
  bool appIsOutdated = false;
  bool newDeviceRegistered = false;

  late StreamSubscription<ApiEvent> _apiEventSubscription;

  @override
  void dispose() {
    _apiEventSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // The rejection is sent during the API handshake, which regularly completes
    // before this widget is mounted, so start from the last one the service saw.
    _showRejection(apiService.permanentRejection);
    _apiEventSubscription = apiService.events.listen((event) async {
      if (!mounted) return;
      if (event.kind == ApiEventKind.appOutdated ||
          event.kind == ApiEventKind.newDeviceRegistered) {
        await context.read<CustomChangeProvider>().updateConnectionState(false);
        if (!mounted) return;
        setState(() => _showRejection(event.kind));
      }
    });
  }

  void _showRejection(ApiEventKind? kind) {
    appIsOutdated = kind == ApiEventKind.appOutdated;
    newDeviceRegistered = kind == ApiEventKind.newDeviceRegistered;
  }

  @override
  Widget build(BuildContext context) {
    if (newDeviceRegistered) {
      return Positioned(
        top: 60,
        left: 30,
        right: 30,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  context.lang.newDeviceRegistered,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (appIsOutdated) {
      return Positioned(
        top: 60,
        left: 30,
        right: 30,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  context.lang.appOutdated,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (Platform.isAndroid) const SizedBox(height: 5),
                if (Platform.isAndroid)
                  ElevatedButton(
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse(
                          'https://play.google.com/store/apps/details?id=eu.twonly',
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.lang.appOutdatedBtn,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return Container();
  }
}
