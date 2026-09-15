import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

class AddContactViaQrLinkView extends StatefulWidget {
  const AddContactViaQrLinkView({
    required this.profile,
    super.key,
  });

  final PublicProfile profile;

  @override
  State<AddContactViaQrLinkView> createState() =>
      _AddContactViaQrLinkViewState();
}

class _AddContactViaQrLinkViewState extends State<AddContactViaQrLinkView> {
  bool _isLoading = false;

  Future<void> _sendFollowRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await addNewContactFromPublicProfile(widget.profile);
      if (!success) {
        if (mounted) {
          showSnackbar(
            context,
            context.lang.additionalUserAddError(widget.profile.username),
          );
        }
        return;
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnackbar(context, 'Error: $e');
      Log.error(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.addFriendTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 50,
                backgroundColor: context.color.primaryContainer,
                child: FaIcon(
                  FontAwesomeIcons.user,
                  size: 40,
                  color: context.color.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.profile.username,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.color.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.lang.userFoundBody(widget.profile.username),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.color.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 16),
              Center(
                child: FilledButton(
                  onPressed: _isLoading ? null : _sendFollowRequest,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.lang.createContactRequest),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  child: Text(context.lang.cancel),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
