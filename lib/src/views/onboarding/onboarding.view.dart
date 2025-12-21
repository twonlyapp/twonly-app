import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/src/utils/misc.dart';

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
                    'assets/animations/selfie2.json',
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
                    'assets/animations/e2e.json',
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
                    'assets/animations/takephoto.json',
                    repeat: false,
                  ),
                ),
              ),
            ),
            // PageViewModel(
            //   title: context.lang.onboardingSendTwonliesTitle,
            //   body: context.lang.onboardingSendTwonliesBody,
            //   image: Center(
            //     child: Padding(
            //       padding: const EdgeInsets.only(top: 100),
            //       child: Lottie.asset(
            //         'assets/animations/twonlies.json',
            //         repeat: false,
            //       ),
            //     ),
            //   ),
            // ),
            PageViewModel(
              title: context.lang.onboardingNotProductTitle,
              bodyWidget: Column(
                children: [
                  Text(
                    context.lang.onboardingNotProductBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 50, right: 50, top: 20),
                    child: FilledButton(
                      onPressed: callbackOnSuccess,
                      child: Text(context.lang.registerSubmitButton),
                    ),
                  ),
                ],
              ),
              image: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Lottie.asset(
                    'assets/animations/donation.json',
                  ),
                ),
              ),
            ),
            // PageViewModel(
            //   title: context.lang.onboardingGetStartedTitle,
            //   image: Center(
            //     child: Padding(
            //       padding: const EdgeInsets.only(top: 100),
            //       child: Lottie.asset(
            //         'assets/animations/rocket.json',
            //       ),
            //     ),
            //   ),
            // ),
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
            activeShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ),
    );
  }
}
