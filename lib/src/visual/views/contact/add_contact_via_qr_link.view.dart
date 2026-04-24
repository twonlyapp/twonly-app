import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';

class AddContactViaQrLinkView extends StatefulWidget {
  const AddContactViaQrLinkView({
    required this.profile,
    this.qrCodeLink,
    super.key,
  });

  final PublicProfile profile;
  final String? qrCodeLink;

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
      final userData = server.Response_UserData(
        userId: widget.profile.userId,
        publicIdentityKey: widget.profile.publicIdentityKey,
        signedPrekey: widget.profile.signedPrekey,
        signedPrekeySignature: widget.profile.signedPrekeySignature,
        signedPrekeyId: widget.profile.signedPrekeyId,
        username: utf8.encode(widget.profile.username),
        registrationId: widget.profile.registrationId,
      );

      final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
        ContactsCompanion(
          username: Value(widget.profile.username),
          userId: Value(widget.profile.userId.toInt()),
          requested: const Value(false),
          blocked: const Value(false),
          deletedByUser: const Value(false),
        ),
      );

      if (added > 0) {
        await importSignalContactAndCreateRequest(userData);
        if (widget.qrCodeLink != null) {
          // As the user does now exist he can now be marked as verified
          await QrCodeUtils.handleQrCodeLink(widget.qrCodeLink!);
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
                context.lang.userFoundBody,
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
                          child: CircularProgressIndicator(
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
