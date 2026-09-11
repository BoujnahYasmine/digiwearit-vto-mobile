import 'package:flutter/material.dart';

String normalizedGender(String value) {
  switch (value.trim().toLowerCase()) {
    case 'female':
    case 'woman':
    case 'femme':
      return 'femme';
    case 'male':
    case 'man':
    case 'homme':
      return 'homme';
    default:
      return value.trim().toLowerCase();
  }
}

class LookCategory {
  const LookCategory({
    required this.id,
    required this.name,
    required this.gender,
    required this.active,
  });
  final String id;
  final String name;
  final String gender;
  final bool active;

  factory LookCategory.fromFirestore(String id, Map<String, dynamic> data) =>
      LookCategory(
        id: id,
        name: (data['name'] as String? ?? '').trim(),
        gender: normalizedGender(data['gender'] as String? ?? ''),
        active: data['active'] != false,
      );
}

class Outfit {
  const Outfit({
    required this.id,
    required this.name,
    required this.gender,
    required this.category,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    required this.imageUrls,
    required this.backgroundUrl,
    required this.makeupAllowed,
    required this.extraPrompt,
    required this.active,
    required this.color,
    this.description = '',
    this.tags = const [],
    this.isNew = false,
    this.style = '',
    this.categoryId = '',
    this.promptImageUrl = '',
  });

  final String id;
  final String name;
  final String gender;
  final String category;
  final String thumbnailUrl;
  final String fullImageUrl;
  final List<String> imageUrls;
  final String backgroundUrl;
  final bool makeupAllowed;
  final String extraPrompt;
  final bool active;
  final Color color;
  final String description;
  final List<String> tags;
  final bool isNew;
  final String style, categoryId, promptImageUrl;

  factory Outfit.fromFirestore(String id, Map<String, dynamic> data) {
    final activeValue = data['active'];
    String imageField(String primary, String fallback) {
      final value = (data[primary] as String? ?? '').trim();
      return value.isNotEmpty
          ? value
          : (data[fallback] as String? ?? '').trim();
    }

    return Outfit(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Tenue',
      gender: normalizedGender(data['gender'] as String? ?? ''),
      category: (data['category'] as String? ?? '').trim(),
      thumbnailUrl: imageField('thumbnailUrl', 'imageUrl'),
      fullImageUrl: imageField('fullImageUrl', 'imageUrl'),
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      backgroundUrl: data['backgroundUrl'] as String? ?? '',
      makeupAllowed: data['makeupAllowed'] == true,
      extraPrompt:
          data['extraPrompt'] as String? ?? data['promptText'] as String? ?? '',
      active:
          activeValue == true || activeValue.toString().toLowerCase() == 'true',
      color: const Color(0xff6f358c),
      description: data['description'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      isNew: data['isNew'] == true,
      style: data['style'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      promptImageUrl: imageField('promptImageUrl', 'referenceImageUrl'),
    );
  }
}
