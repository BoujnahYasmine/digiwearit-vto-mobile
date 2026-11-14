import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'support_sheet.dart';
import 'try_on_history.dart';

String historyDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
}

/// Grid of past try-ons, newest first.
class HistoryGrid extends StatelessWidget {
  const HistoryGrid({
    super.key,
    required this.records,
    required this.onChanged,
  });
  final List<TryOnRecord> records;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text(
          'Vos essayages apparaîtront ici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: records.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .72,
      ),
      itemBuilder: (context, i) {
        final record = records[i];
        return Material(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('history-${record.id}'),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryPhotoScreen(record: record),
                ),
              );
              onChanged();
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (record.files.isNotEmpty)
                  Image.file(
                    File(record.files.first),
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, e, s) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 14, 6, 5),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xcc120e22)],
                      ),
                    ),
                    child: Text(
                      record.outfit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One past try-on: its photos, share, report a problem, delete.
class HistoryPhotoScreen extends StatefulWidget {
  const HistoryPhotoScreen({super.key, required this.record});
  final TryOnRecord record;
  @override
  State<HistoryPhotoScreen> createState() => _HistoryPhotoScreenState();
}

class _HistoryPhotoScreenState extends State<HistoryPhotoScreen> {
  int index = 0;

  Future<void> share() async {
    final path = widget.record.files[index];
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: 'Mon essayage Digiwearit ✨'),
    );
  }

  Future<void> delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet essayage ?'),
        content: const Text('La photo sera effacée de ce téléphone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TryOnHistory.instance.remove(widget.record);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    return Scaffold(
      backgroundColor: const Color(0xff11101b),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.outfit, style: const TextStyle(fontSize: 17)),
            Text(
              historyDate(record.date),
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Supprimer',
            onPressed: delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: record.files.isEmpty
                  ? const SizedBox()
                  : PageView.builder(
                      itemCount: record.files.length,
                      onPageChanged: (i) => setState(() => index = i),
                      itemBuilder: (_, i) => InteractiveViewer(
                        child: Image.file(
                          File(record.files[i]),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            ),
            if (record.files.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${index + 1}/${record.files.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: record.files.isEmpty ? null : share,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Partager'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('history-report'),
                      onPressed: () => showSupportSheet(context, tryOn: record),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffffc4d8),
                        side: const BorderSide(color: Color(0x88ffc4d8)),
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.report_gmailerrorred),
                      label: const Text('Signaler'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
