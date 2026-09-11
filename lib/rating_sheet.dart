import 'package:flutter/material.dart';
import 'experience_session.dart';
import 'experience_failure.dart';
import 'mobile_layout.dart';
import 'full_photo_scene.dart';

enum EndChoice { another, finish }

typedef FeedbackSender = Future<void> Function(Map<String, dynamic> feedback);
Future<EndChoice?> showRatingSheet(
  BuildContext context, {
  String? tryOnId,
  String? outfitId,
}) => showModalBottomSheet<EndChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x59080619),
  builder: (_) => RatingSheet(tryOnId: tryOnId, outfitId: outfitId),
);

class RatingSheet extends StatefulWidget {
  const RatingSheet({super.key, this.tryOnId, this.outfitId, this.sender});
  final String? tryOnId, outfitId;
  final FeedbackSender? sender;
  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int rating = 0;
  bool busy = false, done = false, skipped = false;
  String? error;
  final comment = TextEditingController();
  static const labels = [
    'Très mauvais',
    'Pas terrible',
    'Correct',
    'Très bien',
    'Excellent ✨',
  ];
  bool get demo => widget.sender == null && !ExperienceApi.configured;
  @override
  void dispose() {
    comment.clear();
    comment.dispose();
    super.dispose();
  }

  void skip() {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      done = true;
      skipped = true;
      error = null;
    });
  }

  Future<void> submit() async {
    if (rating == 0 || busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final payload = <String, dynamic>{
        'rating': rating,
        'comment': comment.text.trim(),
        if (widget.tryOnId != null) 'tryOnId': widget.tryOnId,
        if (widget.outfitId != null) 'outfitId': widget.outfitId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      if (widget.sender != null) {
        await widget.sender!(payload);
      } else if (ExperienceApi.configured) {
        await ExperienceApi.post('/feedback', payload);
      }
      if (mounted) setState(() => done = true);
    } catch (e) {
      if (mounted) setState(() => error = explainFailure(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final available = (media.size.height - keyboard - media.padding.top).clamp(
      0.0,
      media.size.height,
    );
    return PopScope(
      canPop: done && !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) skip();
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          keyboard + 12 + media.padding.bottom,
        ),
        child: SizedBox(
          height:
              (keyboard > 0 ? available * .88 : available * .68) -
              media.padding.bottom,
          child: OverlayGlass(
            tint: const Color(0xdc1c1632),
            blur: 24,
            borderColor: Colors.white24,
            child: Column(
              children: [
                SizedBox(
                  height: 32,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          key: const ValueKey('rating-close'),
                          tooltip: 'Fermer',
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                          ),
                          onPressed: busy ? null : skip,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: box.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (keyboard == 0) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xffb6c7ff),
                                        Color(0xffe4a5ef),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x668245f6),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    done ? Icons.check : Icons.favorite_border,
                                    color: digiInk,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Text(
                                done
                                    ? skipped
                                          ? 'Merci 💜'
                                          : 'Merci pour votre avis 💜'
                                    : 'Votre avis nous intéresse ✨',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (done) ...[
                                Text(
                                  skipped
                                      ? 'À bientôt pour un nouvel essayage.'
                                      : 'Votre retour nous aide à améliorer l’expérience Digiwearit.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                if (demo && !skipped)
                                  const Text(
                                    'Mode démonstration : aucun avis transmis.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                              ] else ...[
                                const Text(
                                  'Comment s’est passé votre essayage ?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                if (keyboard == 0)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      'Votre avis nous aide à améliorer Digiwearit.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    for (var i = 1; i <= 5; i++)
                                      Expanded(
                                        child: Semantics(
                                          selected: i <= rating,
                                          child: IconButton(
                                            key: ValueKey('rating-$i'),
                                            tooltip: labels[i - 1],
                                            onPressed: busy
                                                ? null
                                                : () => setState(
                                                    () => rating = i,
                                                  ),
                                            icon: AnimatedScale(
                                              scale: i <= rating ? 1.08 : 1,
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              curve: Curves.easeOutBack,
                                              child: Icon(
                                                i <= rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: i <= rating
                                                    ? const Color(0xffffd448)
                                                    : Colors.white70,
                                                size: 36,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  rating == 0
                                      ? 'Choisissez une note'
                                      : labels[rating - 1],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: comment,
                                  enabled: !busy,
                                  maxLength: 150,
                                  minLines: 2,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Un commentaire ? (facultatif)',
                                    hintText: 'Partagez votre avis…',
                                    labelStyle: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    hintStyle: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                    counterStyle: const TextStyle(
                                      color: Colors.white60,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white10,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: Color(0xffb986f9),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                if (demo)
                                  const Text(
                                    'Mode démonstration : aucun avis ne sera transmis.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (error != null)
                                  Text(
                                    error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xffffbdd4),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (done) ...[
                  DigiButton(
                    label: 'Essayer une autre tenue',
                    onPressed: () => Navigator.pop(context, EndChoice.another),
                  ),
                  const SizedBox(height: 8),
                  DigiButton(
                    secondary: true,
                    label: 'Terminer',
                    onPressed: () => Navigator.pop(context, EndChoice.finish),
                  ),
                ] else ...[
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      DigiButton(
                        key: const ValueKey('rating-submit'),
                        label: busy ? 'Envoi…' : 'Envoyer mon avis',
                        onPressed: busy || rating == 0 ? null : submit,
                      ),
                      if (busy)
                        const Positioned(
                          left: 12,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextButton(
                    onPressed: busy ? null : skip,
                    child: const Text(
                      'Passer',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
