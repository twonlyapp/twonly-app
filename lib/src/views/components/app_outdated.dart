import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:url_launcher/url_launcher.dart';

class AppOutdated extends StatefulWidget {
  const AppOutdated({super.key});

  @override
  State<AppOutdated> createState() => _AppOutdatedState();
}

class _AppOutdatedState extends State<AppOutdated> {
  bool appIsOutdated = false;
  bool newDeviceRegistered = false;

  @override
  void dispose() {
    globalCallbackAppIsOutdated = () {};
    globalCallbackNewDeviceRegistered = () {};
    super.dispose();
  }

  @override
  void initState() {
    globalCallbackAppIsOutdated = () async {
      await context.read<CustomChangeProvider>().updateConnectionState(false);
      setState(() {
        appIsOutdated = true;
      });
    };
    globalCallbackNewDeviceRegistered = () async {
      await context.read<CustomChangeProvider>().updateConnectionState(false);
      setState(() {
        newDeviceRegistered = true;
      });
    };
    super.initState();
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white, fontSize: 16),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white, fontSize: 16),
                ),
                if (Platform.isAndroid) const SizedBox(height: 5),
                if (Platform.isAndroid)
                  ElevatedButton(
                    onPressed: () {
                      launchUrl(Uri.parse(
                          'https://play.google.com/store/apps/details?id=eu.twonly'));
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.lang.appOutdatedBtn,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white, fontSize: 16),
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
