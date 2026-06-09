import 'dart:convert';
import 'dart:io';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
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
  String? debugLogDownloadToken;
  String? debugLogEncryptionKey;

  Future<(String, String)?> uploadDebugLog() async {
    if (debugLogDownloadToken != null && debugLogEncryptionKey != null) {
      return (debugLogDownloadToken!, debugLogEncryptionKey!);
    }
    final downloadToken = getRandomUint8List(32);
    final encryptionKey = getRandomUint8List(32);

    final debugLog = await loadLogFile();

    // 1. Compress the debug log
    final logBytes = utf8.encode(debugLog);
    final compressedBytes = gzip.encode(logBytes);

    // 2. Encrypt using AES-GCM (with 256 bits)
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(
      compressedBytes,
      secretKey: SecretKey(encryptionKey),
    );
    final encryptedData = secretBox.concatenation();

    final messageOnSuccess = TextMessage()
      ..body = []
      ..userId = Int64();

    final uploadRequest = UploadRequest(
      messagesOnSuccess: [messageOnSuccess],
      downloadTokens: [downloadToken],
      encryptedData: encryptedData,
    );

    final uploadRequestBytes = uploadRequest.writeToBuffer();

    final apiUrl =
        'http${apiService.apiSecure}://${apiService.apiHost}/api/upload';

    final requestMultipart = http.MultipartRequest('POST', Uri.parse(apiUrl));

    final headers = await getAuthenticationHeader();
    if (headers == null) {
      Log.error('Auth headers are empty. Returning');
      return null;
    }

    requestMultipart.headers.addAll(headers);

    requestMultipart.files.add(
      http.MultipartFile.fromBytes(
        'file',
        uploadRequestBytes,
        filename: 'upload',
      ),
    );

    final response = await requestMultipart.send();
    if (response.statusCode == 200) {
      final tokenHex = uint8ListToHex(downloadToken);
      final keyHex = uint8ListToHex(encryptionKey);
      setState(() {
        debugLogDownloadToken = tokenHex;
        debugLogEncryptionKey = keyHex;
      });
      return (tokenHex, keyHex);
    }
    return null;
  }

  Future<String?> _getFeedbackText() async {
    var osVersion = '';
    final locale = context.lang.localeName;
    final deviceInfo = DeviceInfoPlugin();
    var phoneModel = '';
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final packageName = packageInfo.packageName;
    final feedback = _controller.text;
    var debugLogToken = '';

    if (!mounted) return null;

    setState(() {
      isLoading = true;
    });

    // Get device information
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      osVersion = 'Android version: ${androidInfo.version.release}';
      phoneModel = ' ${androidInfo.model} (${androidInfo.brand})';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      osVersion = 'iOS version: ${iosInfo.utsname.release}';
      phoneModel = ' ${iosInfo.name}';
    }

    if (includeDebugLog) {
      (String, String)? result;
      try {
        result = await uploadDebugLog();
      } catch (e) {
        Log.error(e);
      }
      if (result == null) {
        if (!mounted) return null;
        showSnackbar(context, 'Could not upload the debug log!');
        setState(() {
          isLoading = false;
        });
        return null;
      }
      final downloadToken = result.$1;
      final encryptionKey = result.$2;
      debugLogToken =
          'Debug Log: https://logs.twonly.eu#$downloadToken/$encryptionKey';
    }

    setState(() {
      isLoading = false;
    });

    return """
$feedback

----------
Reason: ${_selectedReason ?? "Other"}
Locale: $locale
Emoji: ${FeedbackEmojiRow.getEmoji(_selectedFeedback)}
Device info: $phoneModel
twonly Version: $appVersion
twonly Package: $packageName
$osVersion
$debugLogToken
""";
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
                  style: const TextStyle(
                    color: Colors.blue,
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
                          SubmitMessage(fullMessage: fullMessage),
                        );

                        if (feedbackSend == true && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black87),
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
            style: const TextStyle(
              color: Colors.blue,
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
        _buildEmojiButton(5, Icons.sentiment_very_satisfied),
        _buildEmojiButton(4, Icons.sentiment_satisfied),
        _buildEmojiButton(3, Icons.sentiment_neutral),
        _buildEmojiButton(2, Icons.sentiment_dissatisfied),
        _buildEmojiButton(1, Icons.sentiment_very_dissatisfied),
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

  Widget _buildEmojiButton(int value, IconData icon) {
    final isSelected = selectedFeedback == value;

    return GestureDetector(
      onTap: () {
        onFeedbackChanged(value);
      },
      child: Icon(
        icon,
        size: 40,
        color: _getColorForValue(value, isSelected),
      ),
    );
  }

  Color _getColorForValue(int value, bool isSelected) {
    if (isSelected) {
      if (value == 5) {
        return Colors.greenAccent;
      } else if (value > 1) {
        return Colors.yellow;
      } else {
        return Colors.red;
      }
    } else {
      return const Color.fromARGB(155, 134, 134, 134);
    }
  }
}
