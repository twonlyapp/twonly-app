import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/database/twonly_database_old.dart' as old;
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/utils/log.dart';

part 'contacts.dao.g.dart';

@DriftAccessor(tables: [Contacts])
class ContactsDao extends DatabaseAccessor<TwonlyDB> with _$ContactsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ContactsDao(super.db);

  Future<int?> insertContact(ContactsCompanion contact) async {
    try {
      return await into(contacts).insert(contact);
    } catch (e) {
      Log.error(e);
      return null;
    }
  }

  Future<int> insertOnConflictUpdate(ContactsCompanion contact) async {
    try {
      return await into(contacts).insertOnConflictUpdate(contact);
    } catch (e) {
      Log.error(e);
      return 0;
    }
  }

  SingleOrNullSelectable<Contact> getContactByUserId(int userId) {
    return select(contacts)..where((t) => t.userId.equals(userId));
  }

  Future<Contact?> getContactById(int userId) async {
    return (select(contacts)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<List<Contact>> getContactsByUsername(
    String username, {
    String username2 = '_______',
  }) async {
    return (select(contacts)
          ..where(
            (t) => t.username.equals(username) | t.username.equals(username2),
          ))
        .get();
  }

  Future<void> deleteContactByUserId(int userId) {
    return (delete(contacts)..where((t) => t.userId.equals(userId))).go();
  }

  Future<void> updateContact(
    int userId,
    ContactsCompanion updatedValues,
  ) async {
    await (update(contacts)..where((c) => c.userId.equals(userId)))
        .write(updatedValues);
    if (updatedValues.blocked.present ||
        updatedValues.displayName.present ||
        updatedValues.nickName.present ||
        updatedValues.username.present) {
      final contact = await getContactByUserId(userId).getSingleOrNull();
      if (contact != null) {
        await updatePushUser(contact);
        final group = await twonlyDB.groupsDao.getDirectChat(userId);
        if (group != null) {
          await twonlyDB.groupsDao.updateGroup(
            group.groupId,
            GroupsCompanion(
              groupName: Value(getContactDisplayName(contact)),
            ),
          );
        }
      }
    }
  }

  Stream<List<Contact>> watchNotAcceptedContacts() {
    return (select(contacts)
          ..where(
            (t) =>
                t.accepted.equals(false) &
                t.blocked.equals(false) &
                t.deletedByUser.equals(false),
          ))
        .watch();
  }

  Stream<Contact?> watchContact(int userid) {
    return (select(contacts)..where((t) => t.userId.equals(userid)))
        .watchSingleOrNull();
  }

  Future<List<Contact>> getAllContacts() {
    return select(contacts).get();
  }

  Stream<int?> watchContactsBlocked() {
    final count = contacts.userId.count();
    final query = selectOnly(contacts)
      ..where(contacts.blocked.equals(true))
      ..addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<int?> watchContactsRequested() {
    final count = contacts.requested.count(distinct: true);
    final query = selectOnly(contacts)
      ..where(
        contacts.requested.equals(true) &
            contacts.accepted.equals(false) &
            contacts.deletedByUser.equals(false) &
            contacts.blocked.equals(false),
      )
      ..addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<List<Contact>> watchAllAcceptedContacts() {
    return (select(contacts)
          ..where(
            (t) =>
                t.blocked.equals(false) &
                t.accepted.equals(true) &
                t.accountDeleted.equals(false),
          ))
        .watch();
  }

  Stream<List<Contact>> watchAllContacts() {
    return select(contacts).watch();
  }
}

String getContactDisplayName(Contact user, {int? maxLength}) {
  var name = user.username;
  if (user.nickName != null && user.nickName != '') {
    name = user.nickName!;
  } else if (user.displayName != null) {
    name = user.displayName!;
  }
  if (user.accountDeleted) {
    name = applyStrikethrough(name);
  }
  if (maxLength != null) {
    name = substringBy(name, maxLength);
  }
  return name;
}

String substringBy(String string, int maxLength) {
  if (string.length > maxLength) {
    return '${string.substring(0, maxLength - 3)}...';
  }
  return string;
}

String getContactDisplayNameOld(old.Contact user) {
  var name = user.username;
  if (user.nickName != null && user.nickName != '') {
    name = user.nickName!;
  } else if (user.displayName != null) {
    name = user.displayName!;
  }
  if (user.deleted) {
    name = applyStrikethrough(name);
  }
  if (name.length > 12) {
    return '${name.substring(0, 12)}...';
  }
  return name;
}

String applyStrikethrough(String text) {
  return text.split('').map((char) => '$char\u0336').join();
}
