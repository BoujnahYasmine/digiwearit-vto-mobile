import 'dart:typed_data';
import 'outfit.dart';

class TryOnRequest {
  const TryOnRequest({
    required this.userPhotoBytes,
    required this.outfit,
    required this.gender,
    required this.style,
    required this.category,
    this.preferredColorName,
  });
  final Uint8List userPhotoBytes;
  final Outfit outfit;
  final String gender, style, category;
  final String? preferredColorName;
  String get lookName => outfit.name;
  String get lookImageUrl => outfit.promptImageUrl.isNotEmpty
      ? outfit.promptImageUrl
      : outfit.fullImageUrl.isNotEmpty
      ? outfit.fullImageUrl
      : outfit.thumbnailUrl;
  List<String> get lookImageUrls => <String>{
    if (outfit.promptImageUrl.isNotEmpty) outfit.promptImageUrl,
    ...outfit.imageUrls.where((url) => url.isNotEmpty),
  }.take(5).toList();
  String get backgroundUrl => outfit.backgroundUrl;
  bool get makeupAllowed => outfit.makeupAllowed;
  String get extraPrompt => outfit.extraPrompt;
}
