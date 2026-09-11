import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'try_on_request.dart';
import 'try_on_prompt.dart';

class NanoBananaService {
  NanoBananaService({Future<Part> Function(String)? imageLoader})
    : loadImage = imageLoader ?? _imagePartFromUrl;
  final Future<Part> Function(String) loadImage;
  Future<List<Part>> buildInput(TryOnRequest request) async {
    final referenceUrls = request.lookImageUrls.isNotEmpty
        ? request.lookImageUrls.take(5).toList()
        : <String>[if (request.lookImageUrl.isNotEmpty) request.lookImageUrl];
    if (referenceUrls.isEmpty) {
      throw Exception("Cette tenue n'a pas d'image de reference.");
    }
    final outfitParts = <Part>[];
    for (final url in referenceUrls) {
      outfitParts.add(await loadImage(url));
    }
    Part? backgroundPart;
    if (request.backgroundUrl.isNotEmpty) {
      backgroundPart = await loadImage(request.backgroundUrl);
    }
    return [
      TextPart(
        'Selected garment metadata: gender=${request.gender}; style=${request.style}; category=${request.category}; outfit=${request.lookName}.',
      ),
      TextPart(
        buildTryOnPrompt(request, hasBackground: backgroundPart != null),
      ),
      TextPart(
        'IMAGE 1 â€” USER BASE PHOTO. Preserve this person, pose, crop and visible '
        'body area. Edit clothing, and only admin-enabled makeup or background:',
      ),
      if (request.preferredColorName != null)
        TextPart(
          'USER COLOR CHOICE: Change only the base fabric color of the '
          'selected outfit to ${request.preferredColorName}. This explicitly '
          'overrides reference base-fabric color matching. Keep embroidery, '
          'trims, garment design, and all protected user regions unchanged.',
        ),
      InlineDataPart(
        _imageMimeType(request.userPhotoBytes),
        request.userPhotoBytes,
      ),
      for (var index = 0; index < outfitParts.length; index++) ...[
        TextPart(
          'OUTFIT REFERENCE ${index + 1} OF ${outfitParts.length}. Extract '
          'garment information only. Do not copy this model or composition:',
        ),
        outfitParts[index],
      ],
      if (backgroundPart != null) ...[
        TextPart(
          'OPTIONAL BACKGROUND REFERENCE. Use only if the earlier instruction '
          'explicitly requests a background replacement:',
        ),
        backgroundPart,
      ],
    ];
  }

  Future<List<Uint8List>> generate(
    TryOnRequest request, {
    void Function(int)? onStage,
  }) async {
    final ai = FirebaseAI.agentPlatform(location: 'global');
    final model = ai.generativeModel(
      model: 'gemini-3.1-flash-image',
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
      ),
    );
    onStage?.call(1);
    final response = await model
        .generateContent([Content.multi(await buildInput(request))])
        .timeout(const Duration(minutes: 2));
    if (response.inlineDataParts.isEmpty) {
      throw Exception(
        "Digiwearit AI n'a retourn\u00e9 aucune image. R\u00e9essayez avec une photo plus nette.",
      );
    }
    final codec = await instantiateImageCodec(
      response.inlineDataParts.first.bytes,
    );
    final frame = await codec.getNextFrame();
    frame.image.dispose();
    codec.dispose();

    return response.inlineDataParts.map((part) => part.bytes).toList();
  }

  static Future<Part> _imagePartFromUrl(String url) async {
    final storageUri = _firebaseStorageUri(url);
    if (storageUri != null) {
      return FileData(_imageMimeTypeFromUrl(url), storageUri);
    }

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        "Impossible de charger une image de la tenue (${response.statusCode}).",
      );
    }
    return InlineDataPart(
      _imageMimeType(response.bodyBytes),
      response.bodyBytes,
    );
  }

  static String? _firebaseStorageUri(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'firebasestorage.googleapis.com') {
      return null;
    }
    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('b');
    final objectIndex = segments.indexOf('o');
    if (bucketIndex < 0 ||
        objectIndex < 0 ||
        bucketIndex + 1 >= segments.length ||
        objectIndex + 1 >= segments.length) {
      return null;
    }
    final bucket = segments[bucketIndex + 1];
    final objectPath = segments.sublist(objectIndex + 1).join('/');
    return 'gs://$bucket/$objectPath';
  }

  static String _imageMimeTypeFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _imageMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
