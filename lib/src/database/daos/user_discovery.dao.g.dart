// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_discovery.dao.dart';

// ignore_for_file: type=lint
mixin _$UserDiscoveryDaoMixin on DatabaseAccessor<TwonlyDB> {
  $UserDiscoveryAnnouncedUsersTable get userDiscoveryAnnouncedUsers =>
      attachedDatabase.userDiscoveryAnnouncedUsers;
  $ContactsTable get contacts => attachedDatabase.contacts;
  $UserDiscoveryUserRelationsTable get userDiscoveryUserRelations =>
      attachedDatabase.userDiscoveryUserRelations;
  $UserDiscoveryOwnPromotionsTable get userDiscoveryOwnPromotions =>
      attachedDatabase.userDiscoveryOwnPromotions;
  $UserDiscoverySharesTable get userDiscoveryShares =>
      attachedDatabase.userDiscoveryShares;
  UserDiscoveryDaoManager get managers => UserDiscoveryDaoManager(this);
}

class UserDiscoveryDaoManager {
  final _$UserDiscoveryDaoMixin _db;
  UserDiscoveryDaoManager(this._db);
  $$UserDiscoveryAnnouncedUsersTableTableManager
  get userDiscoveryAnnouncedUsers =>
      $$UserDiscoveryAnnouncedUsersTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryAnnouncedUsers,
      );
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db.attachedDatabase, _db.contacts);
  $$UserDiscoveryUserRelationsTableTableManager
  get userDiscoveryUserRelations =>
      $$UserDiscoveryUserRelationsTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryUserRelations,
      );
  $$UserDiscoveryOwnPromotionsTableTableManager
  get userDiscoveryOwnPromotions =>
      $$UserDiscoveryOwnPromotionsTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryOwnPromotions,
      );
  $$UserDiscoverySharesTableTableManager get userDiscoveryShares =>
      $$UserDiscoverySharesTableTableManager(
        _db.attachedDatabase,
        _db.userDiscoveryShares,
      );
}
