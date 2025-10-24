import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';

part 'contacts.dao.g.dart';

@DriftAccessor(tables: [Contacts])
class ContactsDao extends DatabaseAccessor<TwonlyDB> with _$ContactsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  ContactsDao(super.db);

  Future<int> insertContact(ContactsCompanion contact) async {
    try {
      return await into(contacts).insert(contact);
    } catch (e) {
      return 0;
    }
  }

  SingleOrNullSelectable<Contact> getContactByUserId(int userId) {
    return select(contacts)..where((t) => t.userId.equals(userId));
  }

  Future<List<Contact>> getContactsByUsername(String username) async {
    return (select(contacts)..where((t) => t.username.equals(username))).get();
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
        updatedValues.nickName.present) {
      final contact = await getContactByUserId(userId).getSingleOrNull();
      if (contact != null) {
        await updatePushUser(contact);
      }
    }
  }

  Stream<List<Contact>> watchNotAcceptedContacts() {
    return (select(contacts)
          ..where(
            (t) => t.accepted.equals(false) & t.blocked.equals(false),
          ))
        .watch();
    // return (select(contacts)).watch();
  }

  Stream<Contact?> watchContact(int userid) {
    return (select(contacts)..where((t) => t.userId.equals(userid)))
        .watchSingleOrNull();
  }

  Future<List<Contact>> getAllNotBlockedContacts() {
    return (select(contacts)..where((t) => t.blocked.equals(false))).get();
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
        contacts.requested.equals(true) & contacts.accepted.equals(true).not(),
      )
      ..addColumns([count]);
    return query.map((row) => row.read(count)).watchSingle();
  }

  Stream<List<Contact>> watchAllAcceptedContacts() {
    return (select(contacts)
          ..where((t) => t.blocked.equals(false) & t.accepted.equals(true)))
        .watch();
  }

  Stream<List<Contact>> watchAllContacts() {
    return select(contacts).watch();
  }
}

String getContactDisplayName(Contact user) {
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
