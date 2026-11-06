/// Customer-facing mirror content. Only fields that are safe to display are
/// carried: backend internals (promptText, promptImageUrl, enterpriseId,
/// catalogId internals, AI configuration) never reach these models.
class MirrorOutfit {
  const MirrorOutfit({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.gender,
  });
  final String id;
  final String name;
  final String imageUrl;
  final String? gender;

  bool matchesGender(String? choice) {
    if (choice == null) return true;
    final target = choice == "femme"
        ? "female"
        : choice == "homme"
        ? "male"
        : choice;
    final value = gender?.trim().toLowerCase();
    return value == target ||
        value == "unisex" ||
        (target == "female" && value == "femme") ||
        (target == "male" && value == "homme");
  }
}

class MirrorCatalogue {
  const MirrorCatalogue({
    required this.id,
    required this.name,
    this.imageUrl,
    this.gender,
    this.outfits = const [],
  });
  final String id;
  final String name;
  final String? imageUrl;
  final String? gender;
  final List<MirrorOutfit> outfits;
}

class MirrorContent {
  const MirrorContent({
    required this.enterpriseName,
    required this.enterpriseId,
    this.logoUrl,
    this.plan,
    this.remainingQuota,
    this.catalogues = const [],
  });
  final String enterpriseName;
  final String enterpriseId;
  final String? logoUrl;
  final String? plan;
  final int? remainingQuota;
  final List<MirrorCatalogue> catalogues;
}
