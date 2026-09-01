import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/subscription/select_additional_users.view.dart';

class AdditionalUsersView extends StatefulWidget {
  const AdditionalUsersView({required this.ballance, super.key});

  final FrbPlanBalance? ballance;

  @override
  State<AdditionalUsersView> createState() => _AdditionalUsersViewState();
}

class _AdditionalUsersViewState extends State<AdditionalUsersView> {
  FrbPlanBalance? ballance;

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
      try {
        ballance = await RustApi.loadPlanBalance();
      } catch (_) {
        ballance = null;
      }
      _unusedAdditionalAccounts =
          _planLimit - (ballance?.additionalAccounts.length ?? _planLimit);
    }
    setState(() {});
  }

  Future<void> addAdditionalUser() async {
    final selectedUserIds =
        await context.navPush(
              SelectAdditionalUsers(
                limit: _planLimit,
                alreadySelected:
                    ballance?.additionalAccounts
                        .map((e) => e.userId)
                        .toList() ??
                    [],
              ),
            )
            as List<int>?;
    if (selectedUserIds == null) return;
    for (final selectedUserId in selectedUserIds) {
      final res = await rustApiResult(
        RustApi.addAdditionalUser(userId: selectedUserId),
      );
      if (res.isError && mounted) {
        final contact = await twonlyDB.contactsDao.getContactById(
          selectedUserId,
        );
        if (contact != null && mounted) {
          if (res.error == ErrorCode.UserIsNotInFreePlan) {
            showSnackbar(
              context,
              context.lang.additionalUserAddErrorNotInFreePlan(
                getContactDisplayName(contact),
              ),
              level: SnackbarLevel.info,
            );
          } else {
            showSnackbar(
              context,
              context.lang.additionalUserAddError(
                getContactDisplayName(contact),
              ),
              level: SnackbarLevel.info,
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
                child: MyButton(
                  variant: MyButtonVariant.primaryMiddle,
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
  final FrbAdditionalAccount account;
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
        .getContactByUserId(widget.account.userId)
        .getSingleOrNull();
    if (contact != null) {
      username = getContactDisplayName(contact);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        elevation: 0,
        color: context.color.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AvatarIcon(contactId: widget.account.userId, fontSize: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.account.planId,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.userXmark,
                  size: 16,
                  color: context.color.onSurfaceVariant,
                ),
                onPressed: () async {
                  final remove = await showAlertDialog(
                    context,
                    context.lang.additionalUserRemoveTitle,
                    context.lang.additionalUserRemoveDesc,
                  );
                  if (remove) {
                    final res = await rustApiResult(
                      RustApi.removeAdditionalUser(
                        userId: widget.account.userId,
                      ),
                    );
                    if (!context.mounted) return;
                    if (res.isSuccess) {
                      widget.refresh();
                    } else {
                      showSnackbar(
                        context,
                        errorCodeToText(
                          context,
                          res.error!,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
