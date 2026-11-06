import 'try_on_session.dart';
import 'dart:typed_data';
import 'result_photo.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'style_selection.dart';
import 'outfit_selection.dart';
import 'mobile_layout.dart';
import 'full_photo_scene.dart';
import 'classic_delivery_service.dart';
import 'delivery_screen.dart';
import 'rating_sheet.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.images,
    required this.outfitName,
    required this.resultId,
    this.selection = const StyleSelection(),
    this.emailSender,
  });
  final List<Uint8List> images;
  final String outfitName, resultId;
  final StyleSelection selection;
  final Future<void> Function(String, Uint8List, String)? emailSender;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int index = 0;
  late bool english = widget.selection.english;

  /// Panel fraction of the screen; dragging it down reveals the full photo.
  final sheet = DraggableScrollableController();
  double? extent;
  static const closedSheet = .12;

  @override
  void dispose() {
    sheet.dispose();
    super.dispose();
  }

  void toggleSheet(double open) {
    if (!sheet.isAttached) return;
    sheet.animateTo(
      sheet.size > (open + closedSheet) / 2 ? closedSheet : open,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  bool presenting = false;
  void another() {
    TryOnSession.current.reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/outfits',
      (route) => route.isFirst,
      arguments: widget.selection,
    );
  }

  void finish() {
    TryOnSession.current.reset();
    imageCache.clear();
    imageCache.clearLiveImages();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> rate() async {
    if (presenting) return;
    presenting = true;
    final choice = await showRatingSheet(
      context,
      tryOnId: widget.resultId,
      outfitId: widget.selection is OutfitSelection
          ? (widget.selection as OutfitSelection).outfit.id
          : null,
    );
    presenting = false;
    if (!mounted) return;
    if (choice == EndChoice.another) another();
    if (choice == EndChoice.finish) finish();
  }

  Future<void> email() async {
    if (presenting) return;
    presenting = true;
    final sent = await showDeliverySheet(
      context,
      bytes: widget.images[index],
      resultId: '${widget.resultId}-$index',
      sender: widget.emailSender ?? ClassicDeliveryService.send,
    );
    presenting = false;
    if (mounted && sent == true) await rate();
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).height < 700 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    final screen = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final panelHeight =
        (compact ? 290 : 364) + (widget.images.length > 1 ? 48 : 0);
    final open = ((panelHeight + 12 + bottomInset) / screen).clamp(.3, .92);
    final current = (extent ?? open).clamp(closedSheet, open);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xff11101b),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: screen * current,
            child: GestureDetector(
              onTap: () => toggleSheet(open),
              child: ResultPhoto(bytes: widget.images[index]),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x6b050514),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x8c050514),
                  ],
                  stops: [0, .22, .65, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        _control(
                          IconButton(
                            tooltip: english ? 'Back' : 'Retour',
                            onPressed: another,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Image.asset(
                              'lib/logo digiwearit.png',
                              height: 40,
                            ),
                          ),
                        ),
                        _control(
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
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    english ? 'EN' : 'FR',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.expand_more,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checkroom,
                            color: Color(0xff6e52dc),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.outfitName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: digiInk,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() => extent = notification.extent);
              return false;
            },
            child: DraggableScrollableSheet(
              key: const ValueKey('result-sheet'),
              controller: sheet,
              initialChildSize: open,
              minChildSize: closedSheet,
              maxChildSize: open,
              snap: true,
              builder: (context, scroll) => SingleChildScrollView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
                child: Column(
                  children: [
                    if (widget.images.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Précédent',
                            onPressed: () => setState(
                              () => index = (index - 1) % widget.images.length,
                            ),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            '${index + 1}/${widget.images.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Suivant',
                            onPressed: () => setState(
                              () => index = (index + 1) % widget.images.length,
                            ),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    _resultPanel(compact),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x4d1e1937),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    ),
  );

  Widget _resultPanel(bool compact) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 40,
          offset: Offset(0, -10),
        ),
      ],
    ),
    child: OverlayGlass(
      tint: const Color(0xd6130f2a),
      blur: 24,
      borderColor: Colors.white24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: compact ? 100 : 160,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xffb5abcc),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),
                    SizedBox(
                      height: compact ? 34 : 54,
                      child: Container(
                        padding: EdgeInsets.all(compact ? 5 : 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: digiGradient,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xff9c59ef,
                              ).withValues(alpha: .28),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffd6c2fb),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: digiInk,
                            size: compact ? 20 : 30,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 12),
                    Text(
                      english
                          ? 'Your try-on is ready ✨'
                          : 'Votre essayage est prêt ✨',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 18 : 23,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      english
                          ? 'What would you like to do now?'
                          : 'Que souhaitez-vous faire maintenant ?',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xffb9aed0),
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 16),
          DigiButton(
            key: const ValueKey('result-email'),
            label: english ? '✉ Receive my photo' : '✉ Recevoir ma photo',
            onPressed: email,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white38),
            ),
            child: TextButton(
              onPressed: another,
              style: TextButton.styleFrom(
                minimumSize: Size(0, compact ? 44 : 52),
              ),
              child: Text(
                english ? '↻ Try another outfit' : '↻ Essayer une autre tenue',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          TextButton(
            onPressed: finish,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(vertical: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              english ? 'Return home' : 'Retour à l’accueil',
              maxLines: 1,
              style: const TextStyle(color: Color(0xffc7d5f7), fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}
