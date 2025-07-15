import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

Future<List<Response_AddAccountsInvite>?> loadAdditionalUserInvites() async {
  final ballance = await apiService.getAdditionalUserInvites();
  if (ballance != null) {
    await updateUserdata((u) {
      u.additionalUserInvites =
          jsonEncode(ballance.map((x) => x.writeToJson()).toList());
      return u;
    });
    return ballance;
  }
  final user = await getUser();
  if (user != null && user.lastPlanBallance != null) {
    try {
      final decoded = jsonDecode(user.additionalUserInvites!) as List<String>;
      return decoded.map(Response_AddAccountsInvite.fromJson).toList();
    } catch (e) {
      Log.error('could not parse additional user json: $e');
    }
  }
  return null;
}

class AdditionalUsersView extends StatefulWidget {
  const AdditionalUsersView({required this.ballance, super.key});

  final Response_PlanBallance? ballance;

  @override
  State<AdditionalUsersView> createState() => _AdditionalUsersViewState();
}

class _AdditionalUsersViewState extends State<AdditionalUsersView> {
  List<Response_AddAccountsInvite>? additionalInvites;
  Response_PlanBallance? ballance;

  @override
  void initState() {
    super.initState();
    ballance = widget.ballance;
    initAsync(force: false);
  }

  Future<void> initAsync({required bool force}) async {
    additionalInvites = await loadAdditionalUserInvites();
    if (force) {
      ballance = await loadPlanBalance();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var plusInvites = <Response_AddAccountsInvite>[];
    var freeInvites = <Response_AddAccountsInvite>[];
    if (additionalInvites != null) {
      plusInvites =
          additionalInvites!.where((x) => x.planId == 'Plus').toList();
      freeInvites =
          additionalInvites!.where((x) => x.planId == 'Free').toList();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manageAdditionalUsers),
      ),
      body: ListView(
        children: [
          if (ballance != null && ballance!.additionalAccounts.isNotEmpty)
            ListTile(
              title: Text(
                context.lang.additionalUsersList,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          if (ballance != null)
            ...ballance!.additionalAccounts.map((e) => AdditionalAccount(
                  account: e,
                  refresh: () {
                    initAsync(force: true);
                  },
                )),
          if (plusInvites.isNotEmpty)
            ListTile(
              title: Text(
                context.lang.additionalUsersPlusTokens,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 16 / 5,
              shrinkWrap: true,
              children: plusInvites.map(AdditionalUserInvite.new).toList(),
            ),
          ),
          if (freeInvites.isNotEmpty)
            ListTile(
              title: Text(
                context.lang.additionalUsersFreeTokens,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 16 / 5,
              shrinkWrap: true,
              children: freeInvites.map(AdditionalUserInvite.new).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class AdditionalAccount extends StatefulWidget {
  const AdditionalAccount({
    required this.account,
    required this.refresh,
    super.key,
  });

  final void Function() refresh;
  final Response_AdditionalAccount account;
  @override
  State<AdditionalAccount> createState() => _AdditionalAccountState();
}

class _AdditionalAccountState extends State<AdditionalAccount> {
  late String username;

  @override
  void initState() {
    super.initState();
    username = widget.account.userId.toString();
    initAsync();
  }

  Future<void> initAsync() async {
    final contact = await twonlyDB.contactsDao
        .getContactByUserId(widget.account.userId.toInt())
        .getSingleOrNull();
    if (contact != null) {
      username = getContactDisplayName(contact);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.account.planId,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.userXmark, size: 16),
              onPressed: () async {
                final remove = await showAlertDialog(
                    context,
                    'Remove this additional user',
                    'The additional user will automatically be downgraded to the preview plan after removal and you will receive a new invitation code to give to another person.');
                if (remove) {
                  final res = await apiService
                      .removeAdditionalUser(widget.account.userId);
                  if (!context.mounted) return;
                  if (res.isSuccess) {
                    widget.refresh();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(errorCodeToText(
                        context,
                        res.error as ErrorCode,
                      ))),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdditionalUserInvite extends StatefulWidget {
  const AdditionalUserInvite(this.invite, {super.key});
  final Response_AddAccountsInvite invite;
  @override
  State<AdditionalUserInvite> createState() => _AdditionalUserInviteState();
}

class _AdditionalUserInviteState extends State<AdditionalUserInvite> {
  void _copyVoucherId() {
    Clipboard.setData(ClipboardData(text: widget.invite.inviteCode));
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.invite.inviteCode} copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copyVoucherId,
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              widget.invite.inviteCode.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
