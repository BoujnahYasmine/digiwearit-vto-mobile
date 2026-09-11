import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_startup.dart';
import 'outfit.dart';
import 'outfit_selection.dart';

class OutfitRepository {
  Stream<List<Outfit>> watchOutfits() async* {
    await FirebaseStartup.ensureReady().timeout(const Duration(seconds: 20));
    yield* FirebaseFirestore.instance
        .collection('outfits')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Outfit.fromFirestore(d.id, d.data())).toList(),
        );
  }

  Stream<List<LookCategory>> watchStyles() async* {
    await FirebaseStartup.ensureReady();
    yield* FirebaseFirestore.instance
        .collection('look_categories')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => LookCategory.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  static List<Outfit> filter(
    Iterable<Outfit> items, {
    required String gender,
    required String style,
    String? category,
  }) => items
      .where(
        (o) =>
            o.active &&
            normalizedGender(o.gender) == normalizedGender(gender) &&
            normalizedStyle(outfitStyle(o)) == normalizedStyle(style) &&
            (category == null ||
                outfitType(o) == category ||
                o.categoryId == category),
      )
      .toList();
  Stream<List<Outfit>> getOutfits({
    required String gender,
    required String style,
    String? category,
  }) => watchOutfits().map(
    (items) => filter(items, gender: gender, style: style, category: category),
  );
  Stream<List<Outfit>> getCategories({
    required String gender,
    required String style,
  }) => getOutfits(
    gender: gender,
    style: style,
  ).map((items) => {for (final o in items) outfitType(o): o}.values.toList());
  Future<Outfit?> getOutfitById(String id) async {
    await FirebaseStartup.ensureReady();
    final doc = await FirebaseFirestore.instance
        .collection('outfits')
        .doc(id)
        .get();
    return doc.exists ? Outfit.fromFirestore(doc.id, doc.data()!) : null;
  }
}
