import 'package:flutter/material.dart';
import '../mobile_layout.dart';
import 'mirror_content.dart';
import 'mirror_tryon_controller.dart';

/// Only content returned for the authenticated mirror is displayed here.
class MirrorCataloguesScreen extends StatefulWidget {
  const MirrorCataloguesScreen({
    super.key,
    this.controller,
    this.gender,
    this.initialEnglish = false,
  });
  final MirrorTryOnController? controller;
  final String? gender;
  final bool initialEnglish;
  @override
  State<MirrorCataloguesScreen> createState() => _MirrorCataloguesScreenState();
}

class _MirrorCataloguesScreenState extends State<MirrorCataloguesScreen> {
  late final controller = widget.controller ?? MirrorTryOnController.current;
  late bool english = widget.initialEnglish;
  String? selectedId;

  List<MirrorCatalogue> get catalogues => controller.visibleCatalogues;

  @override
  void initState() {
    super.initState();
    if (widget.gender != null) controller.setGender(widget.gender!);
    controller.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadContent(forceRefresh: true);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/mirror/universe', (route) => false);
    }
  }

  void _continue() {
    if (controller.loadingContent ||
        controller.contentError != null ||
        !catalogues.any((c) => c.id == selectedId)) {
      return;
    }
    controller.selectCatalogue(selectedId!);
    Navigator.of(context).pushNamed('/mirror/outfits');
  }

  @override
  Widget build(BuildContext context) {
    final items = catalogues;
    final ready =
        !controller.loadingContent &&
        controller.contentError == null &&
        items.any((c) => c.id == selectedId);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
          const ColoredBox(color: Color(0xe6e4d7ed)),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    final compact = bounds.maxHeight < 650;
                    final wide = bounds.maxWidth > 600;
                    final gap = compact ? 8.0 : 14.0;
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16),
                      child: Column(
                        children: [
                          SizedBox(height: gap),
                          SizedBox(
                            height: wide ? 64 : 48,
                            child: Row(
                              children: [
                                _glass(
                                  IconButton(
                                    tooltip: english ? 'Back' : 'Retour',
                                    onPressed: _back,
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: digiInk,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Image.asset(
                                      'lib/logo digiwearit.png',
                                      height: wide ? 58 : 40,
                                    ),
                                  ),
                                ),
                                _glass(
                                  PopupMenuButton<bool>(
                                    tooltip: english ? 'Language' : 'Langue',
                                    onSelected: (value) =>
                                        setState(() => english = value),
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: false,
                                        child: Text('Fran\u00e7ais'),
                                      ),
                                      PopupMenuItem(
                                        value: true,
                                        child: Text('English'),
                                      ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.language,
                                            size: 16,
                                            color: digiInk,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(english ? 'EN' : 'FR'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: List.generate(
                                4,
                                (i) => Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: i <= 1 ? digiGradient : null,
                                      color: i > 1
                                          ? const Color(0x337b648d)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gap),
                          Text(
                            english
                                ? 'Which collection would you like to explore?'
                                : 'Quel style souhaitez-vous explorer ?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: digiInk,
                              fontWeight: FontWeight.bold,
                              fontSize: wide ? 34 : (compact ? 23 : 27),
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: gap * .6),
                          Text(
                            controller.content?.enterpriseName ??
                                (english
                                    ? 'Your partner collections'
                                    : 'Les collections de votre partenaire'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff8b7a9f),
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: gap),
                          Expanded(child: _body(items, wide)),
                          if (controller.isFemaleJourney)
                            CheckboxListTile(
                              key: const ValueKey('mirror-allow-makeup'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                english
                                    ? 'Allow subtle makeup'
                                    : 'Autoriser un maquillage leger',
                              ),
                              value: controller.allowMakeup,
                              onChanged: (value) =>
                                  controller.setAllowMakeup(value ?? false),
                            ),
                          SizedBox(height: gap),
                          SizedBox(
                            width: double.infinity,
                            child: DigiButton(
                              key: const ValueKey('mirror-catalogue-continue'),
                              label: english ? 'Continue' : 'Continuer',
                              onPressed: ready ? _continue : null,
                            ),
                          ),
                          SizedBox(height: gap),
                          const Text(
                            'D R E S S  Y O U R S E L F  D I F F E R E N T L Y',
                            style: TextStyle(
                              color: Color(0xff9c7aac),
                              fontSize: 8,
                            ),
                          ),
                          SizedBox(height: gap),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(List<MirrorCatalogue> items, bool wide) {
    if (controller.loadingContent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.contentError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(controller.contentError!, textAlign: TextAlign.center),
            TextButton(
              onPressed: () => controller.loadContent(forceRefresh: true),
              child: Text(english ? 'Retry' : 'R\u00e9essayer'),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 42,
              color: digiInk,
            ),
            const SizedBox(height: 12),
            Text(
              english
                  ? 'No collection available for this selection.'
                  : 'Aucune collection disponible pour ce choix.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: digiInk),
            ),
            TextButton(
              onPressed: () => controller.loadContent(forceRefresh: true),
              child: Text(english ? 'Refresh' : 'Actualiser'),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, bounds) => GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: ((bounds.maxHeight - 12) / 2).clamp(
            180.0,
            wide ? 360.0 : 310.0,
          ),
        ),
        itemCount: items.length,
        itemBuilder: (_, index) => _card(items[index]),
      ),
    );
  }

  Widget _glass(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .25),
      border: Border.all(color: Colors.white60),
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );

  Widget _card(MirrorCatalogue catalogue) {
    final selected = selectedId == catalogue.id;
    final image =
        catalogue.imageUrl ??
        (catalogue.outfits.isEmpty ? null : catalogue.outfits.first.imageUrl);
    final fallback = Container(
      color: const Color(0xffa18ba9),
      child: const Center(
        child: Icon(
          Icons.collections_bookmark_outlined,
          color: Colors.white70,
          size: 42,
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: catalogue.name,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: selected ? digiGradient : null,
        ),
        padding: EdgeInsets.all(selected ? 2 : 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: const Color(0xffa18ba9),
            child: InkWell(
              key: ValueKey('mirror-catalogue-${catalogue.id}'),
              onTap: () => setState(() => selectedId = catalogue.id),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null && image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  else
                    fallback,
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 10,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          catalogue.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${catalogue.outfits.length} ${english ? 'outfits' : 'tenues'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
