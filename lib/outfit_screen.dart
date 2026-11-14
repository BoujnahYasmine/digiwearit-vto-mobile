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

  /// One tap on an outfit (card or its button) opens the try-on.
  Future<void> tryOn(String type) async {
    setState(() => selected = type);
    await next();
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
                              // Language is chosen on the home page only.
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Semantics(
                          label: english
                              ? 'Choose an outfit'
                              : 'Choix de la tenue',
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
                          english ? 'Choose an outfit' : 'Choisissez une tenue',
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
                        Expanded(child: _catalogue(wide, gap)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: compact ? 12 : 22,
                          ),
                          child: const DigiSlogan(),
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

  Widget _catalogue(bool wide, double gap) {
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
      builder: (context, box) => GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          mainAxisExtent: ((box.maxHeight - gap) / 2).clamp(140.0, 420.0),
        ),
        itemBuilder: (context, index) => _card(categories[index], wide),
      ),
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

  /// The card's own "Essayer" button: chooses this outfit and opens the
  /// try-on (camera) right away.
  Widget _tryOnButton(String type, bool wide) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: digiGradient,
      borderRadius: BorderRadius.circular(18),
    ),
    child: TextButton.icon(
      key: ValueKey('try-on-$type'),
      onPressed: () => tryOn(type),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: Size(0, wide ? 44 : 34),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.auto_awesome, size: wide ? 20 : 15),
      label: Text(
        english ? 'Try on' : 'Essayer',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: wide ? 16 : 13),
      ),
    ),
  );

  Widget _card(Outfit outfit, bool wide) {
    final type = outfitType(outfit);
    final active = selected == type;
    final details = _details(type);
    return Semantics(
      button: true,
      selected: active,
      label: type,
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
            key: ValueKey('category-$type'),
            onTap: () => tryOn(type),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CataloguePhoto(outfit: outfit),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [.35, 1],
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
                  left: wide ? 16 : 9,
                  right: wide ? 16 : 9,
                  bottom: wide ? 14 : 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (wide) ...[
                        Icon(details.$2, color: Colors.white, size: 28),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontFamilyFallback: const ['serif'],
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: wide ? 26 : 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: wide ? 14 : 10,
                        ),
                      ),
                      SizedBox(height: wide ? 10 : 6),
                      _tryOnButton(type, wide),
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
