import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

class UnlockTwonlyView extends StatefulWidget {
  const UnlockTwonlyView({required this.callbackOnSuccess, super.key});

  final void Function() callbackOnSuccess;

  @override
  State<UnlockTwonlyView> createState() => _UnlockTwonlyViewState();
}

class _UnlockTwonlyViewState extends State<UnlockTwonlyView> {
  Future<void> _unlockTwonly() async {
    final isAuth = await authenticateUser(context.lang.unlockTwonly);
    if (isAuth) {
      widget.callbackOnSuccess();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _unlockTwonly();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const Icon(
                FontAwesomeIcons.lock,
                size: 40,
              ),
              const SizedBox(height: 24),

              Text(
                context.lang.unlockTwonly,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  context.lang.unlockTwonlyDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: FilledButton(
                  onPressed: _unlockTwonly,
                  child: Text(context.lang.unlockTwonlyTryAgain),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
