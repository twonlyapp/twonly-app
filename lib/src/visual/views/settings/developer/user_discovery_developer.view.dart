import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/user_discovery.dart'
    as rust_user_discovery;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/user_discovery/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';

class UserDiscoveryDeveloperView extends StatefulWidget {
  const UserDiscoveryDeveloperView({super.key});

  @override
  State<UserDiscoveryDeveloperView> createState() =>
      _UserDiscoveryDeveloperViewState();
}

class _UserDiscoveryDeveloperViewState
    extends State<UserDiscoveryDeveloperView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Contact>>(
      stream: watchRustDatabase(
        (control) => rust_contacts.watchContacts(
          input: db_contacts.ContactQuery(
            filter: db_contacts.ContactFilter.all,
            ids: Int64List(0),
          ),
          control: control,
        ),
      ),
      builder: (context, contactSnapshot) {
        final contacts = contactSnapshot.data ?? [];
        final contactNames = {for (final c in contacts) c.userId: c.username};

        String getName(int? id) {
          if (id == null) return 'None';
          return contactNames[id] ?? 'ID: $id';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Discovery Debug'),
          ),
          body: ListView(
            children: [
              _TableExpansionTile<UserDiscoveryAnnouncedUser>(
                title: 'Announced Users',
                stream: watchRustDatabase(
                  (control) => rust_user_discovery.watchDiscoveryAnnouncements(
                    control: control,
                  ),
                ),
                itemBuilder: (context, user) => ListTile(
                  title: Text(user.username ?? 'No Username'),
                  subtitle: Text(
                    'ID: ${getName(user.announcedUserId)}\n'
                    'Public ID: ${user.publicId}\n'
                    'Shown: ${user.wasShownToTheUser}, Hidden: ${user.isHidden}',
                  ),
                  isThreeLine: true,
                ),
              ),
              _TableExpansionTile<UserDiscoveryUserRelation>(
                title: 'User Relations',
                stream: watchRustDatabase(
                  (control) => rust_user_discovery.watchDiscoveryRelations(
                    control: control,
                  ),
                ),
                itemBuilder: (context, relation) => ListTile(
                  title: Text(
                    'From: ${getName(relation.fromContactId)} → To: ${getName(relation.announcedUserId)}',
                  ),
                  subtitle: Text(
                    'Verified: ${relation.publicKeyVerifiedTimestamp}',
                  ),
                ),
              ),
              _TableExpansionTile<UserDiscoveryOtherPromotion>(
                title: 'Other Promotions',
                stream: watchRustDatabase(
                  (control) => rust_user_discovery
                      .watchDiscoveryOtherPromotions(control: control),
                ),
                itemBuilder: (context, promotion) => ListTile(
                  title: Text(
                    'From: ${getName(promotion.fromContactId)}, Public ID: ${promotion.publicId}',
                  ),
                  subtitle: Text(
                    'ID: ${promotion.promotionId}, Threshold: ${promotion.threshold}\n'
                    'Verified: ${promotion.publicKeyVerifiedTimestamp}',
                  ),
                  isThreeLine: true,
                ),
              ),
              _TableExpansionTile<UserDiscoveryOwnPromotion>(
                title: 'Own Promotions',
                stream: watchRustDatabase(
                  (control) => rust_user_discovery.watchDiscoveryOwnPromotions(
                    control: control,
                  ),
                ),
                itemBuilder: (context, promotion) => ListTile(
                  title: Text('Contact: ${getName(promotion.contactId)}'),
                  subtitle: Text('Version: ${promotion.versionId}'),
                ),
              ),
              _TableExpansionTile<UserDiscoveryShare>(
                title: 'Shares',
                stream: watchRustDatabase(
                  (control) => rust_user_discovery.watchDiscoveryShares(
                    control: control,
                  ),
                ),
                itemBuilder: (context, share) => ListTile(
                  title: Text('Share ID: ${share.shareId}'),
                  subtitle: Text('Contact: ${getName(share.contactId)}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableExpansionTile<T> extends StatelessWidget {
  const _TableExpansionTile({
    required this.title,
    required this.stream,
    required this.itemBuilder,
  });
  final String title;
  final Stream<List<T>> stream;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        return ExpansionTile(
          title: Text(
            '$title (${data.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: data.isNotEmpty
              ? data.map((item) => itemBuilder(context, item)).toList()
              : [
                  ListTile(
                    title: Text(
                      'No entries',
                      style: TextStyle(color: context.color.onSurfaceVariant),
                    ),
                  ),
                ],
        );
      },
    );
  }
}
