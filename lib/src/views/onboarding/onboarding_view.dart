import 'package:introduction_screen/introduction_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Slide 1: Welcome to [App Name]
// Text: "Experience a new way to connect with friends through secure, spontaneous image sharing."
// Image Idea: A vibrant, welcoming graphic featuring diverse groups of friends using the app in various settings (e.g., at a café, at a party, etc.).

// Slide 2: End-to-End Encryption
// Text: "Your privacy matters. Enjoy peace of mind with end-to-end encryption, ensuring only you and your friends can see your images."
// Image Idea: A lock symbol overlaying a smartphone screen displaying an encrypted message, symbolizing security and privacy.

// Slide 3: Local Processing
// Text: "Everything is done locally. Our servers only see encrypted bytes, keeping your data safe from prying eyes."
// Image Idea: A visual representation of local processing, such as a smartphone with a shield icon, indicating that data remains on the device.

// Slide 4: Focus on Images
// Text: "Say goodbye to clutter! Our app is designed for sharing images, not useless distractions."
// Image Idea: A clean, minimalist interface showcasing a user effortlessly sending an image, with a focus on the image itself.

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
                "Experience a new way to connect with friends through secure, spontaneous image sharing.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                // child: Image.asset('assets/animations/messages.gif'),
                child: Lottie.asset(
                  'assets/animations/messages.json',
                ),
              ),
            ),
          ),
          PageViewModel(
            title: "End-to-End Encryption",
            body:
                "Your privacy matters. Enjoy peace of mind with end-to-end encryption, ensuring only you and your friends can see your images.",
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
            title: "Focus on sharing moments",
            body:
                "Say goodbye to addictive features! Our app is designed for sharing moments, no useless distractions or ads.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Lottie.asset(
                  'assets/animations/selfie2.json',
                ),
              ),
            ),
          ),
          PageViewModel(
            title: "Send twonlies",
            body:
                "Share moments securely with just one other person. twonly ensures that only you and your chosen friend can view the picture, keeping your moments private.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Lottie.asset(
                  'assets/animations/twonlies.json',
                  repeat: false,
                ),
              ),
            ),
          ),
          PageViewModel(
            title: "You are not the product!",
            body:
                "If you don't pay, your data is the product that is sold. So we decided to develop a sustainable business model where everyone wins. You can keep your data private and we can create a beautiful app.",
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Lottie.asset(
                  'assets/animations/product.json',
                ),
              ),
            ),
          ),
          PageViewModel(
            title: "Pricing",
            bodyWidget: Column(
              children: [
                Text(
                  "To be able to create a sustainable privacy focused app which does not show ads, we have to rely on you! You can get twonly for only 0,99€ / monthly or 9,99€ / yearly. As twonly is for at least two, you get a second user for free, so your twonly partner does not have to pay!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            image: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Lottie.asset(
                  'assets/animations/selfie.json',
                ),
              ),
            ),
          ),
          PageViewModel(
            title: "Let's get started!",
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
                child: Lottie.asset(
                  'assets/animations/rocket.json',
                ),
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
