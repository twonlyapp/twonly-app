import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';

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

class _MyInputState extends State<MyInput> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          lowerBound: double.negativeInfinity,
          upperBound: double.infinity,
          value: 0,
        )..addListener(() {
          setState(() {});
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _bounce();
  }

  void _onTapCancel() {
    _bounce();
  }

  void _bounce() {
    const spring = SpringDescription(
      mass: 1,
      stiffness: 400,
      damping: 15,
    );
    final simulation = SpringSimulation(
      spring,
      _controller.value,
      0,
      _controller.velocity,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    // 0 (unpressed) -> scale 1.0
    // 1 (pressed) -> scale 0.98 (subtle bounce)
    final scale = 1.0 - (_controller.value * 0.02);
    final isDark = isDarkMode(context);

    final inputFillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    final inputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.15);

    final inputHintColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    final prefixIconColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: scale,
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: widget.dense,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: inputHintColor,
            ),
            filled: true,
            fillColor: inputFillColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: widget.dense ? 14 : 18,
              horizontal: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: inputBorderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: inputBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: isDark ? Colors.white : Colors.black87,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}
