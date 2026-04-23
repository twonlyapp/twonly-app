import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';

class UserDiscoveryDeveloperView extends StatefulWidget {
  const UserDiscoveryDeveloperView({super.key});

  @override
  State<UserDiscoveryDeveloperView> createState() =>
      _UserDiscoveryDeveloperViewState();
}

class _UserDiscoveryDeveloperViewState
    extends State<UserDiscoveryDeveloperView> {
  UserDiscoveryDao get dao => twonlyDB.userDiscoveryDao;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Contact>>(
      stream: twonlyDB.contactsDao.watchAllContacts(),
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
                stream: dao.watchAllAnnouncedUsers(),
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
                stream: dao.watchAllUserRelations(),
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
                stream: dao.watchAllOtherPromotions(),
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
                stream: dao.watchAllOwnPromotions(),
                itemBuilder: (context, promotion) => ListTile(
                  title: Text('Contact: ${getName(promotion.contactId)}'),
                  subtitle: Text('Version: ${promotion.versionId}'),
                ),
              ),
              _TableExpansionTile<UserDiscoveryShare>(
                title: 'Shares',
                stream: dao.watchAllShares(),
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
                  const ListTile(
                    title: Text(
                      'No entries',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
        );
      },
    );
  }
}
