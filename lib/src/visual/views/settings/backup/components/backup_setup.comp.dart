import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';

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
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        filled: true,
        fillColor: context.color.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
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
