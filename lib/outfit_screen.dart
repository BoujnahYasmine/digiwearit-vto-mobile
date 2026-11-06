import 'dart:async';
import 'package:flutter/material.dart';
import 'experience_failure.dart';
import 'outfit_repository.dart';
import 'try_on_session.dart';

import 'catalogue_photo.dart';
import 'mobile_layout.dart';
import 'outfit.dart';
import 'style_selection.dart';
import 'outfit_selection.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({
    super.key,
    this.selection = const StyleSelection(),
    this.outfits,
    this.categoryMode = true,
  });
  final StyleSelection selection;
  final Stream<List<Outfit>>? outfits;
  final bool categoryMode;
  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  late bool english = widget.selection.english;
  List<Outfit> outfits = [];
  String? selected;
  bool loading = true, error = false;
  StreamSubscription<List<Outfit>>? subscription;
  List<Outfit> get collection => OutfitRepository.filter(
    outfits,
    gender: widget.selection.gender,
    style: widget.selection.style,
  );
  List<Outfit> get categories => {
    for (final outfit in collection) outfitType(outfit): outfit,
  }.values.toList();
  @override
  void initState() {
    super.initState();
    listen();
  }

  Future<void> listen() async {
    await subscription?.cancel();
    if (mounted) {
      setState(() {
        loading = true;
        error = false;
      });
    }
    try {
      Stream<List<Outfit>> stream;
      if (widget.outfits != null) {
        stream = widget.outfits!;
      } else {
        stream = OutfitRepository().watchOutfits();
      }
      if (!mounted) return;
      subscription = stream.listen(
        (items) {
          if (mounted) {
            setState(() {
              outfits = items;
              loading = false;
              error = false;
              if (!categories.any((o) => outfitType(o) == selected)) {
                selected = categories.isEmpty
                    ? null
                    : outfitType(categories.first);
              }
            });
          }
        },
        onError: (Object e) {
          if (mounted) {
            setState(() {
              loading = false;
              error = true;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> next() async {
    final models = collection.where((o) => outfitType(o) == selected).toList();
    if (models.isEmpty) return;
    TryOnSession.current.selectCategory(selected!);
    final selection = OutfitSelection(
      outfit: models.first,
      outfits: models,
      gender: widget.selection.gender,
      english: english,
      style: widget.selection.style,
    );
    TryOnSession.current.selectOutfit(selection);
    await Navigator.pushNamed(context, '/try-on', arguments: selection);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/welcome_boutique.png', fit: BoxFit.cover),
        const ColoredBox(color: Color(0xe6e6d8eb)),
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
                    padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 16),
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
                              ? 'Choose a category'
                              : 'Choix de la catégorie',
                          child: SizedBox(
                            width: wide ? 270 : 150,
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
                        ),
                        SizedBox(height: gap),
                        Text(
                          english
                              ? 'Choose a category'
                              : 'Choisissez une catégorie',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['serif'],
                            fontWeight: FontWeight.bold,
                            fontSize: wide ? 42 : (compact ? 25 : 29),
                            height: 1.1,
                            color: digiInk,
                          ),
                        ),
                        SizedBox(height: gap * .6),
                        Text(
                          english
                              ? 'Explore traditional and modern outfits inspired by heritage.'
                              : 'Explorez nos tenues traditionnelles et modernes inspirées du patrimoine.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            color: const Color(0xff887399),
                            fontSize: wide ? 19 : 13,
                            height: 1.25,
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(child: _catalogue(wide)),
                        SizedBox(height: gap),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            DigiButton(
                              key: const ValueKey('outfit-continue'),
                              label: english ? 'Continue' : 'Continuer',
                              onPressed: loading || error || selected == null
                                  ? null
                                  : next,
                            ),
                            const IgnorePointer(
                              child: Padding(
                                padding: EdgeInsets.only(right: 18),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                            ),
                          ],
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
      color: Colors.white38,
      borderRadius: BorderRadius.circular(30),
    ),
    child: child,
  );

  Widget _catalogue(bool wide) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              english
                  ? 'The collection is taking a moment to arrive 👗 Check your connection, then try again.'
                  : Friendly.catalogue,
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: listen,
              child: Text(english ? 'Retry' : 'Réessayer'),
            ),
          ],
        ),
      );
    }
    if (categories.isEmpty) {
      return Center(
        child: Text(
          english
              ? 'No outfits available in this collection.'
              : 'Aucune tenue disponible dans cette collection.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final rows = ((categories.length + 1) ~/ 2).clamp(1, 3);
        final extent = ((box.maxHeight - (rows - 1) * 12) / rows).clamp(
          130.0,
          box.maxHeight.clamp(130.0, double.infinity),
        );
        return GridView.builder(
          padding: const EdgeInsets.all(3),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: extent - 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _card(categories[index], wide),
        );
      },
    );
  }

  (String, IconData) _details(String type) {
    final name = type.toLowerCase();
    if (name.contains('baamran') || name.contains('baamrane'))
      return (
        english ? 'Authentic heritage' : 'Héritage authentique',
        Icons.filter_vintage_outlined,
      );
    if (name.contains('amazigh'))
      return (
        english ? 'Colours and symbols' : 'Couleurs et symboles',
        Icons.change_history,
      );
    if (name.contains('sahra'))
      return (
        english ? 'Desert beauty' : 'Beauté du désert',
        Icons.park_outlined,
      );
    if (name.contains('caftan'))
      return (
        english ? 'Timeless elegance' : 'Élégance intemporelle',
        Icons.checkroom,
      );
    if (name.contains('rif'))
      return (
        english ? 'Living traditions' : 'Traditions vivantes',
        Icons.star_outline,
      );
    return (
      english ? 'Discover the collection' : 'Découvrez la collection',
      Icons.diamond_outlined,
    );
  }

  Widget _card(Outfit outfit, bool wide) {
    final type = outfitType(outfit);
    final active = selected == type;
    final details = _details(type);
    return Semantics(
      button: true,
      selected: active,
      label: type,
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          gradient: active ? digiGradient : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xffac6afa).withValues(alpha: .3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: const Color(0xffeee7ec),
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('category-$type'),
            onTap: () => setState(() => selected = type),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CataloguePhoto(outfit: outfit),
                      if (active)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: wide ? 46 : 30,
                            height: wide ? 46 : 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: digiGradient,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: wide ? 32 : 23,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 14 : 8,
                    vertical: wide ? 14 : 8,
                  ),
                  child: Row(
                    children: [
                      if (wide) ...[
                        Icon(details.$2, color: digiInk, size: 29),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: digiInk,
                                fontWeight: FontWeight.w600,
                                fontSize: wide ? 20 : 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              details.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xff89759d),
                                fontSize: wide ? 14 : 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: wide ? 42 : 27,
                        height: wide ? 42 : 27,
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xffe0d5e4)),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: digiInk,
                          size: wide ? 27 : 20,
                        ),
                      ),
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
