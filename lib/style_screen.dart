import 'dart:async';
import 'outfit.dart';
import 'outfit_repository.dart';
import 'outfit_selection.dart';
import 'try_on_session.dart';
import 'package:flutter/material.dart';
import 'mobile_layout.dart';
import 'style_selection.dart';

class StyleScreen extends StatefulWidget {
  const StyleScreen({
    super.key,
    this.selection = const StyleSelection(),
    this.catalogues,
  });
  final Stream<List<LookCategory>>? catalogues;
  final StyleSelection selection;
  @override
  State<StyleScreen> createState() => _StyleScreenState();
}

class _StyleScreenState extends State<StyleScreen> {
  late bool english = widget.selection.english;
  late String selected = widget.selection.style;
  // Keep catalogue identifiers stable; the displayed French label is Indien.
  static const defaults = [
    (
      'Marocain',
      'Moroccan',
      'assets/universe_femme.png',
      'Élégance et tradition',
      'Elegance and tradition',
      Icons.architecture_outlined,
    ),
    (
      'Hindien',
      'Indian',
      'assets/style_indian.png',
      'Couleurs et raffinement',
      'Colour and refinement',
      Icons.spa_outlined,
    ),
    (
      'Espagnol',
      'Spanish',
      'assets/style_spanish.png',
      'Passion et caractère',
      'Passion and character',
      Icons.filter_vintage_outlined,
    ),
    (
      'Moderne',
      'Modern',
      'assets/style_modern.png',
      'Un style d’aujourd’hui',
      'Contemporary style',
      Icons.work_outline,
    ),
  ];

  late List<(String, String, String, String, String, IconData)> styles = [
    ...defaults,
  ];
  StreamSubscription<List<LookCategory>>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = (widget.catalogues ?? OutfitRepository().watchStyles())
        .listen(
          (items) {
            final merged = [...defaults];
            for (final item in items.where(
              (item) => item.active && item.name.isNotEmpty,
            )) {
              final index = merged.indexWhere(
                (entry) =>
                    normalizedStyle(entry.$1) == normalizedStyle(item.name),
              );
              if (index >= 0) {
                final old = merged[index];
                merged[index] = (
                  old.$1,
                  old.$2,
                  item.imageUrl.isEmpty ? old.$3 : item.imageUrl,
                  item.description.isEmpty ? old.$4 : item.description,
                  item.description.isEmpty ? old.$5 : item.description,
                  old.$6,
                );
              } else {
                merged.add((
                  item.name,
                  item.name,
                  item.imageUrl.isEmpty
                      ? 'assets/welcome_boutique.png'
                      : item.imageUrl,
                  item.description,
                  item.description,
                  Icons.checkroom_outlined,
                ));
              }
            }
            if (!mounted) return;
            setState(() {
              styles = merged;
              if (!styles.any((item) => item.$1 == selected))
                selected = styles.first.$1;
            });
          },
          onError: (Object error) {
            // Existing categories remain available if the catalogue cannot load.
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void next() {
    TryOnSession.current.selectStyle(selected);
    Navigator.pushNamed(
      context,
      '/outfits',
      arguments: StyleSelection(
        gender: widget.selection.gender,
        english: english,
        style: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  final gap = compact ? 9.0 : 16.0;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 4 : 12),
                        SizedBox(
                          height: wide ? 64 : 48,
                          child: Row(
                            children: [
                              _glass(
                                IconButton(
                                  tooltip: english ? 'Back' : 'Retour',
                                  onPressed: () => Navigator.maybePop(context),
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
                                    height: wide ? 60 : 40,
                                  ),
                                ),
                              ),
                              _glass(
                                PopupMenuButton<bool>(
                                  tooltip: english ? 'Language' : 'Langue',
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
                                          color: digiInk,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          english ? 'EN' : 'FR',
                                          style: const TextStyle(
                                            color: digiInk,
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
                        Semantics(
                          label: english
                              ? 'Style, setup step 2 of 5'
                              : 'Style, étape de préparation 2 sur 5',
                          child: SizedBox(
                            width: wide ? 270 : 150,
                            child: Row(
                              children: List.generate(
                                5,
                                (index) => Expanded(
                                  child: Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: index < 2 ? digiGradient : null,
                                      color: index < 2
                                          ? null
                                          : const Color(0x337e6894),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        Text(
                          english
                              ? 'Which style would you like to explore?'
                              : 'Quel style souhaitez-vous explorer ?',
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontWeight: FontWeight.bold,
                            fontSize: wide ? 42 : (compact ? 25 : 29),
                            height: 1.1,
                            color: digiInk,
                          ),
                        ),
                        SizedBox(height: gap * .65),
                        Text(
                          english
                              ? 'Discover our traditional and modern outfit collections.'
                              : 'Découvrez nos univers de tenues traditionnelles et modernes.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color(0xff9280a8),
                            fontSize: wide ? 19 : 13,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => GridView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: styles.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                    mainAxisExtent:
                                        ((constraints.maxHeight - gap) / 2)
                                            .clamp(140.0, 420.0),
                                  ),
                              itemBuilder: (context, index) =>
                                  _card(index, wide, compact),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: digiGradient,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextButton(
                            key: const ValueKey('style-continue'),
                            onPressed: next,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Text(
                                    english ? 'Continue' : 'Continuer',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 12 : 22,
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '—  DRESS YOURSELF DIFFERENTLY  —',
                              style: TextStyle(
                                color: Color(0xffa68eba),
                                fontSize: 9,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
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
      color: Colors.white30,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white70),
    ),
    child: child,
  );

  Widget _card(int index, bool wide, bool compact) {
    final item = styles[index];
    final active = selected == item.$1;
    final label = english ? item.$2 : (index == 1 ? 'Indien' : item.$1);
    return Semantics(
      selected: active,
      button: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: active ? digiGradient : null,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xffae6aff).withValues(alpha: .4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('style-${item.$1}'),
            onTap: () => setState(() => selected = item.$1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.$3.startsWith('https://') ||
                    item.$3.startsWith('http://'))
                  Image.network(
                    item.$3,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => Image.asset(
                      'assets/welcome_boutique.png',
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset(
                    index == 0 && widget.selection.gender == 'homme'
                        ? 'assets/universe_homme.png'
                        : item.$3,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.35),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.4, 1],
                      colors: [Colors.transparent, Color(0xee221a35)],
                    ),
                  ),
                ),
                if (active)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: wide ? 46 : 30,
                      height: wide ? 46 : 30,
                      decoration: BoxDecoration(
                        gradient: digiGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: wide ? 30 : 21,
                      ),
                    ),
                  ),
                Positioned(
                  left: wide ? 20 : 10,
                  right: wide ? 16 : 8,
                  bottom: wide ? 18 : 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!compact)
                              Icon(
                                item.$6,
                                color: Colors.white,
                                size: wide ? 32 : 22,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontFamilyFallback: const ['serif'],
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: wide ? 30 : 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              english ? item.$5 : item.$4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .85),
                                fontSize: wide ? 15 : 10,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!active) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: wide ? 46 : 28,
                          height: wide ? 46 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: wide ? 30 : 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
