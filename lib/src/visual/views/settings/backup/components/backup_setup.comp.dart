import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';

Future<bool> isSecurePassword(String password) async {
  final badPasswordsStr = await rootBundle.loadString(
    'assets/passwords/bad_passwords.txt',
  );
  final badPasswords = badPasswordsStr.split('\n');
  if (badPasswords.contains(password)) {
    return false;
  }
  // Check if the password meets all criteria
  return RegExp('[A-Z]').hasMatch(password) &&
      RegExp('[a-z]').hasMatch(password) &&
      RegExp('[0-9]').hasMatch(password);
}

class BackupPasswordTextField extends StatefulWidget {
  const BackupPasswordTextField({
    required this.controller,
    required this.labelText,
    this.onChanged,
    this.obscureByDefault = true,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final ValueChanged<String>? onChanged;
  final bool obscureByDefault;

  @override
  State<BackupPasswordTextField> createState() => _BackupPasswordTextFieldState();
}

class _BackupPasswordTextFieldState extends State<BackupPasswordTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureByDefault;
  }

  @override
  Widget build(BuildContext context) {
    return MyInput(
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      hintText: widget.labelText,
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        icon: FaIcon(
          _obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
          size: 16,
        ),
      ),
    );
  }
}

class PasswordRequirementText extends StatelessWidget {
  const PasswordRequirementText({
    required this.text,
    required this.showError,
    super.key,
  });

  final String text;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: showError ? Colors.red : Colors.transparent,
        ),
      ),
    );
  }
}

void showBackupExplanation(BuildContext context) {
  final isDark = isDarkMode(context);
  final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
  final textColor = isDark ? Colors.white : Colors.black87;
  final subtitleColor = isDark ? Colors.white70 : Colors.black54;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'twonly Backup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.lang.backupTwonlySafeLongDesc,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 32),
              MyButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
