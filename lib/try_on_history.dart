import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One past try-on kept on this phone.
class TryOnRecord {
  const TryOnRecord({
    required this.id,
    required this.outfit,
    required this.date,
    required this.files,
  });
  final String id, outfit;
  final DateTime date;
  final List<String> files;

  Map<String, dynamic> toJson() => {
    'id': id,
    'outfit': outfit,
    'date': date.toIso8601String(),
    'files': files,
  };

  static TryOnRecord? fromJson(Object? value) {
    if (value is! Map) return null;
    final date = DateTime.tryParse('${value['date']}');
    final files = value['files'];
    if (value['id'] is! String || date == null || files is! List) return null;
    return TryOnRecord(
      id: value['id'] as String,
      outfit: value['outfit'] is String ? value['outfit'] as String : '',
      date: date,
      files: files.whereType<String>().toList(),
    );
  }
}

/// The customer's try-on photos, saved in the app's private folder (never
/// in the gallery) so they can be seen again from the profile.
class TryOnHistory {
  TryOnHistory({Future<Directory> Function()? folder})
    : _folder = folder ?? getApplicationDocumentsDirectory;

  static TryOnHistory instance = TryOnHistory();
  static const keep = 50;

  final Future<Directory> Function() _folder;
  List<TryOnRecord>? _records;

  Future<Directory> _dir() async {
    final dir = Directory('${(await _folder()).path}/tryons');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _index() async => File('${(await _dir()).path}/index.json');

  /// Newest first; empty when storage is unavailable (web, tests).
  Future<List<TryOnRecord>> records() async {
    if (_records != null) return _records!;
    if (kIsWeb) return _records = [];
    try {
      final index = await _index();
      if (!await index.exists()) return _records = [];
      final data = jsonDecode(await index.readAsString());
      return _records = (data is List ? data : const [])
          .map(TryOnRecord.fromJson)
          .whereType<TryOnRecord>()
          .toList();
    } catch (_) {
      return _records = [];
    }
  }

  Future<void> _write(List<TryOnRecord> list) async {
    _records = list;
    await (await _index()).writeAsString(
      jsonEncode([for (final r in list) r.toJson()]),
    );
  }

  Future<void> add({
    required String id,
    required String outfit,
    required List<Uint8List> images,
  }) async {
    if (kIsWeb || images.isEmpty) return;
    try {
      final list = [...await records()];
      if (list.any((r) => r.id == id)) return;
      final dir = await _dir();
      final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final files = <String>[];
      for (var i = 0; i < images.length; i++) {
        final file = File('${dir.path}/${safe}_$i.jpg');
        await file.writeAsBytes(images[i]);
        files.add(file.path);
      }
      list.insert(
        0,
        TryOnRecord(id: id, outfit: outfit, date: DateTime.now(), files: files),
      );
      while (list.length > keep) {
        await _deleteFiles(list.removeLast());
      }
      await _write(list);
    } catch (error) {
      debugPrint('Try-on history not saved: $error');
    }
  }

  Future<void> remove(TryOnRecord record) async {
    final list = [...await records()]..removeWhere((r) => r.id == record.id);
    await _deleteFiles(record);
    try {
      await _write(list);
    } catch (_) {}
  }

  Future<void> clear() async {
    for (final record in [...await records()]) {
      await _deleteFiles(record);
    }
    try {
      await _write([]);
    } catch (_) {}
  }

  Future<void> _deleteFiles(TryOnRecord record) async {
    for (final path in record.files) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }
}
