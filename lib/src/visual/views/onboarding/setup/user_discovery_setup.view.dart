import 'package:flutter/material.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import '../setup.view.dart';

class UserDiscoverySetupPage extends StatelessWidget {
  const UserDiscoverySetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.lang.onboardingUserDiscoveryTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await UserService.update((user) {
                user.currentSetupPage = SetupPages.profile.name;
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 50),
              backgroundColor: context.color.primary,
              foregroundColor: context.color.onPrimary,
            ),
            child: Text(context.lang.onboardingResetSetup),
          ),
        ],
      ),
    );
  }
}
