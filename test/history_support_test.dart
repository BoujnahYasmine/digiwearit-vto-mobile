import 'dart:io';
import 'dart:typed_data';

import 'package:digiwearit2/support_sheet.dart';
import 'package:digiwearit2/try_on_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'history keeps try-ons newest first, survives reload, deletes files',
    () async {
      final root = await Directory.systemTemp.createTemp('history-test');
      addTearDown(() => root.delete(recursive: true));
      final history = TryOnHistory(folder: () async => root);
      await history.add(
        id: 'a',
        outfit: 'Caftan',
        images: [
          Uint8List.fromList([1, 2]),
        ],
      );
      await history.add(
        id: 'b',
        outfit: 'Amazigh',
        images: [
          Uint8List.fromList([3]),
        ],
      );
      await history.add(
        id: 'b',
        outfit: 'Amazigh',
        images: [
          Uint8List.fromList([3]),
        ],
      );

      final reloaded = await TryOnHistory(folder: () async => root).records();
      expect(reloaded.map((r) => r.id), ['b', 'a']);
      expect(File(reloaded.last.files.single).readAsBytesSync(), [1, 2]);

      await history.remove(reloaded.last);
      expect(File(reloaded.last.files.single).existsSync(), isFalse);
      expect(
        (await TryOnHistory(folder: () async => root).records()).length,
        1,
      );
    },
  );

  test('support mail goes to Digiwearit with the try-on reference', () {
    final uri = supportMail(
      reason: SupportReason.refund,
      message: 'Image floue',
      tryOn: TryOnRecord(
        id: 'r-42',
        outfit: 'Caftan',
        date: DateTime(2026, 11, 14, 9, 5),
        files: const [],
      ),
      email: 'client@example.com',
    );
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'hi@digiwearit.com');
    final query = Uri.decodeComponent(uri.query);
    expect(query, contains('Demande de remboursement'));
    expect(query, contains('Référence : r-42'));
    expect(query, contains('14/11/2026 09:05'));
    expect(query, contains('client@example.com'));
    expect(query, contains('Image floue'));
  });
}
