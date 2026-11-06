import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OutfitManagementScreen extends StatefulWidget {
  const OutfitManagementScreen({super.key});
  @override
  State<OutfitManagementScreen> createState() => _OutfitManagementScreenState();
}

class _PickedImage {
  const _PickedImage(this.bytes, this.name);
  final Uint8List bytes;
  final String name;
}

class _OutfitManagementScreenState extends State<OutfitManagementScreen> {
  final formKey = GlobalKey<FormState>();
  final outfitName = TextEditingController();
  final extraPrompt = TextEditingController();
  final picker = ImagePicker();
  final List<_PickedImage?> photos = List.filled(5, null);
  _PickedImage? mainPicture;
  _PickedImage? background;
  String gender = 'femme';
  String? category;
  bool makeupAllowed = false;
  bool saving = false;
  int uploadDone = 0;
  int uploadTotal = 0;
  String? deletingId;

  @override
  void dispose() {
    outfitName.dispose();
    extraPrompt.dispose();
    super.dispose();
  }

  Future<void> pickPhoto(int index) async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => photos[index] = _PickedImage(bytes, file.name));
  }

  Future<void> pickMainPicture() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 1800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => mainPicture = _PickedImage(bytes, file.name));
  }

  Future<void> pickBackground() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => background = _PickedImage(bytes, file.name));
  }

  String extension(String name) => name.toLowerCase().endsWith('.png')
      ? 'png'
      : name.toLowerCase().endsWith('.webp')
      ? 'webp'
      : 'jpg';
  String contentType(String name) => extension(name) == 'png'
      ? 'image/png'
      : extension(name) == 'webp'
      ? 'image/webp'
      : 'image/jpeg';

  Future<String> upload(Reference ref, _PickedImage image) async {
    await ref.putData(
      image.bytes,
      SettableMetadata(contentType: contentType(image.name)),
    );
    final url = await ref.getDownloadURL();
    if (mounted) setState(() => uploadDone++);
    return url;
  }

  Future<void> saveOutfit() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    final selectedPhotos = photos.whereType<_PickedImage>().toList();
    if (selectedPhotos.isEmpty) {
      message('Ajoutez au moins une photo de la tenue.');
      return;
    }
    if (category == null || category!.isEmpty) {
      message('Choisissez une categorie.');
      return;
    }
    if (mainPicture == null) {
      message('Ajoutez la photo principale affichee sur l ecran camera.');
      return;
    }
    setState(() {
      saving = true;
      uploadDone = 0;
      uploadTotal = selectedPhotos.length + 1 + (background == null ? 0 : 1);
    });
    try {
      final doc = FirebaseFirestore.instance.collection('outfits').doc();
      final folder = FirebaseStorage.instance.ref('outfits/${doc.id}');
      final mainUrl = await upload(
        folder.child('main.${extension(mainPicture!.name)}'),
        mainPicture!,
      );
      final urls = <String>[];
      for (var i = 0; i < selectedPhotos.length; i++) {
        final photo = selectedPhotos[i];
        urls.add(
          await upload(
            folder.child('reference_${i + 1}.${extension(photo.name)}'),
            photo,
          ),
        );
      }
      String backgroundUrl = '';
      if (background != null)
        backgroundUrl = await upload(
          folder.child('background.${extension(background!.name)}'),
          background!,
        );
      await doc.set({
        'name': outfitName.text.trim(),
        'category': category,
        'gender': gender,
        'imageUrls': urls,
        'thumbnailUrl': mainUrl,
        'mainImageUrl': mainUrl,
        'fullImageUrl': urls.first,
        'backgroundUrl': backgroundUrl,
        'makeupAllowed': gender == 'femme' && makeupAllowed,
        'extraPrompt': extraPrompt.text.trim(),
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      outfitName.clear();
      extraPrompt.clear();
      setState(() {
        for (var i = 0; i < photos.length; i++) {
          photos[i] = null;
        }
        mainPicture = null;
        background = null;
        makeupAllowed = false;
      });
      message('Tenue ajoutee a l ecran principal.');
    } on FirebaseException catch (e) {
      message('Firebase: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteOutfit(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette tenue ?'),
        content: Text(
          '« ${data['name'] ?? ''} » et toutes ses images seront supprimees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => deletingId = doc.id);
    try {
      final items = await FirebaseStorage.instance
          .ref('outfits/${doc.id}')
          .listAll();
      for (final item in items.items) {
        await item.delete();
      }
      await doc.reference.delete();
      message('Tenue supprimee.');
    } on FirebaseException catch (e) {
      message('Firebase: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => deletingId = null);
    }
  }

  void message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      backgroundColor: const Color(0xfff7f5fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Gestion des tenues',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(mobile ? 16 : 30),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ajouter une tenue',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff170635),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ajoutez jusqu a 5 photos de reference pour representer la meme tenue.',
                    style: TextStyle(fontSize: 16, color: Color(0xff655e70)),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: outfitName,
                              enabled: !saving,
                              decoration: const InputDecoration(
                                labelText: 'Nom de la tenue',
                                prefixIcon: Icon(Icons.checkroom_rounded),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nom requis'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'femme',
                                  label: Text('Femme'),
                                ),
                                ButtonSegment(
                                  value: 'homme',
                                  label: Text('Homme'),
                                ),
                              ],
                              selected: {gender},
                              onSelectionChanged: saving
                                  ? null
                                  : (v) => setState(() {
                                      gender = v.first;
                                      category = null;
                                      if (gender == 'homme')
                                        makeupAllowed = false;
                                    }),
                            ),
                            const SizedBox(height: 14),
                            categorySelector,
                            const SizedBox(height: 18),
                            const Text(
                              'Photo principale pour l ecran camera *',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Cette image represente la tenue dans le selecteur du client.',
                              style: TextStyle(color: Color(0xff655e70)),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(height: 190, child: mainPicturePicker),
                            const SizedBox(height: 18),
                            const Text(
                              'Photos de la tenue',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 5,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: mobile ? 2 : 5,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: .82,
                                  ),
                              itemBuilder: (_, i) => imageSlot(i),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Arriere-plan optionnel',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(height: 170, child: optionalBackground),
                            if (gender == 'femme') ...[
                              const SizedBox(height: 14),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Maquillage autorise',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                subtitle: const Text(
                                  'Autoriser l IA a adapter ou ajouter du maquillage.',
                                ),
                                value: makeupAllowed,
                                onChanged: saving
                                    ? null
                                    : (v) => setState(() => makeupAllowed = v),
                              ),
                            ],
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: extraPrompt,
                              enabled: !saving,
                              minLines: 3,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                labelText:
                                    'Instructions supplementaires (optionnel)',
                                hintText:
                                    'Exemple : conserver les broderies dorees et utiliser une lumiere douce...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (saving) ...[
                              LinearProgressIndicator(
                                value: uploadTotal == 0
                                    ? null
                                    : uploadDone / uploadTotal,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Envoi $uploadDone / $uploadTotal',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                            ],
                            FilledButton.icon(
                              onPressed: saving ? null : saveOutfit,
                              icon: const Icon(Icons.cloud_upload_rounded),
                              label: Text(
                                saving ? 'Publication...' : 'Ajouter la tenue',
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                backgroundColor: const Color(0xff5146f5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Tenues actuelles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  outfitList(mobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get categorySelector =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('look_categories')
            .where('gender', isEqualTo: gender)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final names = docs
              .map((d) => d.data()['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          return DropdownButtonFormField<String>(
            initialValue: names.contains(category) ? category : null,
            decoration: const InputDecoration(
              labelText: 'Categorie',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: names
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: saving ? null : (v) => setState(() => category = v),
            validator: (v) => v == null ? 'Categorie requise' : null,
          );
        },
      );

  Widget imageSlot(int index) {
    final photo = photos[index];
    return InkWell(
      onTap: saving ? null : () => pickPhoto(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffeeeaf5),
          borderRadius: BorderRadius.circular(14),
          image: photo == null
              ? null
              : DecorationImage(
                  image: MemoryImage(photo.bytes),
                  fit: BoxFit.cover,
                ),
        ),
        child: photo == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xff5146f5),
                  ),
                  Text(
                    '${index + 1}${index == 0 ? ' *' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => photos[index] = null),
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close_rounded),
                  ),
                ),
              ),
      ),
    );
  }

  Widget get mainPicturePicker => InkWell(
    onTap: saving ? null : pickMainPicture,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xffeeeaf5),
        borderRadius: BorderRadius.circular(14),
        image: mainPicture == null
            ? null
            : DecorationImage(
                image: MemoryImage(mainPicture!.bytes),
                fit: BoxFit.contain,
              ),
      ),
      child: mainPicture == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_outlined, size: 40, color: Color(0xff5146f5)),
                Text('Choisir la photo principale'),
              ],
            )
          : Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: saving
                    ? null
                    : () => setState(() => mainPicture = null),
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close_rounded),
                ),
              ),
            ),
    ),
  );
  Widget get optionalBackground => InkWell(
    onTap: saving ? null : pickBackground,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xffeeeaf5),
        borderRadius: BorderRadius.circular(14),
        image: background == null
            ? null
            : DecorationImage(
                image: MemoryImage(background!.bytes),
                fit: BoxFit.cover,
              ),
      ),
      child: background == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.landscape_outlined,
                  size: 38,
                  color: Color(0xff5146f5),
                ),
                Text('Ajouter un arriere-plan'),
              ],
            )
          : Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: saving
                    ? null
                    : () => setState(() => background = null),
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close_rounded),
                ),
              ),
            ),
    ),
  );

  Widget outfitList(
    bool mobile,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('outfits').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return Text('Firestore: ${snapshot.error}');
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty)
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucune tenue.')),
          ),
        );
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: docs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: mobile ? 1 : 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: mobile ? 2.1 : .85,
        ),
        itemBuilder: (_, i) {
          final doc = docs[i];
          final data = doc.data();
          final url = data['thumbnailUrl'] as String? ?? '';
          final deleting = deletingId == doc.id;
          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: url.isEmpty
                      ? const Icon(Icons.checkroom_rounded, size: 50)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] as String? ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${data['category'] ?? ''} · ${data['gender'] ?? ''}',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: deleting ? null : () => deleteOutfit(doc),
                        icon: deleting
                            ? const SizedBox.square(
                                dimension: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
