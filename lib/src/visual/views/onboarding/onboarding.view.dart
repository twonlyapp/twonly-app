import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({required this.callbackOnSuccess, super.key});
  final VoidCallback callbackOnSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          bodyPadding: const EdgeInsets.only(top: 75, left: 10, right: 10),
          pages: [
            PageViewModel(
              title: context.lang.onboardingWelcomeTitle,
              body: context.lang.onboardingWelcomeBody,
              image: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  // child: Image.asset('assets/animations/messages.gif'),
                  child: Lottie.asset(
                    'assets/animations/selfie2.lottie',
                  ),
                ),
              ),
            ),
            PageViewModel(
              title: context.lang.onboardingE2eTitle,
              body: context.lang.onboardingE2eBody,
              image: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Lottie.asset(
                    'assets/animations/e2e.lottie',
                    repeat: false,
                  ),
                ),
              ),
            ),
            PageViewModel(
              title: context.lang.onboardingFocusTitle,
              body: context.lang.onboardingFocusBody,
              image: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Lottie.asset(
                    'assets/animations/takephoto.lottie',
                    repeat: false,
                  ),
                ),
              ),
            ),
            PageViewModel(
              title: context.lang.onboardingNotProductTitle,
              useScrollView: false,
              bodyWidget: Column(
                children: [
                  Text(
                    context.lang.onboardingNotProductBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 50,
                      right: 50,
                      top: 10,
                    ),
                    child: MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: callbackOnSuccess,
                      child: Text(context.lang.registerSubmitButton),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 50,
                      right: 50,
                      top: 10,
                    ),
                    child: MyButton(
                      onPressed: () {
                        callbackOnSuccess();
                        context.push(Routes.settingsBackupRecovery);
                      },
                      variant: MyButtonVariant.secondaryDense,
                      child: Text(
                        context.lang.twonlySafeRecoverBtn,
                      ),
                    ),
                  ),
                ],
              ),
              image: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: SizedBox(
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/donation.lottie',
                    ),
                  ),
                ),
              ),
            ),
          ],
          done: const Text(''),
          next: Text(context.lang.next),
          // done: RegisterView(callbackOnSuccess: callbackOnSuccess),
          onDone: callbackOnSuccess,
          dotsDecorator: DotsDecorator(
            size: const Size.square(8),
            activeSize: const Size(20, 10),
            activeColor: Theme.of(context).colorScheme.primary,
            color: Theme.of(context).colorScheme.secondary,
            spacing: const EdgeInsets.symmetric(horizontal: 3),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }
}
