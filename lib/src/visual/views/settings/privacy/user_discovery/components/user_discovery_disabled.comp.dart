import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/components/user_discovery_setup.comp.dart';

class UserDiscoveryDisabledComp extends StatefulWidget {
  const UserDiscoveryDisabledComp({super.key});

  @override
  State<UserDiscoveryDisabledComp> createState() =>
      _UserDiscoveryDisabledCompState();
}

class _UserDiscoveryDisabledCompState extends State<UserDiscoveryDisabledComp> {
  late UserDiscoverySetupState state;

  @override
  void initState() {
    super.initState();
    state = UserDiscoverySetupState(setState: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ListView(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.color.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: context.color.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    context.lang.userDiscoverySettingsCurrentlyDisabled,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          UserDiscoverySetupComp(state: state),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              state.initializeOrUpdate();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: context.color.primary,
              foregroundColor: context.color.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(context.lang.userDiscoverySettingsApply),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
