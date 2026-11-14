import 'package:digiwearit2/outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category flag: admin code, explicit none, or never set', () {
    expect(
      LookCategory.fromFirestore('a', {'name': 'X', 'flag': 'MA'}).flag,
      'MA',
    );
    expect(
      LookCategory.fromFirestore('a', {'name': 'X', 'flag': null}).flag,
      '',
    );
    expect(
      LookCategory.fromFirestore('a', {'name': 'X', 'flag': 'bad'}).flag,
      '',
    );
    expect(LookCategory.fromFirestore('a', {'name': 'X'}).flag, isNull);
  });
}
