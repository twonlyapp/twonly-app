import 'dart:convert';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/services/api/media_upload.dart'
    show createDownloadTokens, uint8ListToHex;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/help/contact_us/submit_message.view.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<String?> uploadDebugLog() async {
    if (debugLogDownloadToken != null) return debugLogDownloadToken;
    Uint8List downloadToken = createDownloadTokens(1)[0];

    String debugLog = await loadLogFile();

    var messageOnSuccess = TextMessage()
      ..body = []
      ..userId = Int64(0);

    final uploadRequest = UploadRequest(
      messagesOnSuccess: [messageOnSuccess],
      downloadTokens: [downloadToken],
      encryptedData: debugLog.codeUnits,
    );

    final uploadRequestBytes = uploadRequest.writeToBuffer();

    String? apiAuthTokenRaw =
        await FlutterSecureStorage().read(key: SecureStorageKeys.apiAuthToken);
    if (apiAuthTokenRaw == null) {
      Log.error("api auth token not defined.");
      return null;
    }
    String apiAuthToken = uint8ListToHex(base64Decode(apiAuthTokenRaw));

    String apiUrl =
        "http${apiService.apiSecure}://${apiService.apiHost}/api/upload";

    var requestMultipart = http.MultipartRequest(
      "POST",
      Uri.parse(apiUrl),
    );
    requestMultipart.headers['x-twonly-auth-token'] = apiAuthToken;

    requestMultipart.files.add(http.MultipartFile.fromBytes(
      "file",
      uploadRequestBytes,
      filename: "upload",
    ));

    final response = await requestMultipart.send();
    if (response.statusCode == 200) {
      setState(() {
        debugLogDownloadToken = uint8ListToHex(downloadToken);
      });
      return debugLogDownloadToken;
    }
    return null;
  }

  Future<String> _getFeedbackText() async {
    setState(() {
      isLoading = true;
    });
    String osVersion = '';
    String locale = context.lang.localeName;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String phoneModel = "";
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;
    String packageName = packageInfo.packageName;
    final String feedback = _controller.text;
    String debugLogToken = "";

    if (!mounted) return "";

    // Get device information
    if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      osVersion = "Android version: ${androidInfo.version.release}";
      phoneModel = " ${androidInfo.model} (${androidInfo.brand})";
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      osVersion = "iOS version: ${iosInfo.utsname.release}";
      phoneModel = " ${iosInfo.name}";
    }

    if (includeDebugLog) {
      try {
        final token = await uploadDebugLog();
        if (token != null) {
          debugLogToken =
              "Debug Log: https://api.twonly.eu/api/download/$token";
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload the debug log!')),
        );
      }
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
    final List<String> _reasons = [
      context.lang.contactUsReasonNotWorking,
      context.lang.contactUsReasonFeatureRequest,
      context.lang.contactUsReasonQuestion,
      context.lang.contactUsReasonFeedback,
      context.lang.contactUsReasonOther,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpContactUs),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(context.lang.contactUsMessageTitle),
            SizedBox(height: 5),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: context.lang.contactUsYourMessage,
                border: OutlineInputBorder(),
              ),
              minLines: 5,
              maxLines: 10,
            ),
            SizedBox(height: 5),
            Text(
              context.lang.contactUsMessage,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 10,
              ),
            ),
            SizedBox(height: 20),
            Text(context.lang.contactUsReason),
            SizedBox(height: 5),
            DropdownButton<String>(
              hint: Text(context.lang.contactUsSelectOption),
              underline: SizedBox.shrink(),
              value: _selectedReason,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedReason = newValue;
                });
              },
              items: _reasons.map<DropdownMenuItem<String>>((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text(context.lang.contactUsEmojis),
            SizedBox(height: 5),
            FeedbackEmojiRow(
              selectedFeedback: _selectedFeedback,
              onFeedbackChanged: (int? newValue) {
                setState(() {
                  _selectedFeedback = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            IncludeDebugLog(
              isChecked: includeDebugLog,
              onChanged: (value) {
                setState(() {
                  includeDebugLog = value;
                });
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse("https://twonly.eu/en/faq/"));
                    },
                    child: Text(
                      context.lang.contactUsFaq,
                      style: TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (isLoading)
                        ? null
                        : () async {
                            final fullMessage = await _getFeedbackText();
                            if (!context.mounted) return;

                            bool? feedbackSend = await Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return SubmitMessage(
                                fullMessage: fullMessage,
                              );
                            }));

                            if (feedbackSend == true && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(context.lang.next),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IncludeDebugLog extends StatefulWidget {
  final bool isChecked;
  final Function(bool) onChanged;

  const IncludeDebugLog({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  State<IncludeDebugLog> createState() => _IncludeDebugLogState();
}

class _IncludeDebugLogState extends State<IncludeDebugLog> {
  void _launchURL() async {
    const url = 'https://twonly.eu/en/faq/troubleshooting/debug-log.html';
    if (await launchUrl(Uri.parse(url))) {
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.isChecked,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (bool? value) {
            if (value != null) {
              widget.onChanged(value);
            }
          },
        ),
        Text(context.lang.contactUsIncludeLog),
        SizedBox(width: 20),
        GestureDetector(
          onTap: _launchURL,
          child: Text(
            context.lang.contactUsWhatsThat,
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class FeedbackEmojiRow extends StatelessWidget {
  final int? selectedFeedback;
  final ValueChanged<int?> onFeedbackChanged;

  const FeedbackEmojiRow({
    super.key,
    required this.selectedFeedback,
    required this.onFeedbackChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
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
    if (value == null) return "";
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
    bool isSelected = selectedFeedback == value;

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
