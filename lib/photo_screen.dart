import 'experience_failure.dart';
import 'face_smoothing.dart';
import 'mobile_layout.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'beauty_filter.dart';
import 'photo_check.dart';
import 'camera_service.dart';
import 'outfit_selection.dart';
import 'photo_review_screen.dart';
import 'package:flutter/foundation.dart';

class PhotoScreen extends StatefulWidget {
  const PhotoScreen({
    super.key,
    required this.onContinue,
    this.selection,
    this.english,
    this.initializeCamera = true,
    this.makeup = false,
  });
  final OutfitSelection? selection;

  /// Adds blush and a sheer lipstick to the beauty look; femme journeys only.
  final bool makeup;
  final bool? english;
  final Future<void> Function(BuildContext, Uint8List) onContinue;
  final bool initializeCamera;
  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> with WidgetsBindingObserver {
  final _cameraService = CameraService();
  final _faceSmoothing = FaceSmoothing();
  double _smoothing = 0;

  bool _filterLoading = false;
  int _filterEpoch = 0;

  /// The built-in beauty look, always on with no customer choice: the
  /// "Éclat" light on every camera shot, plus on phones (face detection)
  /// smoothing and a light foundation, with blush and lips for femme journeys.
  static const _beautyLevel = .5;
  Future<void> _stopFilter() {
    ++_filterEpoch;
    _smoothing = 0;
    _filterLoading = false;
    _faceSmoothing.setMakeup(foundation: false, color: false);
    return _faceSmoothing.stop();
  }

  Future<void> _setSmoothing(double value, {bool auto = false}) async {
    if (_busy || _countdown > 0 || _filterLoading) return;
    _faceSmoothing.setMakeup(
      foundation: value == _beautyLevel,
      color: widget.makeup && value == _beautyLevel,
    );
    if (value == 0) {
      await _stopFilter();
      if (mounted) setState(() {});
      return;
    }
    if (_smoothing > 0) {
      _faceSmoothing.setStrength(value);
      setState(() => _smoothing = value);
      return;
    }
    final epoch = ++_filterEpoch;
    setState(() => _filterLoading = true);
    final ready = await _faceSmoothing.start(value);
    if (!mounted || epoch != _filterEpoch) return;
    setState(() {
      _filterLoading = false;
      _smoothing = ready ? value : 0;
    });
    if (!ready && !auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Lissage indisponible. La photo originale est conserv\u00e9e.',
              'Smoothing unavailable. Your original photo is preserved.',
            ),
          ),
        ),
      );
    }
  }

  CameraController? _camera;
  List<CameraDescription> _devices = [];
  int _device = 0;
  int _epoch = 0;
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _loading = false, _busy = false;
  late bool _english = widget.english ?? widget.selection?.english ?? false;
  String? _error;
  Uint8List? _photo;
  String t(String fr, String en) => _english ? en : fr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initializeCamera) unawaited(_start());
  }

  Future<void> _start({bool switchLens = false}) async {
    _cancelCountdown();
    final epoch = ++_epoch;
    await _stopFilter();
    if (!mounted || epoch != _epoch) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    CameraController? next;
    try {
      final previous = _camera;
      setState(() => _camera = null);
      await _release(previous);
      if (_devices.isEmpty) {
        _devices = await _cameraService.devices();
        final front = _devices.indexWhere(
          (d) => d.lensDirection == CameraLensDirection.front,
        );
        _device = front < 0 ? 0 : front;
      } else if (switchLens) {
        _device = (_device + 1) % _devices.length;
      }
      if (!mounted || epoch != _epoch) return;
      if (_devices.isEmpty) throw CameraException('no-camera', 'No camera');
      next = await _cameraService.open(_devices[_device], release: _release);
      if (!mounted || epoch != _epoch) {
        await _release(next);
        return;
      }
      _faceSmoothing.bind(next);
      setState(() {
        _camera = next;
        _loading = false;
      });
      if (_faceSmoothing.makeupSupported) {
        unawaited(_setSmoothing(_beautyLevel, auto: true));
      }
    } catch (failure) {
      await _release(next);
      if (mounted && epoch == _epoch) {
        setState(() {
          _loading = false;
          _error =
              failure is CameraException &&
                  failure.code.toLowerCase().contains('denied')
              ? t(
                  Friendly.cameraDenied,
                  'To take your photo, allow the camera in your settings, then come back here 📷',
                )
              : t(
                  Friendly.cameraUnavailable,
                  'The camera isn’t responding right now 📷 Try again, or pick a photo from your gallery.',
                );
        });
      }
    }
  }

  /// Disposes a camera that may never have finished initializing: CameraX
  /// throws when releasing a preview it never created (e.g. while the
  /// permission prompt interrupted startup), which must not crash the screen.
  static Future<void> _release(CameraController? camera) async {
    try {
      await camera?.dispose();
    } catch (error) {
      debugPrint('Camera release ignored: $error');
    }
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (mounted) setState(() => _countdown = 0);
  }

  Future<void> _beginCapture() async {
    if (_busy || _loading || _filterLoading || _countdown > 0) return;
    if (_camera?.value.isInitialized != true) {
      await _start();
      return;
    }
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _camera?.value.isInitialized != true) {
        timer.cancel();
        if (mounted) _cancelCountdown();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _cancelCountdown();
        unawaited(_capture());
      }
    });
  }

  Future<void> _capture({bool gallery = false}) async {
    if (_busy || _countdown > 0) return;
    if (!gallery && _camera?.value.isInitialized != true) {
      await _start();
      return;
    }
    setState(() => _busy = true);
    try {
      Uint8List bytes;
      if (!gallery && _smoothing > 0) {
        try {
          bytes = await _faceSmoothing.capture();
        } catch (error) {
          // The beauty look is automatic, so a plain photo is taken quietly.
          debugPrint('Beauty capture skipped: $error');
          await _stopFilter();
          bytes = await _cameraService.captureBytes(_camera!);
        }
      } else if (gallery) {
        final file = await _cameraService.pickPhoto();
        if (file == null) return;
        bytes = await _cameraService.normalizedBytes(file);
      } else {
        bytes = await _cameraService.captureBytes(_camera!);
      }
      // Automatic light and camera-quality check, before Éclat brightens it.
      PhotoCheck? check;
      try {
        check = await compute(checkPhoto, bytes);
      } catch (error) {
        debugPrint('Photo check skipped: $error');
      }
      if (!gallery) {
        try {
          bytes = await compute(BeautyFilter.apply, bytes);
        } catch (error) {
          debugPrint('Éclat filter skipped: $error');
        }
      }
      await _stopFilter();
      if (!mounted) return;
      final live = _camera;
      _cancelCountdown();
      ++_epoch;
      setState(() {
        _photo = bytes;
        _camera = null;
        _error = null;
        _loading = false;
      });
      await _release(live);
      if (!mounted) return;
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, animation, secondaryAnimation) => PhotoReviewScreen(
            bytes: bytes,
            english: _english,
            check: check,
            onContinue: widget.onContinue,
          ),
        ),
      );
      if (mounted) setState(() => _photo = null);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            action: SnackBarAction(
              label: t('Réessayer', 'Retry'),
              onPressed: () => _capture(gallery: gallery),
            ),
            content: Text(
              t(
                Friendly.photoUnreadable,
                'This photo couldn’t be opened 📷 Take another one or choose a different photo.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_photo == null &&
            _camera == null &&
            !_loading &&
            widget.initializeCamera) {
          unawaited(_start());
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cancelCountdown();
      ++_epoch;
      final stopped = _stopFilter();
      final old = _camera;
      setState(() {
        _camera = null;
        _loading = false;
      });
      unawaited(stopped.then((_) => _release(old)));
    } else if (state == AppLifecycleState.resumed &&
        _photo == null &&
        !_busy &&
        widget.initializeCamera) {
      unawaited(_start());
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    final stopped = _stopFilter();
    ++_epoch;
    WidgetsBinding.instance.removeObserver(this);
    final camera = _camera;
    unawaited(stopped.then((_) => _release(camera)));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xff16151b)),
        if (_photo != null)
          Image.memory(_photo!, fit: BoxFit.cover, alignment: Alignment.center),
        if (_camera?.value.isInitialized == true)
          LayoutBuilder(
            builder: (context, box) {
              var ratio = _camera!.value.aspectRatio;
              if (!kIsWeb &&
                  MediaQuery.orientationOf(context) == Orientation.portrait) {
                ratio = 1 / ratio;
              }
              return ClipRect(
                key: const ValueKey('live-camera-background'),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: 1000 * ratio,
                      height: 1000,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _faceSmoothing.preview(CameraPreview(_camera!)),
                          BeautyFilter.layer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0x66000000),
                ],
                stops: [0, .25, .72, 1],
              ),
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = box.maxHeight < 650;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          _glass(
                            IconButton(
                              tooltip: t('Retour', 'Back'),
                              onPressed: _busy
                                  ? null
                                  : () => Navigator.maybePop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            dark: true,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Image.asset(
                                'lib/logo digiwearit.png',
                                height: 35,
                              ),
                            ),
                          ),
                          _glass(
                            PopupMenuButton<bool>(
                              tooltip: t('Langue', 'Language'),
                              initialValue: _english,
                              onSelected: (value) =>
                                  setState(() => _english = value),
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
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Text(
                                  _english ? 'EN' : 'FR',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            dark: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('Placez-vous face à la caméra', 'Face the camera'),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 19 : 23,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t(
                        'Gardez votre corps entier dans le cadre',
                        'Keep your whole body in the frame',
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const IgnorePointer(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: CustomPaint(
                                key: ValueKey('camera-body-guide'),
                                painter: _BodyGuidePainter(),
                              ),
                            ),
                          ),
                          if (_countdown > 0)
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Semantics(
                                      liveRegion: true,
                                      label: t(
                                        'Photo dans $_countdown secondes',
                                        'Photo in $_countdown seconds',
                                      ),
                                      child: Text(
                                        '$_countdown',
                                        key: const ValueKey('camera-countdown'),
                                        style: const TextStyle(
                                          fontSize: 100,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    _glass(
                                      TextButton(
                                        onPressed: _cancelCountdown,
                                        child: Text(
                                          t('Annuler', 'Cancel'),
                                          style: const TextStyle(
                                            color: digiInk,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_camera == null)
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: box.maxWidth - 52,
                                  child: DigiGlass(
                                    child: _loading
                                        ? const Center(
                                            child: SizedBox(
                                              width: 28,
                                              height: 28,
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _error ??
                                                    t(
                                                      'Activez la caméra pour afficher votre aperçu en direct.',
                                                      'Enable the camera to see your live preview.',
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              FilledButton(
                                                onPressed: _start,
                                                child: Text(
                                                  _error == null
                                                      ? t(
                                                          'Activer la caméra',
                                                          'Enable camera',
                                                        )
                                                      : t('Réessayer', 'Retry'),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_camera != null)
                      ValueListenableBuilder<LightingIssue?>(
                        valueListenable: _faceSmoothing.lighting,
                        builder: (context, issue, _) => issue == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PhotoTip(
                                  lightingAdvice(issue, english: _english),
                                  key: const ValueKey('live-lighting-tip'),
                                ),
                              ),
                      ),
                    if (_camera != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _glass(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Text(
                              t(
                                'Placez vos pieds dans la zone',
                                'Place your feet in the marked area',
                              ),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: digiInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    _glass(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 3,
                          children: [
                            for (final label in [
                              t('Corps entier', 'Full body'),
                              t('Bonne lumière', 'Good light'),
                              t('Visage naturel', 'Natural face'),
                            ])
                              Text(
                                '✓ $label',
                                style: const TextStyle(
                                  color: digiInk,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Padding(
                      padding: EdgeInsets.only(bottom: compact ? 8 : 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _sideControl(
                              Icons.photo_library_outlined,
                              t('Galerie', 'Gallery'),
                              _busy || _countdown > 0
                                  ? null
                                  : () => _capture(gallery: true),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white70,
                                width: 4,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: digiGradient,
                              ),
                              child: IconButton(
                                key: const ValueKey('camera-shutter'),
                                tooltip: t('Prendre la photo', 'Take photo'),
                                onPressed: _busy || _loading || _countdown > 0
                                    ? null
                                    : _beginCapture,
                                padding: EdgeInsets.all(compact ? 19 : 24),
                                icon: _busy
                                    ? const SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _sideControl(
                              Icons.cameraswitch_outlined,
                              t('Changer caméra', 'Switch camera'),
                              _busy ||
                                      _loading ||
                                      _countdown > 0 ||
                                      _devices.length < 2
                                  ? null
                                  : () => _start(switchLens: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _glass(Widget child, {bool dark = false}) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? Colors.black26 : Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    ),
  );

  Widget _sideControl(IconData icon, String label, VoidCallback? action) =>
      TextButton(
        onPressed: action,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: action == null ? Colors.white30 : Colors.white70,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 25),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      );
}

/// Visual positioning guide only; it does not claim to detect pose or lighting.
class _BodyGuidePainter extends CustomPainter {
  const _BodyGuidePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = (height * .45).clamp(0.0, size.width * .75);
    if (width <= 0 || height <= 0) return;
    canvas.save();
    canvas.translate((size.width - width) / 2, 0);
    canvas.scale(width / 100, height / 250);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // A single unfilled head, shoulders, arms, torso, legs and feet outline.
    final body = Path()
      ..moveTo(50, 14)
      ..cubicTo(34, 14, 32, 37, 39, 46)
      ..lineTo(39, 51)
      ..cubicTo(33, 55, 23, 52, 20, 66)
      ..lineTo(17, 105)
      ..lineTo(10, 141)
      ..quadraticBezierTo(8, 148, 13, 153)
      ..quadraticBezierTo(18, 157, 18, 150)
      ..lineTo(17, 140)
      ..lineTo(27, 109)
      ..lineTo(29, 81)
      ..quadraticBezierTo(34, 103, 30, 116)
      ..quadraticBezierTo(23, 139, 29, 160)
      ..lineTo(36, 196)
      ..lineTo(37, 225)
      ..lineTo(33, 232)
      ..quadraticBezierTo(31, 237, 43, 235)
      ..lineTo(46, 229)
      ..lineTo(45, 196)
      ..lineTo(49, 155)
      ..quadraticBezierTo(50, 150, 51, 155)
      ..lineTo(55, 196)
      ..lineTo(54, 229)
      ..lineTo(57, 235)
      ..quadraticBezierTo(69, 237, 67, 232)
      ..lineTo(63, 225)
      ..lineTo(64, 196)
      ..lineTo(71, 160)
      ..quadraticBezierTo(77, 139, 70, 116)
      ..quadraticBezierTo(66, 103, 71, 81)
      ..lineTo(73, 109)
      ..lineTo(83, 140)
      ..lineTo(82, 150)
      ..quadraticBezierTo(82, 157, 87, 153)
      ..quadraticBezierTo(92, 148, 90, 141)
      ..lineTo(83, 105)
      ..lineTo(80, 66)
      ..cubicTo(77, 52, 67, 55, 61, 51)
      ..lineTo(61, 46)
      ..cubicTo(68, 37, 66, 14, 50, 14)
      ..close();
    canvas.drawPath(body, line);
    final corners = Path()
      ..moveTo(0, 18)
      ..lineTo(0, 7)
      ..quadraticBezierTo(0, 2, 5, 2)
      ..lineTo(13, 2)
      ..moveTo(87, 2)
      ..lineTo(95, 2)
      ..quadraticBezierTo(100, 2, 100, 7)
      ..lineTo(100, 18)
      ..moveTo(0, 232)
      ..lineTo(0, 243)
      ..quadraticBezierTo(0, 248, 5, 248)
      ..lineTo(13, 248)
      ..moveTo(87, 248)
      ..lineTo(95, 248)
      ..quadraticBezierTo(100, 248, 100, 243)
      ..lineTo(100, 232);
    canvas.drawPath(corners, line..strokeWidth = 1.7);
    line
      ..strokeWidth = .55
      ..color = Colors.white.withValues(alpha: .35);
    for (double y = 23; y < 230; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 3), line);
      canvas.drawLine(Offset(100, y), Offset(100, y + 3), line);
    }
    canvas.drawOval(const Rect.fromLTWH(14, 231, 72, 16), line);
    final feet = Paint()..color = Colors.white.withValues(alpha: .45);
    canvas.drawOval(const Rect.fromLTWH(42, 237, 5, 6), feet);
    canvas.drawOval(const Rect.fromLTWH(53, 237, 5, 6), feet);
    canvas.drawOval(const Rect.fromLTWH(43, 244, 3, 2), feet);
    canvas.drawOval(const Rect.fromLTWH(54, 244, 3, 2), feet);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyGuidePainter oldDelegate) => false;
}
