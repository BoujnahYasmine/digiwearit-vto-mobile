import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }

  runApp(const DigiwearitApp());
}

Future<void> shareImage(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required String text,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType)],
        fileNameOverrides: [fileName],
        text: text,
        title: 'Digiwearit',
        downloadFallbackEnabled: true,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Partage impossible : $error')));
  }
}

class DigiwearitApp extends StatelessWidget {
  const DigiwearitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Digiwearit',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5146f5)),
    ),
    home: const TryOnScreen(),
  );
}

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});
  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> with WidgetsBindingObserver {
  CameraController? camera;
  String? cameraError;
  bool female = true;
  int category = 0, look = 0;
  Outfit? selectedOutfit;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? outfitsSubscription;
  List<Outfit> firebaseOutfits = const [];
  bool outfitsLoading = true;
  String? outfitsError;
  Uint8List? capturedPhotoBytes;
  int captureCountdown = 0;
  bool isCapturing = false;
  static const looks = [
    ('Émeraude', Color(0xff087d5c)),
    ('Ciel', Color(0xff8fcbe2)),
    ('Rose', Color(0xffe88991)),
    ('Royal', Color(0xff1646c5)),
    ('Ivoire', Color(0xffe8d9be)),
    ('Nuit', Color(0xff14243d)),
  ];

  List<Outfit> get genderOutfits => firebaseOutfits
      .where(
        (outfit) =>
            outfit.active && outfit.gender == (female ? 'femme' : 'homme'),
      )
      .toList();

  List<String> get categories {
    final result = <String>[];
    final seen = <String>{};
    for (final outfit in genderOutfits) {
      final normalized = outfit.category.toLowerCase();
      if (normalized.isNotEmpty && seen.add(normalized)) {
        result.add(outfit.category);
      }
    }
    return result;
  }

  List<Outfit> get currentCategoryOutfits {
    if (categories.isEmpty) return const [];
    final safeCategory = category.clamp(0, categories.length - 1);
    final wanted = categories[safeCategory].toLowerCase();
    return genderOutfits
        .where((outfit) => outfit.category.toLowerCase() == wanted)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    watchOutfits();
    startCamera();
  }

  void watchOutfits() {
    if (!kIsWeb) return;
    outfitsSubscription = FirebaseFirestore.instance
        .collection('outfits')
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() {
              firebaseOutfits = snapshot.docs
                  .map((doc) => Outfit.fromFirestore(doc.id, doc.data()))
                  .toList();
              outfitsLoading = false;
              outfitsError = null;
              if (category >= categories.length) category = 0;
              look = 0;
              selectedOutfit = null;
            });
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              outfitsLoading = false;
              outfitsError = error.toString();
            });
          },
        );
  }

  Future<void> startCamera() async {
    try {
      final all = await availableCameras();
      if (all.isEmpty) throw CameraException('noCamera', 'No camera found');
      final front = all.where(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      final next = CameraController(
        front.isNotEmpty ? front.first : all.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      try {
        final minimumZoom = await next.getMinZoomLevel();
        await next.setZoomLevel(minimumZoom);
      } on CameraException {
        // Some mobile browsers do not expose zoom controls.
      }
      if (!mounted) return next.dispose();
      await camera?.dispose();
      setState(() {
        camera = next;
        cameraError = null;
      });
    } on CameraException catch (e) {
      if (mounted) setState(() => cameraError = e.description ?? e.code);
    }
  }

  Future<void> takePhotoWithCountdown() async {
    final controller = camera;
    if (isCapturing || controller?.value.isInitialized != true) return;
    setState(() => isCapturing = true);
    try {
      for (var value = 3; value > 0; value--) {
        if (!mounted) return;
        setState(() => captureCountdown = value);
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      final photo = await controller!.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        capturedPhotoBytes = bytes;
        captureCountdown = 0;
        isCapturing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        captureCountdown = 0;
        isCapturing = false;
        cameraError = error.toString();
      });
    }
  }

  Future<void> showRatingDialog() async {
    var selectedRating = 0;
    final rating = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Votre avis compte',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comment évaluez-vous votre expérience Digiwearit ?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    tooltip: '$value étoile${value > 1 ? 's' : ''}',
                    onPressed: () =>
                        setDialogState(() => selectedRating = value),
                    iconSize: MediaQuery.sizeOf(context).width < 600 ? 35 : 42,
                    icon: Icon(
                      value <= selectedRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xffffb300),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 0
                    ? 'Touchez une étoile'
                    : '$selectedRating sur 5',
                style: const TextStyle(
                  color: Color(0xff5361f4),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: selectedRating == 0
                  ? null
                  : () => Navigator.of(dialogContext).pop(selectedRating),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
    if (rating == null || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('experience_ratings').add({
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Merci pour votre avis !')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("La note n'a pas pu être enregistrée : $error")),
      );
    }
  }

  void retakePhoto() {
    setState(() {
      capturedPhotoBytes = null;
      captureCountdown = 0;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      camera?.dispose();
      camera = null;
    } else if (state == AppLifecycleState.resumed) {
      startCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    outfitsSubscription?.cancel();
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: const Color(0xffd8d0cb),
    body: Stack(
      fit: StackFit.expand,
      children: [
        CameraBackground(
          controller: camera,
          error: cameraError,
          retry: startCamera,
        ),
        if (capturedPhotoBytes != null)
          Positioned.fill(
            child: Image.memory(
              capturedPhotoBytes!,
              fit: kIsWeb && MediaQuery.sizeOf(context).width < 600
                  ? BoxFit.contain
                  : BoxFit.cover,
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x44000000),
                Colors.transparent,
                Color(0x55071245),
              ],
              stops: [0, .38, 1],
            ),
          ),
        ),
        if (captureCountdown > 0)
          Center(
            child: Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xaa170635),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Text(
                '$captureCountdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        SafeArea(
          child: LayoutBuilder(
            builder: (_, box) => Padding(
              padding: EdgeInsets.fromLTRB(
                box.maxWidth < 600 ? 10 : 18,
                box.maxWidth < 600 ? 8 : 14,
                box.maxWidth < 600 ? 10 : 18,
                box.maxHeight < 720 ? 6 : (box.maxWidth < 600 ? 10 : 18),
              ),
              child: Column(
                children: [
                  Glass(
                    radius: box.maxWidth < 600 ? 17 : 22,
                    padding: EdgeInsets.symmetric(
                      horizontal: box.maxWidth < 600 ? 9 : 18,
                      vertical: box.maxWidth < 600 ? 6 : 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'lib/logo digiwearit.png',
                              height: box.maxWidth < 600 ? 25 : 38,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text(
                                    'Digiwearit',
                                    style: TextStyle(
                                      color: Color(0xff07145a),
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            children: [
                              GenderChip(
                                'Femme',
                                female,
                                () => changeGender(true),
                              ),
                              GenderChip(
                                'Homme',
                                !female,
                                () => changeGender(false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  CategoryBar(
                    items: categories,
                    selected: category,
                    onChanged: (v) => setState(() {
                      category = v;
                      look = 0;
                      selectedOutfit = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  buildOutfitPicker(),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: isCapturing
                        ? null
                        : capturedPhotoBytes == null
                        ? takePhotoWithCountdown
                        : openGeneration,
                    child: Container(
                      height: box.maxWidth < 600 ? 50 : 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          MediaQuery.sizeOf(context).width < 600 ? 16 : 20,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xff1764fa),
                            Color(0xff7953f4),
                            Color(0xffff5c91),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x554d45f5),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            capturedPhotoBytes == null
                                ? Icons.camera_alt_rounded
                                : Icons.auto_fix_high_rounded,
                            color: Colors.white,
                            size: box.maxWidth < 600 ? 23 : 29,
                          ),
                          SizedBox(width: box.maxWidth < 600 ? 9 : 16),
                          Text(
                            isCapturing
                                ? 'Photo dans $captureCountdown...'
                                : capturedPhotoBytes == null
                                ? 'Prendre une photo'
                                : 'Essayer cette tenue',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: box.maxWidth < 600 ? 17 : 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: box.maxWidth < 600 ? 10 : 20),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: box.maxWidth < 600 ? 24 : 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: box.maxHeight < 720 ? 8 : 14),
                  Row(
                    children: [
                      ActionButton(
                        Icons.camera_alt_outlined,
                        'Reprendre',
                        retakePhoto,
                      ),
                      const SizedBox(width: 10),
                      ActionButton(
                        Icons.check_circle_outline,
                        'Terminer',
                        showRatingDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> openGeneration() async {
    final availableOutfits = currentCategoryOutfits;
    final outfit =
        selectedOutfit ??
        (availableOutfits.isEmpty ? null : availableOutfits.first);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GenerationScreen(
          userPhotoBytes: capturedPhotoBytes!,
          category:
              outfit?.category ??
              (categories.isEmpty ? 'Catalogue' : categories[category]),
          lookName: outfit?.name ?? looks[look].$1,
          lookColor: outfit?.color ?? looks[look].$2,
          lookImageUrl: outfit?.fullImageUrl.isNotEmpty == true
              ? outfit!.fullImageUrl
              : (outfit?.thumbnailUrl ?? ''),
        ),
      ),
    );
  }

  void changeGender(bool value) {
    if (female == value) return;
    setState(() {
      female = value;
      category = 0;
      look = 0;
      selectedOutfit = null;
    });
  }

  Widget buildOutfitPicker() {
    final outfits = currentCategoryOutfits;
    return LookPicker(
      selected: look.clamp(0, outfits.isEmpty ? 0 : outfits.length - 1),
      outfits: outfits,
      loading: outfitsLoading,
      errorMessage: outfitsError,
      onChanged: (index, outfit) => setState(() {
        look = index;
        selectedOutfit = outfit;
      }),
    );
  }
}

class CameraBackground extends StatelessWidget {
  const CameraBackground({
    super.key,
    required this.controller,
    required this.error,
    required this.retry,
  });
  final CameraController? controller;
  final String? error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    if (controller?.value.isInitialized == true) {
      final s = controller!.value.previewSize!;
      return ClipRect(
        child: FittedBox(
          fit: kIsWeb && MediaQuery.sizeOf(context).width < 600
              ? BoxFit.contain
              : BoxFit.cover,
          child: SizedBox(
            width: kIsWeb ? s.width : s.height,
            height: kIsWeb ? s.height : s.width,
            child: CameraPreview(controller!),
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffd8cdc5), Color(0xfff2ece7), Color(0xffb9aaa2)],
        ),
      ),
      alignment: Alignment.center,
      child: error == null
          ? const CircularProgressIndicator()
          : TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.videocam_off_outlined),
              label: const Text('Autoriser la caméra'),
            ),
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .56),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white70),
        ),
        child: child,
      ),
    ),
  );
}

class GenderChip extends StatelessWidget {
  const GenderChip(this.label, this.selected, this.tap, {super.key});
  final String label;
  final bool selected;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: tap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 19,
        vertical: MediaQuery.sizeOf(context).width < 600 ? 8 : 11,
      ),
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xff315dff), Color(0xff6c40f4)],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xff162066),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });
  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      height: compact ? 48 : 58,
      child: Glass(
        padding: EdgeInsets.all(compact ? 5 : 8),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
              child: Text(
                compact ? 'Looks' : 'Catalogues',
                style: TextStyle(
                  color: const Color(0xff07145a),
                  fontSize: compact ? 11 : 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(width: compact ? 4 : 6),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 11 : 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected == i
                          ? const LinearGradient(
                              colors: [Color(0xff285dff), Color(0xffff5c9c)],
                            )
                          : null,
                      color: selected == i ? null : Colors.white38,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      items[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected == i
                            ? Colors.white
                            : const Color(0xff07145a),
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LookPicker extends StatelessWidget {
  const LookPicker({
    super.key,
    required this.selected,
    required this.outfits,
    required this.onChanged,
    this.loading = false,
    this.errorMessage,
  });

  final int selected;
  final List<Outfit> outfits;
  final void Function(int, Outfit?) onChanged;
  final bool loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).width < 600 ? 94 : 126,
      child: Glass(
        padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 6 : 9),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Text(
                  'Firestore: $errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : outfits.isEmpty
            ? const Center(
                child: Text(
                  'Aucune tenue trouvee',
                  style: TextStyle(
                    color: Color(0xff07145a),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: outfits.isEmpty
                    ? _TryOnScreenState.looks.length
                    : outfits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _TryOnScreenState
                      .looks[index % _TryOnScreenState.looks.length];
                  final outfit = outfits.isEmpty ? null : outfits[index];
                  final active = index == selected;

                  return GestureDetector(
                    onTap: () => onChanged(index, outfit),
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width < 600 ? 52 : 66,
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: MediaQuery.sizeOf(context).width < 600
                                ? 52
                                : 66,
                            height: 74,
                            padding: EdgeInsets.all(active ? 4 : 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: active
                                  ? const SweepGradient(
                                      colors: [
                                        Color(0xff175cff),
                                        Color(0xffff5aa5),
                                        Color(0xff175cff),
                                      ],
                                    )
                                  : null,
                              color: active ? null : Colors.white,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: outfit?.color ?? item.$2,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (outfit != null &&
                                      outfit.thumbnailUrl.isNotEmpty)
                                    ClipOval(
                                      child: Image.network(
                                        outfit.thumbnailUrl,
                                        width:
                                            MediaQuery.sizeOf(context).width <
                                                600
                                            ? 46
                                            : 60,
                                        height:
                                            MediaQuery.sizeOf(context).width <
                                                600
                                            ? 50
                                            : 66,
                                        fit:
                                            kIsWeb &&
                                                MediaQuery.sizeOf(
                                                      context,
                                                    ).width <
                                                    600
                                            ? BoxFit.contain
                                            : BoxFit.cover,
                                        webHtmlElementStrategy:
                                            WebHtmlElementStrategy.prefer,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.person_rounded,
                                          size:
                                              MediaQuery.sizeOf(context).width <
                                                  600
                                              ? 40
                                              : 52,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.person_rounded,
                                      size:
                                          MediaQuery.sizeOf(context).width < 600
                                          ? 40
                                          : 52,
                                      color: Colors.white.withValues(
                                        alpha: .82,
                                      ),
                                    ),
                                  if (active)
                                    const Positioned(
                                      right: 0,
                                      top: 0,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Color(0xff5362f4),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            outfit?.name ?? item.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xff07145a),
                              fontSize: MediaQuery.sizeOf(context).width < 600
                                  ? 10
                                  : 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class Outfit {
  const Outfit({
    required this.id,
    required this.name,
    required this.gender,
    required this.category,
    required this.thumbnailUrl,
    required this.fullImageUrl,
    required this.active,
    required this.color,
  });

  final String id;
  final String name;
  final String gender;
  final String category;
  final String thumbnailUrl;
  final String fullImageUrl;
  final bool active;
  final Color color;

  factory Outfit.fromFirestore(String id, Map<String, dynamic> data) {
    final activeValue = data['active'];
    return Outfit(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : 'Tenue',
      gender: (data['gender'] as String? ?? '').toLowerCase(),
      category: (data['category'] as String? ?? '').trim(),
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      fullImageUrl: data['fullImageUrl'] as String? ?? '',
      active:
          activeValue == true || activeValue.toString().toLowerCase() == 'true',
      color: const Color(0xff6f358c),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton(this.icon, this.label, this.tap, {super.key});
  final IconData icon;
  final String label;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: Glass(
        radius: MediaQuery.sizeOf(context).width < 600 ? 14 : 18,
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).width < 600 ? 10 : 15,
          horizontal: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xff5361f4),
              size: MediaQuery.sizeOf(context).width < 600 ? 19 : 24,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xff07145a),
                  fontWeight: FontWeight.w800,
                  fontSize: MediaQuery.sizeOf(context).width < 600 ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({
    super.key,
    required this.userPhotoBytes,
    required this.category,
    required this.lookName,
    required this.lookColor,
    required this.lookImageUrl,
  });

  final Uint8List userPhotoBytes;
  final String category;
  final String lookName;
  final Color lookColor;
  final String lookImageUrl;

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _progressTimer;
  Uint8List? _generatedImageBytes;
  String? _error;
  double _progress = .06;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _generateTryOn();
  }

  Future<void> _generateTryOn() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _generatedImageBytes = null;
      _error = null;
      _progress = .06;
    });
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (mounted && _progress < .9) {
        setState(() => _progress = (_progress + .025).clamp(0, .9));
      }
    });

    try {
      if (widget.lookImageUrl.isEmpty) {
        throw Exception("Cette tenue n'a pas d'image de référence.");
      }
      final outfitResponse = await http.get(Uri.parse(widget.lookImageUrl));
      if (outfitResponse.statusCode < 200 || outfitResponse.statusCode >= 300) {
        throw Exception(
          "Impossible de charger l'image de la tenue (${outfitResponse.statusCode}).",
        );
      }

      final ai = FirebaseAI.agentPlatform(location: 'global');
      final model = ai.generativeModel(
        model: 'gemini-3.1-flash-image',
        generationConfig: GenerationConfig(
          responseModalities: [
            ResponseModalities.text,
            ResponseModalities.image,
          ],
        ),
      );
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Perform a high-quality, photorealistic virtual try-on edit. The '
            'first image is the original person photo and is the locked base '
            'image. The second image is the outfit reference '
            '(${widget.category} ${widget.lookName}). Change only the clothing '
            'pixels that are visible in the original photo. Keep the person '
            'exactly as they are: do not regenerate, reshape, beautify, retouch '
            'or reinterpret the face. Preserve the exact facial features, '
            'expression, gaze, glasses, hair, skin texture, skin tone, ears and '
            'accessories. Preserve the exact pose, head position, hand position, '
            'body shape, body proportions and silhouette. Do not move any body '
            'part. Preserve the original crop, framing, camera angle, perspective, '
            'background and lighting. Do not zoom, rotate, extend or recompose '
            'the image. Fit the referenced outfit naturally onto the existing '
            'body and pose, with realistic fabric folds, seams, shadows and '
            'occlusion. Preserve the outfit colors, materials, patterns, cut, '
            'logos and details. Improve clarity and image quality gently without '
            'changing the person or making skin look artificial. The result must '
            'look like the same untouched photo with only the clothes replaced. '
            'Return exactly one final image and no text.',
          ),
          InlineDataPart(
            _imageMimeType(widget.userPhotoBytes),
            widget.userPhotoBytes,
          ),
          InlineDataPart(
            _imageMimeType(outfitResponse.bodyBytes),
            outfitResponse.bodyBytes,
          ),
        ]),
      ]);
      if (response.inlineDataParts.isEmpty) {
        throw Exception(
          "Digiwearit AI n'a retourné aucune image. Réessayez avec une photo plus nette.",
        );
      }
      if (!mounted) return;
      setState(() {
        _generatedImageBytes = response.inlineDataParts.first.bytes;
        _progress = 1;
        _isGenerating = false;
      });
      _controller.stop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _isGenerating = false;
      });
      _controller.stop();
    } finally {
      _progressTimer?.cancel();
    }
  }

  static String _imageMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('ClientFailed to fetch')) {
      return 'Le navigateur bloque le téléchargement de la tenue. Vérifiez la configuration CORS du bucket Firebase Storage.';
    }
    if (message.contains('permission') || message.contains('403')) {
      return 'Firebase AI Logic doit être activé et la facturation Blaze configurée pour ce projet.';
    }
    return message;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _generatedImageBytes != null;
    return Scaffold(
      backgroundColor: const Color(0xff210949),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: 1.15,
            colors: [Color(0xff4c0874), Color(0xff260850), Color(0xff170635)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    if (done)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.memory(
                            _generatedImageBytes!,
                            fit:
                                kIsWeb && MediaQuery.sizeOf(context).width < 600
                                ? BoxFit.contain
                                : BoxFit.cover,
                          ),
                        ),
                      )
                    else if (_error == null)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (_, __) => _GeneratingOrb(
                          animation: _controller,
                          color: widget.lookColor,
                          imageUrl: widget.lookImageUrl,
                        ),
                      )
                    else
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xffff72af),
                        size: 88,
                      ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff5d2383),
                        borderRadius: BorderRadius.circular(
                          MediaQuery.sizeOf(context).width < 600 ? 16 : 20,
                        ),
                      ),
                      child: Text(
                        '✨  DIGIWEARIT AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.sizeOf(context).width < 600
                              ? 10
                              : 11,
                          letterSpacing: .5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      done
                          ? 'Votre essayage est prêt !'
                          : _error != null
                          ? 'Génération impossible'
                          : 'Création de votre\nessayage...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _error ??
                          (done
                              ? '${widget.category} ${widget.lookName}'
                              : 'Digiwearit AI crée votre essayage avec la tenue sélectionnée.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffd6acd9),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    if (!done && _error == null) ...[
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 7,
                          backgroundColor: const Color(0xff512375),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xffff3c9e),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xffdcbbe3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (done)
                      FilledButton.icon(
                        onPressed: () => shareImage(
                          context,
                          bytes: _generatedImageBytes!,
                          fileName: 'digiwearit-look.png',
                          mimeType: 'image/png',
                          text: 'Mon essayage virtuel Digiwearit',
                        ),
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('Partager mon look'),
                      ),
                    if (_error != null)
                      FilledButton.icon(
                        onPressed: () {
                          _controller.repeat();
                          _generateTryOn();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Réessayer'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        done ? 'Retour' : 'Annuler',
                        style: const TextStyle(
                          color: Color(0xffd5b7e8),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratingOrb extends StatelessWidget {
  const _GeneratingOrb({
    required this.animation,
    required this.color,
    required this.imageUrl,
  });

  final Animation<double> animation;
  final Color color;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: animation.value * 6.28,
      child: SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final size in [170.0, 145.0, 120.0])
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: size == 145
                        ? const Color(0xffff2a9a)
                        : const Color(0xff8736dc).withValues(alpha: .75),
                    width: size == 145 ? 3 : 2,
                  ),
                ),
              ),
            Transform.rotate(
              angle: -animation.value * 6.28,
              child: Container(
                width: 82,
                height: 100,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x88ff2999), blurRadius: 20),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: kIsWeb && MediaQuery.sizeOf(context).width < 600
                            ? BoxFit.contain
                            : BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 66,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 66,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
