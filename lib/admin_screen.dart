import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'outfit_management_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminDashboard();
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      backgroundColor: const Color(0xfff7f5fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'lib/logo digiwearit.png',
              height: 32,
              errorBuilder: (_, _, _) => const Icon(Icons.checkroom_rounded),
            ),
            const SizedBox(width: 10),
            const Text(
              'Administration',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Retour a l application',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.storefront_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 16 : 36,
          vertical: narrow ? 24 : 40,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff170635),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Gerez le catalogue visible dans l experience Digiwearit.',
                    style: TextStyle(fontSize: 16, color: Color(0xff655e70)),
                  ),
                  const SizedBox(height: 28),
                  if (narrow) ...[
                    _AdminSectionCard(
                      collection: 'look_categories',
                      icon: Icons.category_rounded,
                      title: 'Categories',
                      description: 'Creer et supprimer les types de looks.',
                      color: Color(0xff5146f5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const _CategoryAdminScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AdminSectionCard(
                      collection: 'outfits',
                      icon: Icons.checkroom_rounded,
                      title: 'Tenues',
                      description:
                          'Ajouter les images et regler la generation IA.',
                      color: Color(0xffff5c91),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const OutfitManagementScreen(),
                        ),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _AdminSectionCard(
                            collection: 'look_categories',
                            icon: Icons.category_rounded,
                            title: 'Categories',
                            description:
                                'Creer et supprimer les types de looks.',
                            color: Color(0xff5146f5),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const _CategoryAdminScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _AdminSectionCard(
                            collection: 'outfits',
                            icon: Icons.checkroom_rounded,
                            title: 'Tenues',
                            description:
                                'Ajouter les images et regler la generation IA.',
                            color: Color(0xffff5c91),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OutfitManagementScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xffeeeaff),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xff5146f5),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Commencez par creer les categories. Vous pourrez ensuite associer chaque tenue a une categorie.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.collection,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });
  final String collection;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 230),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffe7e1ee)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const Spacer(),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(collection)
                      .snapshots(),
                  builder: (_, snapshot) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1eef5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      snapshot.hasData
                          ? '${snapshot.data!.docs.length}'
                          : '...',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xff170635),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              style: const TextStyle(color: Color(0xff655e70), height: 1.4),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Gerer',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, size: 18, color: color),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _CategoryAdminScreen extends StatefulWidget {
  const _CategoryAdminScreen();
  @override
  State<_CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends State<_CategoryAdminScreen> {
  final formKey = GlobalKey<FormState>();
  final categoryName = TextEditingController();
  String gender = 'femme';
  bool saving = false;
  bool bootstrapping = true;
  String? deletingId;

  @override
  void initState() {
    super.initState();
    bootstrapExistingCategories();
  }

  @override
  void dispose() {
    categoryName.dispose();
    super.dispose();
  }

  Future<void> bootstrapExistingCategories() async {
    try {
      final categories = FirebaseFirestore.instance.collection(
        'look_categories',
      );
      final existing = await categories.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final outfits = await FirebaseFirestore.instance
          .collection('outfits')
          .get();
      final unique = <String, ({String name, String gender})>{};
      for (final doc in outfits.docs) {
        final data = doc.data();
        final name = (data['category'] as String? ?? '').trim();
        final itemGender = (data['gender'] as String? ?? '').toLowerCase();
        if (name.isNotEmpty &&
            (itemGender == 'femme' || itemGender == 'homme')) {
          unique['$itemGender:${name.toLowerCase()}'] = (
            name: name,
            gender: itemGender,
          );
        }
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final item in unique.values) {
        final doc = categories.doc();
        batch.set(doc, {
          'name': item.name,
          'gender': item.gender,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (unique.isNotEmpty) await batch.commit();
    } on FirebaseException catch (e) {
      message('Import Firebase: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => bootstrapping = false);
    }
  }

  Future<void> addCategory() async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final collection = FirebaseFirestore.instance.collection(
        'look_categories',
      );
      final snapshot = await collection
          .where('gender', isEqualTo: gender)
          .get();
      final wanted = categoryName.text.trim().toLowerCase();
      final duplicate = snapshot.docs.any(
        (doc) =>
            (doc.data()['name'] as String? ?? '').trim().toLowerCase() ==
            wanted,
      );
      if (duplicate) {
        message('Cette categorie existe deja pour ce genre.');
        return;
      }
      await collection.add({
        'name': categoryName.text.trim(),
        'gender': gender,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      categoryName.clear();
      message('Categorie ajoutee a l ecran principal.');
    } on FirebaseException catch (e) {
      message('Firebase: ${e.message ?? e.code}');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteCategory(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette categorie ?'),
        content: Text(
          '« ${data['name'] ?? ''} » disparaitra de l ecran principal. Les photos de tenues ne seront pas supprimees.',
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
    if (confirmed != true) return;
    setState(() => deletingId = doc.id);
    try {
      await doc.reference.delete();
      message('Categorie supprimee.');
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
    final mobile = MediaQuery.sizeOf(context).width < 720;
    return Scaffold(
      backgroundColor: const Color(0xfff7f5fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(mobile ? 16 : 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Gestion des categories',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff170635),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Une categorie est un type de look affiche sur l ecran principal, par exemple Caftan ou Amazigh.',
                    style: TextStyle(fontSize: 16, color: Color(0xff655e70)),
                  ),
                  const SizedBox(height: 24),
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
                            const Text(
                              'Ajouter une categorie',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: categoryName,
                              enabled: !saving,
                              decoration: const InputDecoration(
                                labelText: 'Nom de la categorie',
                                hintText: 'Caftan',
                                prefixIcon: Icon(Icons.category_outlined),
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
                                  icon: Icon(Icons.woman_rounded),
                                ),
                                ButtonSegment(
                                  value: 'homme',
                                  label: Text('Homme'),
                                  icon: Icon(Icons.man_rounded),
                                ),
                              ],
                              selected: {gender},
                              onSelectionChanged: saving
                                  ? null
                                  : (v) => setState(() => gender = v.first),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: saving ? null : addCategory,
                              icon: saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded),
                              label: Text(
                                saving ? 'Ajout...' : 'Ajouter la categorie',
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
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
                    'Categories actuelles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (bootstrapping)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('look_categories')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return Text(
                            'Firestore: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty)
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(child: Text('Aucune categorie.')),
                            ),
                          );
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: docs.map(categoryCard).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final isFemale = data['gender'] == 'femme';
    final deleting = deletingId == doc.id;
    return Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe7e1ee)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xffeeeaff),
            child: Icon(
              isFemale ? Icons.woman_rounded : Icons.man_rounded,
              color: const Color(0xff5146f5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  isFemale ? 'Femme' : 'Homme',
                  style: const TextStyle(color: Color(0xff655e70)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: deleting ? null : () => deleteCategory(doc),
            icon: deleting
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
