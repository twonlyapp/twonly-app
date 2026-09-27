import 'package:twonly/src/database/twonly.db.dart';

/// Keeps a row of contact group chips in the order they first appeared.
/// Groups arrive most used first and choosing one counts as a use, so taking
/// every new order as it comes would move a chip away right after it was
/// tapped. Groups that are gone are dropped and new ones go to the end.
/// [seenIds] carries the order from one call to the next.
List<ContactGroup> inFirstSeenOrder(
  List<ContactGroup> contactGroups,
  List<int> seenIds,
) {
  final byId = {for (final group in contactGroups) group.id: group};
  seenIds.removeWhere((id) => !byId.containsKey(id));
  for (final group in contactGroups) {
    if (!seenIds.contains(group.id)) seenIds.add(group.id);
  }
  return [for (final id in seenIds) byId[id]!];
}
