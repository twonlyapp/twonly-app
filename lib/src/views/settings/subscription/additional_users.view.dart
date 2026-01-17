import 'dart:async';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/subscription/select_additional_users.view.dart';
import 'package:twonly/src/views/settings/subscription_custom/subscription.view.dart';

class AdditionalUsersView extends StatefulWidget {
  const AdditionalUsersView({required this.ballance, super.key});

  final Response_PlanBallance? ballance;

  @override
  State<AdditionalUsersView> createState() => _AdditionalUsersViewState();
}

class _AdditionalUsersViewState extends State<AdditionalUsersView> {
  Response_PlanBallance? ballance;

  late int _unusedAdditionalAccounts;
  int _planLimit = 0;

  @override
  void initState() {
    super.initState();
    ballance = widget.ballance;

    final currentPlan = context.read<PurchasesProvider>().plan;
    if (currentPlan == SubscriptionPlan.Pro ||
        currentPlan == SubscriptionPlan.Tester) {
      _planLimit = 1;
    } else if (currentPlan == SubscriptionPlan.Family) {
      _planLimit = 4;
    }
    _unusedAdditionalAccounts =
        _planLimit - (ballance?.additionalAccounts.length ?? _planLimit);
    unawaited(initAsync(force: false));
  }

  Future<void> initAsync({required bool force}) async {
    if (force) {
      ballance = await loadPlanBalance();
      _unusedAdditionalAccounts =
          _planLimit - (ballance?.additionalAccounts.length ?? _planLimit);
    }
    setState(() {});
  }

  Future<void> addAdditionalUser() async {
    final selectedUserIds = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectAdditionalUsers(
          limit: _planLimit,
          alreadySelected: ballance?.additionalAccounts
                  .map((e) => e.userId.toInt())
                  .toList() ??
              [],
        ),
      ),
    ) as List<int>?;
    if (selectedUserIds == null) return;
    for (final selectedUserId in selectedUserIds) {
      final res = await apiService.addAdditionalUser(Int64(selectedUserId));
      if (res.isError && mounted) {
        final contact =
            await twonlyDB.contactsDao.getContactById(selectedUserId);
        if (contact != null && mounted) {
          if (res.error == ErrorCode.UserIsNotInFreePlan) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.lang.additionalUserAddErrorNotInFreePlan(
                    getContactDisplayName(contact),
                  ),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.lang
                      .additionalUserAddError(getContactDisplayName(contact)),
                ),
              ),
            );
          }
        }
      }
    }
    await initAsync(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.manageAdditionalUsers),
      ),
      body: ListView(
        children: [
          if (_unusedAdditionalAccounts > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: addAdditionalUser,
                  child: Text(
                    context.lang.additionalUserAddButton(
                      _planLimit,
                      ballance?.additionalAccounts.length ?? 0,
                    ),
                  ),
                ),
              ),
            ),
          if (ballance != null && ballance!.additionalAccounts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ListTile(
                title: Text(
                  context.lang.additionalUsersList,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          if (ballance != null)
            ...ballance!.additionalAccounts.map(
              (e) => AdditionalAccount(
                account: e,
                refresh: () async {
                  await initAsync(force: true);
                },
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
    unawaited(initAsync());
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
                  context.lang.additionalUserRemoveTitle,
                  context.lang.additionalUserRemoveDesc,
                );
                if (remove) {
                  final res = await apiService
                      .removeAdditionalUser(widget.account.userId);
                  if (!context.mounted) return;
                  if (res.isSuccess) {
                    widget.refresh();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorCodeToText(
                            context,
                            res.error as ErrorCode,
                          ),
                        ),
                      ),
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
