import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter/material.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key, required this.callbackOnSuccess});
  final Function callbackOnSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        bodyPadding: EdgeInsets.only(top: 75, left: 10, right: 10),
        pages: [
          PageViewModel(
            title: "Welcome to twonly!",
            body:
                "With twonly you can share pictures with friends that only you and the receiver can see!",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Image.asset("assets/images/onboarding/01.png"),
              ),
            ),
          ),
          PageViewModel(
            title: "No ads, no tracking",
            body:
                "twonly is complete add free and does not collect any personal data. The server does not save any data of you.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Image.asset("assets/images/onboarding/02.png"),
              ),
            ),
          ),
          PageViewModel(
            title: "End-to-End protection",
            body:
                "twonly encrypts every message you send. For this it uses the Signal protocol which is currently the best way to encrypt messages with a minimum of metadata.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Image.asset("assets/images/onboarding/03.png"),
              ),
            ),
          ),
          // PageViewModel(
          //   title: "Hard work",
          //   body:
          //       "We try everything to give you the best experience but developing and maintaining is hard work and requires thousand of hours.",
          //   image: Center(
          //     child: Padding(
          //       padding: const EdgeInsets.only(top: 100),
          //       child: Image.asset("assets/images/onboarding/04.png"),
          //     ),
          //   ),
          // ),
          PageViewModel(
            title: "You are not the product!",
            body:
                "Nothing is free. Either you pay with your personal informations or with money. Twonly gives you the chance to use an social media product without exploiting you by collection you personal data.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Image.asset("assets/images/onboarding/05.png"),
              ),
            ),
          ),
          PageViewModel(
            title: "Try for free!",
            bodyWidget: Column(
              children: [
                Text(
                  "You can test twonly free for 14 days and then decide if it is worth to you.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 50, right: 50, top: 20),
                    child: FilledButton(
                      onPressed: () {
                        callbackOnSuccess();
                        // On button pressed
                      },
                      child: const Text("Try for free"),
                    )),
              ],
            ),
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Image.asset("assets/images/onboarding/06.png"),
              ),
            ),
          ),
        ],
        showNextButton: true,
        done: const Text("Our plans"),
        next: const Text("Next"),
        // done: RegisterView(callbackOnSuccess: callbackOnSuccess),
        onDone: () {
          callbackOnSuccess();
          // On button pressed
        },
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.secondary,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
      ),
    );
  }
}
