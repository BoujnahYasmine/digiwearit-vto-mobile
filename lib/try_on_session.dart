import 'package:flutter/foundation.dart';
import 'outfit.dart';
import 'outfit_selection.dart';
import 'experience_session.dart';
import 'nano_banana_service.dart';
import 'try_on_request.dart';
import 'digiwearit_watermark.dart';

enum TryOnStatus { idle, processing, completed, failed }

class TryOnSession extends ChangeNotifier {
  TryOnSession({
    Future<List<Uint8List>> Function(TryOnRequest)? generator,
    Future<Uint8List> Function(Uint8List)? watermark,
  }) : _generator =
           generator ?? ((request) => NanoBananaService().generate(request)),
       _watermark = watermark ?? DigiwearitWatermark().apply;
  static final current = TryOnSession();
  final Future<List<Uint8List>> Function(TryOnRequest) _generator;
  final Future<Uint8List> Function(Uint8List) _watermark;
  String? gender, style, categoryId;
  Outfit? outfit;
  OutfitSelection? selection;
  Uint8List? capturedPhoto;
  List<Uint8List> results = [];
  TryOnStatus status = TryOnStatus.idle;
  PaymentStatus payment = PaymentStatus.pending;
  Object? error;
  int _epoch = 0;
  Future<void>? _pending;
  String? requestId;
  String get userType => ExperienceSession.covered ? 'partner' : 'personal';
  String? get outfitId => outfit?.id;
  bool get covered => payment == PaymentStatus.covered;
  bool get canReveal =>
      status == TryOnStatus.completed &&
      (payment == PaymentStatus.demoPaid || covered);
  void selectGender(String value) {
    reset();
    gender = value;
    notifyListeners();
  }

  void selectStyle(String value) {
    _clearGeneration();
    style = value;
    categoryId = null;
    outfit = null;
    selection = null;
    notifyListeners();
  }

  void selectCategory(String value) {
    _clearGeneration();
    categoryId = value;
    outfit = null;
    selection = null;
    notifyListeners();
  }

  void selectOutfit(OutfitSelection value) {
    _clearGeneration();
    gender = value.gender;
    style = value.style;
    categoryId = value.outfit.categoryId.isNotEmpty
        ? value.outfit.categoryId
        : outfitType(value.outfit);
    outfit = value.outfit;
    selection = value;
    notifyListeners();
  }

  void confirm(OutfitSelection value, Uint8List photo) {
    if (identical(capturedPhoto, photo) && outfit?.id == value.outfit.id)
      return;
    reset();
    selectOutfit(value);
    capturedPhoto = photo;
    payment = ExperienceSession.covered
        ? PaymentStatus.covered
        : PaymentStatus.pending;
    requestId = DateTime.now().microsecondsSinceEpoch.toString();
    notifyListeners();
  }

  Future<void> generate() {
    if (_pending != null) return _pending!;
    if (status == TryOnStatus.completed) return Future.value();
    if (outfit == null || capturedPhoto == null)
      return Future.error(StateError('No confirmed try-on'));
    final epoch = _epoch;
    status = TryOnStatus.processing;
    error = null;
    final request = TryOnRequest(
      userPhotoBytes: capturedPhoto!,
      outfit: outfit!,
      gender: gender!,
      style: style!,
      category: outfitType(outfit!),
      preferredColorName: selection?.preferredColorName,
    );
    final future = Future<void>(() async {
      try {
        final images = await _generator(request);
        if (epoch != _epoch) return;
        if (images.isEmpty) throw StateError('No generated image');
        final branded = <Uint8List>[];
        for (final image in images) {
          try {
            branded.add(await _watermark(image));
          } catch (watermarkError) {
            debugPrint('Digiwearit watermark unavailable: $watermarkError');
            branded.add(image);
          }
        }
        if (epoch != _epoch) return;
        results = branded;
        status = TryOnStatus.completed;
      } catch (failure) {
        if (epoch != _epoch) return;
        error = failure;
        status = TryOnStatus.failed;
      } finally {
        if (epoch == _epoch) {
          _pending = null;
          notifyListeners();
        }
      }
    });
    _pending = future;
    notifyListeners();
    return future;
  }

  void setPayment(PaymentStatus value) {
    payment = value;
    notifyListeners();
  }

  void _clearGeneration() {
    _epoch++;
    _pending = null;
    capturedPhoto = null;
    results = [];
    error = null;
    requestId = null;
    status = TryOnStatus.idle;
    payment = PaymentStatus.pending;
  }

  void reset() {
    _clearGeneration();
    gender = null;
    style = null;
    categoryId = null;
    outfit = null;
    selection = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearGeneration();
    super.dispose();
  }
}
