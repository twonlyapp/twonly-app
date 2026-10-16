import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';

/// Store metadata mirrored from the API.
///
/// A cache, but a refresh keeps the rows an instance on this device runs even
/// once the store stops offering them: an unpublished app keeps working where
/// it was already downloaded. `published` says whether the last catalog still
/// carried the version, which is what the store list goes by.
@DataClassName('WebxdcApp')
class WebxdcApps extends Table {
  TextColumn get appId => text()();
  IntColumn get version => integer()();

  /// What the app is called where no translation fits. Every row has one,
  /// which is what the store orders by.
  TextColumn get name => text()();

  /// The name per language, as a JSON object keyed by language tag, in the same
  /// shape as [description]. The chat card picks from it; the store list is
  /// built in Rust, which picks there.
  TextColumn get nameTranslations => text().withDefault(const Constant('{}'))();

  /// One short line per language, as a JSON object keyed by language tag. Rust
  /// picks the one to show; nothing in Dart reads inside it.
  TextColumn get description => text().withDefault(const Constant('{}'))();
  TextColumn get sourceCodeUrl => text().nullable()();
  BlobColumn get icon => blob().nullable()();
  TextColumn get bundleSha256 => text()();
  IntColumn get bundleBytes => integer()();
  BoolColumn get published => boolean().withDefault(const Constant(true))();
  IntColumn get cachedAt => integer()();
  BoolColumn get proOnly => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get oneTime => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {appId, version};
}

/// One app placed into a chat. The row's id is the id of the message that
/// carries it, so the chat card and the instance are the same object.
@DataClassName('WebxdcInstance')
class WebxdcInstances extends Table {
  TextColumn get instanceId => text().references(
    Messages,
    #messageId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get groupId =>
      text().references(Groups, #groupId, onDelete: KeyAction.cascade)();
  TextColumn get appId => text()();
  IntColumn get version => integer()();
  TextColumn get bundleSha256 => text().nullable()();
  TextColumn get originToken => text()();
  TextColumn get summary => text().nullable()();
  TextColumn get document => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get lastUpdateAt => integer()();

  @override
  Set<Column> get primaryKey => {instanceId};
}

/// The update log. Read-only from Dart: serials are assigned in Rust, and the
/// chat's deletion timer deliberately does not reach this table.
@DataClassName('WebxdcUpdate')
class WebxdcUpdates extends Table {
  TextColumn get instanceId => text().references(
    WebxdcInstances,
    #instanceId,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get serial => integer()();
  TextColumn get messageId => text()();
  IntColumn get senderId => integer().nullable()();
  TextColumn get payload => text()();
  TextColumn get info => text().nullable()();
  TextColumn get href => text().nullable()();
  IntColumn get receivedAt => integer()();

  @override
  Set<Column> get primaryKey => {instanceId, serial};
}
