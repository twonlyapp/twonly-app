import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'components/mock_contact_request_actions.comp.dart';

class AddNewContactsPage extends StatelessWidget {
  const AddNewContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.lang.onboardingAddContactsTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.lang.onboardingAddContactsAcceptDesc,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),

        Card(
          elevation: 0,
          color: context.color.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                AvatarIcon(fontSize: 16),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'max',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                MockContactRequestActionsComp(),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        Text(
          context.lang.onboardingAddContactsMethodHeading,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),

          child: Column(
            children: [
              // List of ways to add contacts
              _buildMethodItem(
                context,
                icon: FontAwesomeIcons.qrcode,
                text: context.lang.onboardingAddContactsMethodScan,
              ),
              _buildMethodItem(
                context,
                icon: FontAwesomeIcons.magnifyingGlass,
                text: context.lang.onboardingAddContactsMethodSearch,
              ),
              _buildMethodItem(
                context,
                icon: FontAwesomeIcons.shareNodes,
                text: context.lang.onboardingAddContactsMethodShare,
              ),
            ],
          ),
        ),

        const SizedBox(height: 60),
        const NextButtonComp(),
      ],
    );
  }

  Widget _buildMethodItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.color.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              icon,
              size: 20,
              color: context.color.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
