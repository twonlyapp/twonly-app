import 'package:flutter/material.dart';

/// Every Twonly-specific color, with its light and dark values side by side.
///
/// To add a color, add exactly one entry here and use it with:
/// `context.appColor(AppColor.yourColor)`.
enum AppColor {
  // Chat bubbles
  chatBubbleSent(light: Color(0xFFE8EBE9), dark: Color(0xFF292C2A)),
  chatBubbleReceived(light: Color(0xFFF3F4F3), dark: Color(0xFF1D201E)),
  onChatBubbleSent(light: Color(0xFF191C1A), dark: Color(0xFFF0F2F0)),
  onChatBubbleReceived(light: Color(0xFF191C1A), dark: Color(0xFFE2E4E1)),
  chatBubbleDeleted(light: Color(0xFFE1E4E1), dark: Color(0xFF101311)),
  onChatBubbleDeleted(light: Color(0xFF626863), dark: Color(0xFF8A918B)),
  chatMessageMeta(light: Color(0xFF69706A), dark: Color(0xFFAAB2AC)),
  reactionBackground(light: Color(0xFFE1E5E2), dark: Color(0xFF343936)),
  onReaction(light: Color(0xFF191C1A), dark: Color(0xFFF0F2F0)),

  // Feedback and status
  success(light: Color(0xFF177245), dark: Color(0xFF65D99A)),
  onSuccess(light: Color(0xFFFFFFFF), dark: Color(0xFF00391F)),
  successContainer(light: Color(0xFFC0F0D2), dark: Color(0xFF00522F)),
  onSuccessContainer(light: Color(0xFF002112), dark: Color(0xFF83F7B5)),
  warning(light: Color(0xFF8A5700), dark: Color(0xFFFFB95F)),
  onWarning(light: Color(0xFFFFFFFF), dark: Color(0xFF492900)),
  warningContainer(light: Color(0xFFFFDDB4), dark: Color(0xFF673D00)),
  onWarningContainer(light: Color(0xFF2C1700), dark: Color(0xFFFFDDB4)),
  info(light: Color(0xFF35618D), dark: Color(0xFF9FCBFF)),
  onInfo(light: Color(0xFFFFFFFF), dark: Color(0xFF003257)),
  infoContainer(light: Color(0xFFD1E4FF), dark: Color(0xFF164A70)),
  onInfoContainer(light: Color(0xFF001D35), dark: Color(0xFFD1E4FF)),
  premium(light: Color(0xFF8A6500), dark: Color(0xFFFFC94C)),
  verificationPending(light: Color(0xFF007FA3), dark: Color(0xFF5DD5F5)),
  verificationIdle(light: Color(0xFF7A8497), dark: Color(0xFFAEB8CC)),

  // QR codes
  qrForeground(light: Color(0xFF000000), dark: Color(0xFF000000)),
  qrBackground(light: Color(0xFFFFFFFF), dark: Color(0xFFFFFFFF)),

  // Controls displayed over photos and videos
  mediaForeground(light: Color(0xFFFFFFFF), dark: Color(0xFFFFFFFF)),
  mediaForegroundMuted(light: Color(0xB3FFFFFF), dark: Color(0xB3FFFFFF)),
  mediaBackground(light: Color(0xFF000000), dark: Color(0xFF000000)),
  mediaScrim(light: Color(0x8A000000), dark: Color(0x8A000000)),
  selectedZoom(light: Color(0xFFFFEB3B), dark: Color(0xFFFFEB3B)),
  recording(light: Color(0xFFD32F2F), dark: Color(0xFFFF5252)),
  scanHighlight(light: Color(0xFF76FF03), dark: Color(0xFF76FF03)),

  // Message-kind indicators
  messageText(light: Color(0xFF448AFF), dark: Color(0xFF448AFF)),
  messageRestore(light: Color(0xFFFF9800), dark: Color(0xFFFF9800)),
  messageWidget(light: Color(0xFF9B59B6), dark: Color(0xFF9B59B6)),
  messageVideo(light: Color(0xFFF321D0), dark: Color(0xFFF321D0)),
  messageAudio(light: Color(0xFFFC9555), dark: Color(0xFFFC9555)),
  messageImage(light: Color(0xFFFF5252), dark: Color(0xFFFF5252));

  const AppColor({required this.light, required this.dark});

  final Color light;
  final Color dark;

  Color resolve(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// Resolves [AppColor] tokens for one theme and keeps theme transitions smooth.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors.light()
    : _brightness = Brightness.light,
      _interpolatedColors = null;

  const AppColors.dark()
    : _brightness = Brightness.dark,
      _interpolatedColors = null;

  const AppColors._interpolated(this._interpolatedColors) : _brightness = null;

  final Brightness? _brightness;
  final Map<AppColor, Color>? _interpolatedColors;

  Color operator [](AppColor color) {
    return _interpolatedColors?[color] ?? color.resolve(_brightness!);
  }

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors._interpolated({
      for (final color in AppColor.values)
        color: Color.lerp(this[color], other[color], t)!,
    });
  }
}
