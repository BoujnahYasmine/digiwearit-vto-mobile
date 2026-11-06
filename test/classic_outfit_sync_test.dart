import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/outfit.dart';
import 'package:digiwearit2/outfit_repository.dart';

void main() {
  test('React outfits match their catalogue and drafts disappear', () {
    final data = <String, dynamic>{
      'name': 'Kimono',
      'category': 'Japonais',
      'style': 'Japonais',
      'gender': 'femme',
      'active': true,
      'thumbnailUrl': 'cover',
      'fullImageUrl': 'reference',
      'promptImageUrl': 'reference',
      'imageUrls': ['reference', 'detail'],
    };
    final outfit = Outfit.fromFirestore('new', data);
    expect(
      OutfitRepository.filter([outfit], gender: 'femme', style: 'Japonais'),
      hasLength(1),
    );
    expect(
      OutfitRepository.filter([outfit], gender: 'homme', style: 'Japonais'),
      isEmpty,
    );
    expect(
      OutfitRepository.filter([outfit], gender: 'femme', style: 'Marocain'),
      isEmpty,
    );
    expect(outfit.imageUrls, hasLength(2));
    final draft = Outfit.fromFirestore('new', {...data, 'active': false});
    expect(
      OutfitRepository.filter([draft], gender: 'femme', style: 'Japonais'),
      isEmpty,
    );
  });
  test('legacy regional categories remain under Moroccan style', () {
    final outfit = Outfit.fromFirestore('old', {
      'name': 'Ait Baamrane',
      'category': 'Ait Baamrane',
      'gender': 'femme',
      'active': true,
    });
    expect(
      OutfitRepository.filter([outfit], gender: 'femme', style: 'Marocain'),
      hasLength(1),
    );
  });
}
