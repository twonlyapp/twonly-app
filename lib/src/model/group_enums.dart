const int defaultDeleteMessagesAfterMilliseconds = 1000 * 60 * 60 * 24;

// Persisted enum names must stay compatible with the Rust database.

enum MemberState { normal, admin, leftGroup }

enum GroupActionType {
  createdGroup,
  removedMember,
  addMember,
  leftGroup,
  promoteToAdmin,
  demoteToMember,
  updatedGroupName,
  changeDisplayMaxTime,
  updatedContactUsername,
  updatedContactDisplayName,
}
