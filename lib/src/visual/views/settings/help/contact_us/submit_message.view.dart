import 'package:flutter/material.dart';
import 'package:twonly/src/services/feedback.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class SubmitMessage extends StatefulWidget {
  const SubmitMessage({required this.fullMessage, this.debugLog, super.key});

  final String fullMessage;
  final FeedbackDebugLog? debugLog;

  @override
  State<SubmitMessage> createState() => _ContactUsState();
}

class _ContactUsState extends State<SubmitMessage> {
  final TextEditingController _controller = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.fullMessage;
  }

  @override
  void dispose() {
    _controller.dispose();
    _feedbackService.close();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final feedback = _controller.text.trim();
    if (feedback.isEmpty) {
      showSnackbar(
        context,
        'Please enter a message.',
        level: SnackbarLevel.info,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final debugLog = widget.debugLog;
      // The preview is editable: removing its log link must also remove the
      // attachment sent to the API.
      final includesLog =
          debugLog != null &&
          feedback.contains(
            'https://logs.twonly.eu#${debugLog.downloadToken}/${debugLog.encryptionKey}',
          );
      await _feedbackService.submit(
        feedback,
        debugLog: includesLog ? debugLog : null,
      );
      if (!mounted) return;
      showSnackbar(
        context,
        context.lang.contactUsSuccess,
        level: SnackbarLevel.success,
      );
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      Log.error(
        'Could not submit feedback.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      showSnackbar(
        context,
        'Failed to submit feedback.',
      );
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
              Text(
                context.lang.contactUsLastWarning,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: context.lang.contactUsYourMessage,
                  border: const OutlineInputBorder(),
                ),
                minLines: 5,
                maxLines: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 40,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyButton(
                      variant: MyButtonVariant.primaryDense,
                      onPressed: isLoading ? null : _submitFeedback,
                      child: Text(context.lang.submit),
                    ),
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
