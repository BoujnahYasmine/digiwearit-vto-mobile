import 'package:flutter/material.dart';
import 'catalogue_images.dart';
import 'outfit.dart';

class CataloguePhoto extends StatelessWidget {
  const CataloguePhoto({
    super.key,
    required this.outfit,
    this.fit = BoxFit.cover,
    this.fullResolution = false,
  });
  final Outfit outfit;
  final BoxFit fit;
  final bool fullResolution;
  @override
  Widget build(BuildContext context) {
    final url = !fullResolution && outfit.thumbnailUrl.isNotEmpty
        ? outfit.thumbnailUrl
        : outfit.fullImageUrl;
    final local = catalogueImages[url];
    if (local != null) {
      return Image.asset(
        local,
        fit: fit,
        alignment: Alignment.topCenter,
        excludeFromSemantics: true,
      );
    }
    return Image.network(
      url,
      fit: fit,
      alignment: Alignment.topCenter,
      excludeFromSemantics: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, error, stack) => const ColoredBox(
        color: Color(0xffb6a7bc),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white70,
            size: 40,
          ),
        ),
      ),
    );
  }
}
