import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge_info.comp.dart';

class VerificationBadeFaqView extends StatefulWidget {
  const VerificationBadeFaqView({super.key});

  @override
  State<VerificationBadeFaqView> createState() =>
      _VerificationBadeFaqViewState();
}

class _VerificationBadeFaqViewState extends State<VerificationBadeFaqView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.verificationBadgeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(40),
        children: const [
          VerificationBadgeInfo(
            displayButtons: true,
          ),
        ],
      ),
    );
  }
}
