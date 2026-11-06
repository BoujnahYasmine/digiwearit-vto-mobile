import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OutfitStudioScreen extends StatefulWidget {
  const OutfitStudioScreen({super.key});
  @override
  State<OutfitStudioScreen> createState() => _OutfitStudioScreenState();
}

class _Draft {
  final name = TextEditingController();
  final category = TextEditingController();
  Uint8List? bytes;
  String fileName = '';
  void dispose() {
    name.dispose();
    category.dispose();
  }
}

class _OutfitStudioScreenState extends State<OutfitStudioScreen> {
  final formKey = GlobalKey<FormState>();
  final drafts = List.generate(5, (_) => _Draft());
  final picker = ImagePicker();
  String gender = 'femme';
  bool publishing = false;
  int uploaded = 0;

  @override
  void dispose() {
    for (final d in drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> pick(int index) async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted)
      setState(() {
        drafts[index].bytes = bytes;
        drafts[index].fileName = file.name;
      });
  }

  String contentType(String name) => name.toLowerCase().endsWith('.png')
      ? 'image/png'
      : name.toLowerCase().endsWith('.webp')
      ? 'image/webp'
      : 'image/jpeg';
  String extension(String name) => name.toLowerCase().endsWith('.png')
      ? 'png'
      : name.toLowerCase().endsWith('.webp')
      ? 'webp'
      : 'jpg';

  Future<void> publish() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    if (drafts.any((d) => d.bytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez les 5 photos avant de publier.')),
      );
      return;
    }
    setState(() {
      publishing = true;
      uploaded = 0;
    });
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      for (var i = 0; i < 5; i++) {
        final d = drafts[i];
        final doc = db.collection('outfits').doc();
        final ref = FirebaseStorage.instance.ref(
          'outfits/${doc.id}/look.${extension(d.fileName)}',
        );
        await ref.putData(
          d.bytes!,
          SettableMetadata(contentType: contentType(d.fileName)),
        );
        final url = await ref.getDownloadURL();
        batch.set(doc, {
          'name': d.name.text.trim(),
          'category': d.category.text.trim(),
          'gender': gender,
          'thumbnailUrl': url,
          'fullImageUrl': url,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() => uploaded = i + 1);
      }
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les 5 tenues sont publiees.')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase: ${e.message ?? e.code}')),
        );
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      backgroundColor: const Color(0xfff7f5fb),
      appBar: AppBar(
        title: const Text(
          'Studio des tenues',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.all(mobile ? 16 : 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Creez 5 looks',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff170635),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ajoutez cinq photos de tenues. Elles seront stockees dans Firebase et disponibles immediatement dans le selecteur de looks.',
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'femme', label: Text('Femme')),
                        ButtonSegment(value: 'homme', label: Text('Homme')),
                      ],
                      selected: {gender},
                      onSelectionChanged: publishing
                          ? null
                          : (v) => setState(() => gender = v.first),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: mobile ? 1 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: mobile ? 1.6 : 1.35,
                      ),
                      itemBuilder: (_, i) => _DraftCard(
                        number: i + 1,
                        draft: drafts[i],
                        enabled: !publishing,
                        onPick: () => pick(i),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (publishing) ...[
                      LinearProgressIndicator(value: uploaded / 5),
                      const SizedBox(height: 8),
                      Text('Envoi $uploaded / 5', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      onPressed: publishing ? null : publish,
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        publishing ? 'Publication...' : 'Publier les 5 tenues',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: const Color(0xff5146f5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.number,
    required this.draft,
    required this.enabled,
    required this.onPick,
  });
  final int number;
  final _Draft draft;
  final bool enabled;
  final VoidCallback onPick;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xffe7e1ee)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: enabled ? onPick : null,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xfff0edf6),
                  borderRadius: BorderRadius.circular(14),
                  image: draft.bytes == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(draft.bytes!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: draft.bytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 38,
                            color: Color(0xff5146f5),
                          ),
                          Text(
                            'Photo $number',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircleAvatar(child: Icon(Icons.edit_outlined)),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: draft.name,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Nom du look',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: draft.category,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: 'Categorie',
                    hintText: 'Caftan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Categorie requise'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
