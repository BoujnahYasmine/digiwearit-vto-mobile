import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/outfit.dart';
import 'package:digiwearit2/try_on_request.dart';

void main() {
  test('uses all five references even with a primary prompt image', () {
    final outfit = Outfit.fromFirestore('test', {
      'name': 'Test',
      'promptImageUrl': 'one.png',
      'imageUrls': [
        'one.png',
        'two.png',
        'three.png',
        'four.png',
        'five.png',
        'six.png',
      ],
    });
    final request = TryOnRequest(
      userPhotoBytes: Uint8List(0),
      outfit: outfit,
      gender: 'femme',
      style: 'Test',
      category: 'Test',
    );
    expect(request.lookImageUrls, [
      'one.png',
      'two.png',
      'three.png',
      'four.png',
      'five.png',
    ]);
  });
}
