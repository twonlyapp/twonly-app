enum SetupProfile { standard, customized, maximum }

enum SecurityProfile { normal, strict }

extension SecurityProfileExtension on SecurityProfile {
  bool get showWarningForNonVerifiedContacts => this == SecurityProfile.strict;
}
