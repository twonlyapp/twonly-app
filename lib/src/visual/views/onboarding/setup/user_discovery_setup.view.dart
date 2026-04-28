import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class UserDiscoverySetupPage extends StatefulWidget {
  const UserDiscoverySetupPage({super.key});

  @override
  State<UserDiscoverySetupPage> createState() => _UserDiscoverySetupPageState();
}

class _UserDiscoverySetupPageState extends State<UserDiscoverySetupPage> {
  late UserDiscoverySetupState state;

  @override
  void initState() {
    super.initState();
    state = UserDiscoverySetupState(setState: setState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userService.currentUser.isUserDiscoveryEnabled) {
        // feature is already configured...
        UserService.update((user) {
          user.currentSetupPage = SetupPages.userDiscovery.next()?.name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.lang.onboardingUserDiscoveryShareFriends,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          UserDiscoverySetupComp(state: state),
          const SizedBox(height: 60),
          NextButtonComp(
            onPressed: () async {
              return !(await state.initializeOrUpdate());
            },
          ),
        ],
      ),
    );
  }
}
