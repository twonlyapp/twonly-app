import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/feedback.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/help/contact_us/submit_message.view.dart';
import 'package:twonly/src/visual/views/settings/help/faq.view.dart';

class ContactUsView extends StatefulWidget {
  const ContactUsView({super.key});

  @override
  State<ContactUsView> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUsView> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  bool includeDebugLog = true;
  int? _selectedFeedback;
  String? _selectedReason;
  final FeedbackService _feedbackService = FeedbackService();
  FeedbackDebugLog? _debugLog;

  @override
  void dispose() {
    _controller.dispose();
    _feedbackService.close();
    super.dispose();
  }

  Future<FeedbackDebugLog> uploadDebugLog() async {
    return _debugLog ??= await _feedbackService.uploadDebugLog(
      await loadLogFile(),
    );
  }

  Future<String?> _getFeedbackText() async {
    setState(() {
      isLoading = true;
    });
    try {
      final locale = context.lang.localeName;
      final platform = Theme.of(context).platform;
      final feedback = _controller.text;
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      var osVersion = '';
      var phoneModel = '';
      var debugLogToken = '';

      if (platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        osVersion = 'Android version: ${androidInfo.version.release}';
        phoneModel = ' ${androidInfo.model} (${androidInfo.brand})';
      } else if (platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osVersion = 'iOS version: ${iosInfo.utsname.release}';
        phoneModel = ' ${iosInfo.name}';
      }

      if (includeDebugLog) {
        final result = await uploadDebugLog();
        debugLogToken =
            'Debug Log: https://logs.twonly.eu#${result.downloadToken}/${result.encryptionKey}';
      }

      if (!mounted) return null;
      return """
$feedback

----------
Reason: ${_selectedReason ?? "Other"}
Locale: $locale
Emoji: ${FeedbackEmojiRow.getEmoji(_selectedFeedback)}
Device info: $phoneModel
twonly Version: ${packageInfo.version}
twonly Package: ${packageInfo.packageName}
$osVersion
$debugLogToken
""";
    } catch (error, stackTrace) {
      Log.error(
        'Could not prepare feedback.',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        showSnackbar(context, 'Could not prepare feedback. Please try again.');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = <String>[
      context.lang.contactUsReasonNotWorking,
      context.lang.contactUsReasonFeatureRequest,
      context.lang.contactUsReasonQuestion,
      context.lang.contactUsReasonFeedback,
      context.lang.contactUsReasonOther,
    ];
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.settingsHelpContactUs),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(context.lang.contactUsMessageTitle),
              const SizedBox(height: 5),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.lang.contactUsYourMessage,
                  border: const OutlineInputBorder(),
                ),
                minLines: 5,
                maxLines: 10,
              ),
              const SizedBox(height: 5),
              Text(
                context.lang.contactUsMessage,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 20),
              Text(context.lang.contactUsReason),
              const SizedBox(height: 5),
              DropdownButton<String>(
                hint: Text(context.lang.contactUsSelectOption),
                underline: const SizedBox.shrink(),
                value: _selectedReason,
                onChanged: (newValue) {
                  setState(() {
                    _selectedReason = newValue;
                  });
                },
                items: reasons.map<DropdownMenuItem<String>>((reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(context.lang.contactUsEmojis),
              const SizedBox(height: 5),
              FeedbackEmojiRow(
                selectedFeedback: _selectedFeedback,
                onFeedbackChanged: (newValue) {
                  setState(() {
                    _selectedFeedback = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),
              IncludeDebugLog(
                isChecked: includeDebugLog,
                onChanged: (value) {
                  setState(() {
                    includeDebugLog = value;
                  });
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.push(Routes.settingsHelpFaq),
                child: Text(
                  context.lang.contactUsFaq,
                  style: TextStyle(
                    color: context.appColor(AppColor.info),
                  ),
                ),
              ),
              MyButton(
                variant: MyButtonVariant.primaryDense,
                onPressed: isLoading
                    ? null
                    : () async {
                        final fullMessage = await _getFeedbackText();
                        if (!context.mounted || fullMessage == null) return;

                        final feedbackSend = await context.navPush(
                          SubmitMessage(
                            fullMessage: fullMessage,
                            debugLog: _debugLog,
                          ),
                        );

                        if (feedbackSend == true && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            context.color.onPrimary,
                          ),
                        ),
                      )
                    else
                      const FaIcon(FontAwesomeIcons.angleRight, size: 14),
                    const SizedBox(width: 8),
                    Text(context.lang.next),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IncludeDebugLog extends StatefulWidget {
  const IncludeDebugLog({
    required this.isChecked,
    required this.onChanged,
    super.key,
  });
  final bool isChecked;
  final void Function(bool) onChanged;

  @override
  State<IncludeDebugLog> createState() => _IncludeDebugLogState();
}

class _IncludeDebugLogState extends State<IncludeDebugLog> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox.adaptive(
          value: widget.isChecked,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (value) {
            if (value != null) {
              widget.onChanged(value);
            }
          },
        ),
        Text(context.lang.contactUsIncludeLog),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => context.navPush(
            const FaqView(
              questionId: 'debug-log',
            ),
          ),
          child: Text(
            context.lang.contactUsWhatsThat,
            style: TextStyle(
              color: context.appColor(AppColor.info),
            ),
          ),
        ),
      ],
    );
  }
}

class FeedbackEmojiRow extends StatelessWidget {
  const FeedbackEmojiRow({
    required this.selectedFeedback,
    required this.onFeedbackChanged,
    super.key,
  });
  final int? selectedFeedback;
  final ValueChanged<int?> onFeedbackChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildEmojiButton(context, 5, Icons.sentiment_very_satisfied),
        _buildEmojiButton(context, 4, Icons.sentiment_satisfied),
        _buildEmojiButton(context, 3, Icons.sentiment_neutral),
        _buildEmojiButton(context, 2, Icons.sentiment_dissatisfied),
        _buildEmojiButton(context, 1, Icons.sentiment_very_dissatisfied),
      ],
    );
  }

  static String getEmoji(int? value) {
    if (value == null) return '';
    switch (value) {
      case 5:
        return '😄';
      case 4:
        return '😊';
      case 3:
        return '😐';
      case 2:
        return '😕';
      case 1:
        return '😞';
      default:
        return '❓';
    }
  }

  Widget _buildEmojiButton(BuildContext context, int value, IconData icon) {
    final isSelected = selectedFeedback == value;

    return GestureDetector(
      onTap: () {
        onFeedbackChanged(value);
      },
      child: Icon(
        icon,
        size: 40,
        color: _getColorForValue(context, value, isSelected),
      ),
    );
  }

  Color _getColorForValue(BuildContext context, int value, bool isSelected) {
    if (isSelected) {
      if (value == 5) {
        return context.appColor(AppColor.success);
      } else if (value > 1) {
        return context.appColor(AppColor.warning);
      } else {
        return context.color.error;
      }
    } else {
      return context.color.onSurfaceVariant;
    }
  }
}
