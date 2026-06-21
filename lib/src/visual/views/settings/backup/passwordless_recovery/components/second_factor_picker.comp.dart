import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/themes/light.dart';

class _FactorOption {
  const _FactorOption({
    required this.type,
    required this.icon,
  });

  final SecondFactorType type;
  final IconData icon;
}

const _options = [
  _FactorOption(
    type: SecondFactorType.none,
    icon: Icons.block_rounded,
  ),
  _FactorOption(
    type: SecondFactorType.pin,
    icon: Icons.dialpad_rounded,
  ),
  _FactorOption(
    type: SecondFactorType.email,
    icon: Icons.email_rounded,
  ),
];

String _getLabel(BuildContext context, SecondFactorType type) {
  switch (type) {
    case SecondFactorType.none:
      return context.lang.passwordlessRecoverySecondFactorNone;
    case SecondFactorType.pin:
      return context.lang.passwordlessRecoverySecondFactorPin;
    case SecondFactorType.email:
      return context.lang.passwordlessRecoverySecondFactorEmail;
  }
}

class SecondFactorPicker extends StatelessWidget {
  const SecondFactorPicker({
    required this.selected,
    required this.onChanged,
    required this.pinController,
    required this.emailController,
    required this.onInputChanged,
    super.key,
  });

  final SecondFactorType selected;
  final ValueChanged<SecondFactorType> onChanged;
  final TextEditingController pinController;
  final TextEditingController emailController;
  final VoidCallback onInputChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.lang.passwordlessRecoveryMethod,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildSegmentedControl(context),
        const SizedBox(height: 16),
        _buildInputField(context),
      ],
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.color.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: List.generate(_options.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Container(
              width: 1,
              height: 40,
              color: context.color.outlineVariant.withValues(alpha: 0.3),
            );
          }

          final optionIndex = index ~/ 2;
          final option = _options[optionIndex];
          final isSelected = selected == option.type;

          BorderRadius? borderRadius;
          if (optionIndex == 0) {
            borderRadius = const BorderRadius.horizontal(
              left: Radius.circular(15),
            );
          } else if (optionIndex == _options.length - 1) {
            borderRadius = const BorderRadius.horizontal(
              right: Radius.circular(15),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: borderRadius,
                ),
                child: Column(
                  children: [
                    Icon(
                      option.icon,
                      color: isSelected
                          ? Colors.black87
                          : context.color.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getLabel(context, option.type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black87
                            : context.color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInputField(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Column(
        children: switch (selected) {
          SecondFactorType.none => [
            Text(
              context.lang.passwordlessRecoveryMethodNoneDesc,
              textAlign: TextAlign.center,
            ),
          ],
          SecondFactorType.pin => [
            MyInput(
              key: const ValueKey('pin_input'),
              controller: pinController,
              hintText: context.lang.passwordlessRecoveryMethodPinHint,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onInputChanged(),
            ),
          ],
          SecondFactorType.email => [
            MyInput(
              key: const ValueKey('email_input'),
              controller: emailController,
              hintText: context.lang.passwordlessRecoveryMethodEmailHint,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => onInputChanged(),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: formattedText(
                  context,
                  context.lang.passwordlessRecoveryMethodEmailDesc,
                ),
                style: TextStyle(
                  color: context.color.onSurface,
                  fontSize: 11,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        },
      ),
    );
  }
}
