import 'package:flutter/material.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

class UserDiscoveryDisabledComp extends StatefulWidget {
  const UserDiscoveryDisabledComp({super.key});

  @override
  State<UserDiscoveryDisabledComp> createState() =>
      _UserDiscoveryDisabledCompState();
}

class _UserDiscoveryDisabledCompState extends State<UserDiscoveryDisabledComp> {
  Future<void> initializeUserDiscoveryWithDefaultSettings() async {
    await UserDiscoveryService.initializeOrUpdate(
      threshold: 2,
      minimumRequiredImagesExchanged: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ListView(
        children: [
          const SizedBox(height: 45),
          Text(
            context.lang.userDiscoveryDisabledIntro,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          RichText(
            text: TextSpan(
              children: formattedText(
                context,
                context.lang.userDiscoveryDisabledInvisible,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 35),
          Text(
            context.lang.userDiscoveryDisabledYouHaveControl,
            style: const TextStyle(fontSize: 17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            context.lang.userDiscoveryDisabledDecide,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 50),

          FilledButton(
            onPressed: initializeUserDiscoveryWithDefaultSettings,
            style: primaryColorButtonStyle.merge(
              FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
              ),
            ),
            child: Text(context.lang.userDiscoveryDisabledEnableWithDefault),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              onPressed: () {},
              style: secondaryGreyButtonStyle(context),
              child: Text(context.lang.userDiscoveryDisabledCustomizeSettings),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              onPressed: () {},
              style: secondaryGreyButtonStyle(context),
              child: Text(context.lang.userDiscoveryDisabledLearnMore),
            ),
          ),
        ],
      ),
    );
  }
}
