import 'package:flutter/material.dart';
import 'outfit.dart';
import 'style_selection.dart';

class OutfitSelection extends StyleSelection {
  const OutfitSelection({
    required this.outfit,
    required super.gender,
    required super.english,
    required super.style,
    this.preferredColor,
    this.preferredColorName,
    this.outfits = const [],
  });
  final Outfit outfit;
  final List<Outfit> outfits;

  final Color? preferredColor;
  final String? preferredColorName;
}

String normalizedStyle(String value) {
  final name = value.toLowerCase().trim();
  if (['marocain', 'maroccain', 'moroccan'].contains(name)) return 'moroccan';
  if (['hindien', 'hindian', 'indien', 'indian'].contains(name)) {
    return 'indian';
  }
  if (['espagnol', 'spanish'].contains(name)) return 'spanish';
  if (['moderne', 'modern'].contains(name)) return 'modern';
  return name;
}

String outfitStyle(Outfit outfit) {
  if (outfit.style.isNotEmpty) return outfit.style;
  final legacy = normalizedStyle(outfit.category);
  if (['moroccan', 'indian', 'spanish', 'modern'].contains(legacy))
    return legacy;
  // Legacy records store Moroccan regional categories without a separate style.
  return 'moroccan';
}

String outfitType(Outfit outfit) {
  if (outfit.category.isNotEmpty &&
      ![
        'moroccan',
        'indian',
        'spanish',
        'modern',
      ].contains(normalizedStyle(outfit.category)))
    return outfit.category;
  if (outfit.categoryId.isNotEmpty) return outfit.categoryId;
  final name = outfit.name.toLowerCase();
  if (name.contains('caftan') || name.contains('kaftan')) return 'Caftan';
  if (name.contains('takchita') || name.contains('takshita')) return 'Takchita';
  if (name.contains('fassi')) return 'Fassi';
  if (name.contains('jallaba') ||
      name.contains('jellaba') ||
      name.contains('djellaba')) {
    return 'Jellaba';
  }
  if (name.contains('sah') || name.contains('saah')) return 'Sahraoui';
  return outfit.name;
}
