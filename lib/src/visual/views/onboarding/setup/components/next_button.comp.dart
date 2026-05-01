import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

class NextButtonComp extends StatelessWidget {
  const NextButtonComp({
    this.onPressed,
    this.canSubmit = true,
    this.isLoading = false,
    super.key,
  });

  final Future<bool> Function()? onPressed;
  final bool isLoading;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final currentPage = SetupPagesExtension.fromStr(
      userService.currentUser.currentSetupPage,
    );
    return ElevatedButton(
      onPressed: canSubmit
          ? () async {
              if (onPressed != null) {
                final error = await onPressed?.call();
                if (error == true) return;
              }
              await UserService.update((user) {
                user.currentSetupPage = currentPage.next()?.name;
              });
            }
          : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: context.color.primary,
        foregroundColor: context.color.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              currentPage.isLast ? context.lang.finishSetup : context.lang.next,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
