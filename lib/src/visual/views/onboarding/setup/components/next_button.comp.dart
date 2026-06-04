import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
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
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        final currentPage = SetupPagesExtension.fromStr(
          userService.currentUser.currentSetupPage,
        );
        return MyButton(
          onPressed: (canSubmit && !isLoading)
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
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  currentPage.isLast ? context.lang.finishSetup : context.lang.next,
                ),
        );
      },
    );
  }
}
