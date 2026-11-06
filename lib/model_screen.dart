import 'try_on_session.dart';
import 'package:flutter/material.dart';
import 'store_payment.dart';
import 'catalogue_photo.dart';
import 'outfit.dart';
import 'outfit_selection.dart';
import 'mobile_layout.dart';

class ModelScreen extends StatefulWidget {
  const ModelScreen({super.key, required this.selection});
  final OutfitSelection selection;
  @override
  State<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends State<ModelScreen> {
  late bool english = widget.selection.english;
  late Outfit selected = widget.selection.outfit;
  String? filter;
  String t(String fr, String en) => english ? en : fr;
  List<Outfit> get collection => {
    for (final o in widget.selection.outfits)
      if (o.active &&
          o.gender == widget.selection.gender &&
          normalizedStyle(outfitStyle(o)) ==
              normalizedStyle(widget.selection.style))
        o.id: o,
    widget.selection.outfit.id: widget.selection.outfit,
  }.values.toList();
  List<Outfit> get visible => collection
      .where((o) => filter == null || outfitType(o) == filter)
      .toList();
  int get index => visible.indexWhere((o) => o.id == selected.id);
  void step(int delta) {
    if (visible.length > 1) {
      setState(() => selected = visible[(index + delta) % visible.length]);
    }
  }

  OutfitSelection get result => OutfitSelection(
    outfit: selected,
    gender: widget.selection.gender,
    style: widget.selection.style,
    english: english,
    outfits: collection,
    preferredColor: widget.selection.preferredColor,
    preferredColorName: widget.selection.preferredColorName,
  );
  void details() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xffeee5f2),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected.name,
              style: const TextStyle(
                fontSize: 23,
                color: digiInk,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (selected.description.isNotEmpty) Text(selected.description),
            if (selected.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final tag in selected.tags) Chip(label: Text(tag)),
                ],
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('Fermer', 'Close')),
            ),
          ],
        ),
      ),
    ),
  );
  void fullscreen() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xff211a30),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CataloguePhoto(
                  outfit: selected,
                  fit: BoxFit.contain,
                  fullResolution: true,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filledTonal(
                  tooltip: t('Fermer', 'Close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xe6e5d7eb)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(16) > 22;
                  final compact = bounds.maxHeight < 650 || largeText;
                  final wide = bounds.maxWidth > 600;
                  final gap = compact ? 6.0 : 12.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 14),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 4 : 12),
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              _glass(
                                IconButton(
                                  tooltip: t('Retour', 'Back'),
                                  onPressed: () =>
                                      Navigator.pop(context, result),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: digiInk,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Image.asset(
                                    'lib/logo digiwearit.png',
                                    height: 44,
                                  ),
                                ),
                              ),
                              _glass(
                                PopupMenuButton<bool>(
                                  tooltip: t('Langue', 'Language'),
                                  initialValue: english,
                                  onSelected: (value) =>
                                      setState(() => english = value),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: false,
                                      child: Text('Français'),
                                    ),
                                    PopupMenuItem(
                                      value: true,
                                      child: Text('English'),
                                    ),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.language,
                                          size: 18,
                                          color: digiInk,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          english ? 'EN' : 'FR',
                                          style: const TextStyle(
                                            color: digiInk,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: digiInk,
                                        ),
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
                          width: 180,
                          child: Row(
                            children: List.generate(
                              5,
                              (i) => Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: i < 2 ? digiGradient : null,
                                    color: i < 2
                                        ? null
                                        : const Color(0x337e6894),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        Text(
                          t('Choisissez votre modèle', 'Choose your outfit'),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontWeight: FontWeight.bold,
                            color: digiInk,
                            fontSize: largeText ? 20 : (wide ? 38 : 27),
                            height: 1.1,
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 6),
                          Text(
                            t(
                              'Découvrez nos tenues et sélectionnez celle que vous souhaitez essayer.',
                              'Discover our outfits and choose the one you would like to try.',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: TextStyle(
                              color: const Color(0xff8e7aa2),
                              fontSize: wide ? 18 : 13,
                            ),
                          ),
                        ],
                        SizedBox(height: gap),
                        SizedBox(
                          height: largeText ? 54 : 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final type in <String?>[
                                null,
                                ...collection.map(outfitType).toSet(),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: filter == type
                                          ? digiGradient
                                          : null,
                                      color: filter == type
                                          ? null
                                          : Colors.white38,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: () => setState(() {
                                        filter = type;
                                        if (!visible.any(
                                          (o) => o.id == selected.id,
                                        ))
                                          selected = visible.first;
                                      }),
                                      child: Text(
                                        type ?? t('Tous', 'All'),
                                        style: TextStyle(
                                          color: filter == type
                                              ? Colors.white
                                              : digiInk,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          child: GestureDetector(
                            onHorizontalDragEnd: (d) {
                              if ((d.primaryVelocity ?? 0).abs() > 80)
                                step(d.primaryVelocity! < 0 ? 1 : -1);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CataloguePhoto(outfit: selected),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: IgnorePointer(
                                      child: _glass(
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            '${index + 1} / ${visible.length}',
                                            maxLines: 1,
                                            style: const TextStyle(
                                              color: digiInk,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (visible.length > 1) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton.filledTonal(
                                        key: const ValueKey('model-previous'),
                                        tooltip: t('Précédent', 'Previous'),
                                        onPressed: () => step(-1),
                                        icon: const Icon(Icons.chevron_left),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton.filledTonal(
                                        key: const ValueKey('model-next'),
                                        tooltip: t('Suivant', 'Next'),
                                        onPressed: () => step(1),
                                        icon: const Icon(Icons.chevron_right),
                                      ),
                                    ),
                                  ],
                                  Positioned(
                                    bottom: 6,
                                    right: compact
                                        ? (bounds.maxWidth - 28) / 2 - 24
                                        : 8,
                                    child: compact
                                        ? IconButton.filledTonal(
                                            tooltip: t(
                                              'Voir en plein écran',
                                              'View fullscreen',
                                            ),
                                            onPressed: fullscreen,
                                            icon: const Icon(Icons.fullscreen),
                                          )
                                        : _glass(
                                            TextButton.icon(
                                              onPressed: fullscreen,
                                              icon: const Icon(
                                                Icons.fullscreen,
                                                size: 20,
                                              ),
                                              label: Text(
                                                t(
                                                  'Voir en plein écran',
                                                  'View fullscreen',
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!compact && visible.length > 1) ...[
                          SizedBox(height: gap),
                          SizedBox(
                            height: wide ? 78 : 54,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: visible.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) => Semantics(
                                button: true,
                                selected: visible[i].id == selected.id,
                                label: visible[i].name,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => selected = visible[i]),
                                  child: Container(
                                    width: wide ? 78 : 54,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      gradient: visible[i].id == selected.id
                                          ? digiGradient
                                          : null,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: CataloguePhoto(outfit: visible[i]),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: gap),
                        DigiGlass(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selected.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: digiInk,
                                        fontSize: compact ? 16 : 20,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: details,
                                      child: Text(
                                        t('Voir les détails', 'Details'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!compact && selected.description.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    selected.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: digiInk,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              Text(
                                StorePayment.supported
                                    ? t(
                                        'Essayage IA · 29 DH',
                                        'AI try-on · 29 DH',
                                      )
                                    : t(
                                        'Essayage IA · 29 DH · Démo, aucun débit',
                                        'AI try-on · 29 DH · Demo, no charge',
                                      ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: digiInk,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        DigiButton(
                          key: const ValueKey('model-continue'),
                          label: t('Choisir cette tenue', 'Choose this outfit'),
                          onPressed: () {
                            TryOnSession.current.selectOutfit(result);
                            Navigator.pushNamed(
                              context,
                              '/try-on',
                              arguments: result,
                            );
                          },
                        ),
                        SizedBox(height: compact ? 8 : 20),
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

  Widget _glass(Widget child) => Container(
    decoration: BoxDecoration(
      color: const Color(0xffeee5f3).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(28),
    ),
    child: child,
  );
}
