// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_verification.dao.dart';

// ignore_for_file: type=lint
mixin _$KeyVerificationDaoMixin on DatabaseAccessor<TwonlyDB> {
  $ContactsTable get contacts => attachedDatabase.contacts;
  $VerificationTokensTable get verificationTokens =>
      attachedDatabase.verificationTokens;
  $KeyVerificationsTable get keyVerifications =>
      attachedDatabase.keyVerifications;
  $GroupsTable get groups => attachedDatabase.groups;
  $GroupMembersTable get groupMembers => attachedDatabase.groupMembers;
  $UserDiscoveryAnnouncedUsersTable get userDiscoveryAnnouncedUsers =>
      attachedDatabase.userDiscoveryAnnouncedUsers;
  $UserDiscoveryUserRelationsTable get userDiscoveryUserRelations =>
      attachedDatabase.userDiscoveryUserRelations;
  KeyVerificationDaoManager get managers => KeyVerificationDaoManager(this);
}

class KeyVerificationDaoManager {
  final _$KeyVerificationDaoMixin _db;
  KeyVerificationDaoManager(this._db);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$VerificationTokensTableTableManager get verificationTokens =>
      $$VerificationTokensTableTableManager(
        _db.attachedDatabase,
        _db.verificationTokens,
      );
  $$KeyVerificationsTableTableManager get keyVerifications =>
      $$KeyVerificationsTableTableManager(
        _db.attachedDatabase,
        _db.keyVerifications,
      );
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db.attachedDatabase, _db.groupMembers);
  $$UserDiscoveryAnnouncedUsersTableTableManager
  get userDiscoveryAnnouncedUsers =>
      $$UserDiscoveryAnnouncedUsersTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryAnnouncedUsers,
      );
  $$UserDiscoveryUserRelationsTableTableManager
  get userDiscoveryUserRelations =>
      $$UserDiscoveryUserRelationsTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryUserRelations,
      );
}
