import 'package:flutter/material.dart';
import '../mobile_layout.dart';
import 'mirror_content.dart';
import 'mirror_tryon_controller.dart';

class MirrorOutfitsScreen extends StatefulWidget {
  const MirrorOutfitsScreen({super.key, this.controller});
  final MirrorTryOnController? controller;
  @override
  State<MirrorOutfitsScreen> createState() => _MirrorOutfitsScreenState();
}

class _MirrorOutfitsScreenState extends State<MirrorOutfitsScreen> {
  late final c = widget.controller ?? MirrorTryOnController.current;
  String? selected;
  bool english = false;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/mirror/catalogues');
    }
  }

  void _next() {
    if (!(c.selectedCatalogue?.outfits.any((o) => o.id == selected) ?? false)) {
      return;
    }
    c.selectOutfit(selected!);
    Navigator.of(context).pushNamed(
      c.capturedPhoto == null ? '/mirror/camera' : '/mirror/generation',
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = c.selectedCatalogue;
    final outfits = catalogue?.outfits ?? <MirrorOutfit>[];
    final ready = outfits.any((o) => o.id == selected);
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
                    final gap = compact ? 8.0 : 14.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          SizedBox(height: gap),
                          SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                _glass(
                                  IconButton(
                                    onPressed: _back,
                                    tooltip: english ? 'Back' : 'Retour',
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
                                      height: 40,
                                    ),
                                  ),
                                ),
                                _glass(
                                  PopupMenuButton<bool>(
                                    onSelected: (v) =>
                                        setState(() => english = v),
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
                                          const Icon(Icons.language, size: 16),
                                          const SizedBox(width: 4),
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
                                      gradient: i < 3 ? digiGradient : null,
                                      color: i == 3
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
                                ? 'Choose an outfit'
                                : 'Choisissez une tenue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: digiInk,
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 23 : 27,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            catalogue?.name ??
                                (english
                                    ? 'Choose a collection first'
                                    : 'Choisissez un catalogue'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff8b7a9f),
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: gap),
                          Expanded(
                            child: outfits.isEmpty
                                ? Center(
                                    child: Text(
                                      english
                                          ? 'No published outfits in this collection.'
                                          : 'Aucune tenue publi\u00e9e dans ce catalogue.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: digiInk),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (_, grid) => GridView.builder(
                                      padding: EdgeInsets.zero,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent:
                                                ((grid.maxHeight - 24) / 3)
                                                    .clamp(150.0, 280.0),
                                          ),
                                      itemCount: outfits.length,
                                      itemBuilder: (_, i) => _card(outfits[i]),
                                    ),
                                  ),
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            width: double.infinity,
                            child: DigiButton(
                              key: const ValueKey('mirror-outfit-continue'),
                              label: english
                                  ? 'Try this outfit'
                                  : 'Essayer cette tenue',
                              onPressed: ready ? _next : null,
                            ),
                          ),
                          SizedBox(height: gap),
                          const Text(
                            'D R E S S  Y O U R S E L F  D I F F E R E N T L Y',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xff9c7aac),
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

  Widget _glass(Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white60),
    ),
    child: child,
  );
  Widget _card(MirrorOutfit outfit) {
    final chosen = selected == outfit.id;
    final fallback = Container(
      color: const Color(0xffd2c3db),
      child: const Center(
        child: Icon(Icons.checkroom, color: digiInk, size: 36),
      ),
    );
    return Semantics(
      selected: chosen,
      button: true,
      label: outfit.name,
      child: Container(
        padding: EdgeInsets.all(chosen ? 2 : 0),
        decoration: BoxDecoration(
          gradient: chosen ? digiGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: const Color(0xffeee6f0),
            child: InkWell(
              key: ValueKey('mirror-outfit-${outfit.id}'),
              onTap: () => setState(() => selected = outfit.id),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: outfit.imageUrl.isEmpty
                            ? fallback
                            : Image.network(
                                outfit.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => fallback,
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outfit.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: digiInk,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    english
                                        ? 'Discover this outfit'
                                        : 'D\u00e9couvrez cette tenue',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xff8b7a9f),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.white70,
                              child: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: digiInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (chosen)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: digiGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
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
