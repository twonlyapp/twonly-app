import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';

class MyInput extends StatefulWidget {
  const MyInput({
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.autofocus = false,
    this.errorText,
    this.obscureText = false,
    this.dense = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool autofocus;
  final String? errorText;
  final bool obscureText;
  final bool dense;

  @override
  State<MyInput> createState() => _MyInputState();
}

class _MyInputState extends State<MyInput> {
  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);

    final inputFillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final inputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final inputHintColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final prefixIconColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return ReactiveTapFeedback(
      behavior: HitTestBehavior.translucent,
      alwaysAnimate: true,
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onTapOutside: (event) {
          final pointer = event.pointer;
          final startPosition = event.position;
          var moved = false;

          void handlePointerEvent(PointerEvent routeEvent) {
            if (routeEvent is PointerMoveEvent) {
              if ((routeEvent.position - startPosition).distance > 10) {
                moved = true;
              }
            } else if (routeEvent is PointerUpEvent) {
              GestureBinding.instance.pointerRouter.removeRoute(
                pointer,
                handlePointerEvent,
              );
              if (!moved) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            } else if (routeEvent is PointerCancelEvent) {
              GestureBinding.instance.pointerRouter.removeRoute(
                pointer,
                handlePointerEvent,
              );
            }
          }

          GestureBinding.instance.pointerRouter.addRoute(
            pointer,
            handlePointerEvent,
          );
        },
        inputFormatters: widget.inputFormatters,
        keyboardType: widget.keyboardType,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        style: TextStyle(
          fontSize: widget.dense ? 16 : 18,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          isDense: widget.dense,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: inputHintColor,
            fontSize: widget.dense ? 16 : 18,
          ),
          filled: true,
          fillColor: inputFillColor,
          contentPadding: EdgeInsets.symmetric(
            vertical: widget.dense ? 13 : 18,
            horizontal: widget.dense ? 13 : 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.dense ? 12 : 18),
            borderSide: BorderSide(
              color: inputBorderColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.dense ? 12 : 18),
            borderSide: BorderSide(
              color: inputBorderColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.dense ? 12 : 18),
            borderSide: BorderSide(
              color: isDark ? Colors.white : Colors.black87,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.dense ? 12 : 18),
            borderSide: const BorderSide(
              color: Colors.redAccent,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.dense ? 12 : 18),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 2,
            ),
          ),
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: prefixIconColor,
                  ),
                  child: widget.prefixIcon!,
                )
              : null,
          suffixIcon: widget.suffixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  child: widget.suffixIcon!,
                )
              : null,
        ),
      ),
    );
  }
}
