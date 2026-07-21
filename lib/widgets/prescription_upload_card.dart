import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../models/index.dart';
import '../screens/prescription_submitted_screen.dart';
import '../services/index.dart';
import '../utils/index.dart';
import 'location_selector_sheet.dart';

class PrescriptionUploadCard extends StatefulWidget {
  const PrescriptionUploadCard({super.key});

  @override
  State<PrescriptionUploadCard> createState() => _PrescriptionUploadCardState();
}

class _PrescriptionUploadCardState extends State<PrescriptionUploadCard> {
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  File? _selectedImage;
  LocationData? _collectionLocation;
  bool _uploading = false;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadCollectionLocation();
  }

  Future<void> _loadCollectionLocation() async {
    try {
      final location = await _locationService.loadSavedLocation();
      if (!mounted) return;
      setState(() => _collectionLocation = location);
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _chooseCollectionLocation() async {
    if (_uploading || _loadingLocation) return;

    final selected = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .38),
      builder: (_) =>
          LocationSelectorSheet(currentLocation: _collectionLocation),
    );

    if (selected == null || !mounted) return;
    setState(() => _collectionLocation = selected);
  }

  Future<void> _takePhoto() async {
    if (_uploading) return;

    final cameraStatus = await Permission.camera.request();
    if (!mounted) return;

    if (cameraStatus.isPermanentlyDenied) {
      await _showCameraSettingsDialog();
      return;
    }

    if (!cameraStatus.isGranted) {
      _showMessage('Allow camera access to take a prescription photo.');
      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );

    if (photo != null) await _setSelectedImage(photo);
  }

  Future<void> _chooseFromGallery() async {
    if (_uploading) return;

    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
      requestFullMetadata: false,
    );

    if (photo != null) await _setSelectedImage(photo);
  }

  Future<void> _setSelectedImage(XFile photo) async {
    final file = File(photo.path);
    final extension = p.extension(photo.path).toLowerCase();

    if (!_allowedExtensions.contains(extension)) {
      if (mounted) {
        _showMessage('Choose a JPG, PNG, or WebP prescription image.');
      }
      return;
    }

    final exists = await file.exists();
    final fileSize = exists ? await file.length() : 0;
    if (!mounted) return;

    if (!exists || fileSize == 0) {
      _showMessage('This image could not be opened. Choose another file.');
      return;
    }

    if (fileSize > _maxImageBytes) {
      _showMessage('Choose an image smaller than 10 MB.');
      return;
    }

    setState(() => _selectedImage = file);
  }

  void _removeImage() {
    if (_uploading) return;
    setState(() => _selectedImage = null);
  }

  Future<void> _uploadPrescription() async {
    final image = _selectedImage;
    if (image == null || _uploading) return;

    final location = _collectionLocation;
    if (location == null || location.isEmpty) {
      await _chooseCollectionLocation();
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.of(context).pushNamed('/auth');
      return;
    }

    setState(() => _uploading = true);
    String? uploadedPath;

    try {
      uploadedPath = await _storageService.uploadPrescription(image, user.id);
      final now = AppTime.nowUtc();
      final profile = await _authService.getUserProfile(user.id);

      final createdOrder = await _firestoreService.createOrder(
        Order(
          orderId: '',
          userId: user.id,
          prescriptionImagePath: uploadedPath,
          status: 'uploaded',
          testList: const [],
          price: 0,
          patientName: profile?.name,
          patientPhoneNumber: profile?.phoneNumber,
          patientAge: profile?.age,
          patientGender: profile?.gender,
          collectionAddressId: location.id,
          patientLocationAddress: location.displayAddress,
          patientLocationLatitude: location.latitude,
          patientLocationLongitude: location.longitude,
          patientLocationType: location.type.name,
          timeline: [
            {
              'status': 'uploaded',
              'message': 'Prescription received for medical review.',
              'timestamp': AppTime.utcIsoString(now),
            },
          ],
          createdAt: now,
        ),
        patient: profile,
      );

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PrescriptionSubmittedScreen(order: createdOrder),
        ),
      );
    } catch (error) {
      // Avoid leaving an unused object when database insertion fails. The
      // cleanup is best-effort because the original failure is more useful to
      // the user than a secondary storage error.
      if (uploadedPath != null) {
        try {
          await _storageService.deleteImage(uploadedPath);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _uploading = false);
      _showMessage(_cleanError(error));
    }
  }

  Future<void> _showCameraSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.photo_camera_outlined,
          color: PrescriptionFlowTheme.primary,
        ),
        title: const Text('Camera access is off'),
        content: const Text(
          'Turn on camera access in device settings, then return to take a prescription photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StorageServiceException: ', '')
        .replaceFirst('Failed to create order: ', '');

    return message.trim().isEmpty
        ? 'We could not send the prescription. Please try again.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final image = _selectedImage;
    final hasLocation =
        _collectionLocation != null && !_collectionLocation!.isEmpty;

    return ColoredBox(
      color: PrescriptionFlowTheme.background,
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: image == null
                  ? _EmptyPrescriptionView(
                      key: const ValueKey('prescription-empty'),
                      onCamera: _takePhoto,
                      onGallery: _chooseFromGallery,
                      onQualityGuide: _showQualityGuide,
                    )
                  : _SelectedPrescriptionView(
                      key: ValueKey(image.path),
                      image: image,
                      location: _collectionLocation,
                      loadingLocation: _loadingLocation,
                      uploading: _uploading,
                      onChange: _showSourceSheet,
                      onRemove: _removeImage,
                      onLocationTap: _chooseCollectionLocation,
                    ),
            ),
          ),
          if (image != null)
            _ReviewBottomBar(
              uploading: _uploading,
              loadingLocation: _loadingLocation,
              hasLocation: hasLocation,
              onLocationTap: _chooseCollectionLocation,
              onSubmit: _uploadPrescription,
            ),
        ],
      ),
    );
  }

  void _showSourceSheet() {
    if (_uploading) return;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PrescriptionFlowTheme.surface,
      barrierColor: Colors.black.withValues(alpha: .34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Replace prescription',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the clearest version. The entire page should be visible.',
              style: TextStyle(
                color: PrescriptionFlowTheme.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            _SourceOption(
              icon: Icons.photo_camera_outlined,
              title: 'Take a new photo',
              subtitle: 'Best for a paper prescription',
              onTap: () {
                Navigator.pop(sheetContext);
                _takePhoto();
              },
            ),
            const SizedBox(height: 10),
            _SourceOption(
              icon: Icons.photo_library_outlined,
              title: 'Choose from gallery',
              subtitle: 'JPG, PNG, or WebP up to 10 MB',
              onTap: () {
                Navigator.pop(sheetContext);
                _chooseFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityGuide() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PrescriptionFlowTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Take a reviewable photo',
              style: TextStyle(
                color: PrescriptionFlowTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(height: 18),
            const _GuideRow(
              icon: Icons.crop_free_rounded,
              title: 'Show all four corners',
              description: 'Keep the full prescription inside the frame.',
            ),
            const _GuideRow(
              icon: Icons.visibility_outlined,
              title: 'Keep test names readable',
              description: 'Avoid blur, folds, and fingers over the page.',
            ),
            const _GuideRow(
              icon: Icons.light_mode_outlined,
              title: 'Use even lighting',
              description: 'Avoid glare and dark shadows on the writing.',
              last: true,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _takePhoto();
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take photo'),
                style: PrescriptionFlowTheme.filledButtonStyle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrescriptionView extends StatelessWidget {
  const _EmptyPrescriptionView({
    required this.onCamera,
    required this.onGallery,
    required this.onQualityGuide,
    super.key,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onQualityGuide;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      children: [
        const _FlowProgress(currentStep: 0),
        const SizedBox(height: 12),
        _UploadChoiceCard(
          onCamera: onCamera,
          onGallery: onGallery,
          onQualityGuide: onQualityGuide,
        ),
        const SizedBox(height: 12),
        const _ControlPromiseCard(),
      ],
    );
  }
}

class _UploadChoiceCard extends StatelessWidget {
  const _UploadChoiceCard({
    required this.onCamera,
    required this.onGallery,
    required this.onQualityGuide,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onQualityGuide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: PrescriptionFlowTheme.card(),
      child: Column(
        children: [
          const _UploadIllustration(),
          const SizedBox(height: 14),
          const Text(
            'Upload your prescription',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PrescriptionFlowTheme.ink,
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a clear image. Our medical team will prepare the test list for your review.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PrescriptionFlowTheme.text,
              fontSize: 12.5,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text('Take photo'),
                    style: PrescriptionFlowTheme.filledButtonStyle().copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 19),
                    label: const Text('Gallery'),
                    style: PrescriptionFlowTheme.outlinedButtonStyle().copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'JPG, PNG or WebP · max 10 MB',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PrescriptionFlowTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onQualityGuide,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                icon: const Icon(Icons.help_outline_rounded, size: 16),
                label: const Text('Photo tips'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadIllustration extends StatelessWidget {
  const _UploadIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: PrescriptionFlowTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -.07,
            child: Container(
              width: 56,
              height: 70,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PrescriptionFlowTheme.primaryOutline),
                boxShadow: PrescriptionFlowTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rx',
                    style: TextStyle(
                      color: PrescriptionFlowTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...[27.0, 35.0, 23.0].map(
                    (width) => Container(
                      width: width,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: PrescriptionFlowTheme.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: PrescriptionFlowTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPromiseCard extends StatelessWidget {
  const _ControlPromiseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PrescriptionFlowTheme.card(
        color: PrescriptionFlowTheme.primaryContainer,
        borderColor: PrescriptionFlowTheme.primaryOutline,
        radius: 18,
        shadow: false,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: PrescriptionFlowTheme.primary,
            size: 23,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You stay in control',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review every test and price before booking. Your prescription stays private.',
                  style: TextStyle(
                    color: PrescriptionFlowTheme.text,
                    fontSize: 11.5,
                    height: 1.38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPrescriptionView extends StatelessWidget {
  const _SelectedPrescriptionView({
    required this.image,
    required this.location,
    required this.loadingLocation,
    required this.uploading,
    required this.onChange,
    required this.onRemove,
    required this.onLocationTap,
    super.key,
  });

  final File image;
  final LocationData? location;
  final bool loadingLocation;
  final bool uploading;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  final VoidCallback onLocationTap;

  bool get _hasLocation => location != null && !location!.isEmpty;

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenPrescriptionViewer(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        _FlowProgress(currentStep: _hasLocation ? 2 : 1),
        const SizedBox(height: 12),
        _PrescriptionPreviewCard(
          image: image,
          uploading: uploading,
          onOpen: () => _openFullScreen(context),
          onChange: onChange,
          onRemove: onRemove,
        ),
        const SizedBox(height: 12),
        _CollectionAddressCard(
          location: location,
          loading: loadingLocation,
          enabled: !uploading,
          onTap: onLocationTap,
        ),
      ],
    );
  }
}

class _PrescriptionPreviewCard extends StatelessWidget {
  const _PrescriptionPreviewCard({
    required this.image,
    required this.uploading,
    required this.onOpen,
    required this.onChange,
    required this.onRemove,
  });

  final File image;
  final bool uploading;
  final VoidCallback onOpen;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: PrescriptionFlowTheme.card(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 1, 0, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: PrescriptionFlowTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Prescription',
                    style: TextStyle(
                      color: PrescriptionFlowTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: uploading ? null : onChange,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Replace'),
                ),
                IconButton(
                  onPressed: uploading ? null : onRemove,
                  tooltip: 'Remove prescription',
                  style: IconButton.styleFrom(
                    foregroundColor: PrescriptionFlowTheme.danger,
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'View full prescription image',
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 178,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(
                        color: PrescriptionFlowTheme.surfaceMuted,
                      ),
                      Hero(
                        tag: image.path,
                        child: Image.file(
                          image,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) =>
                              const _ImageFallback(),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x0D000000),
                              Color(0x85000000),
                            ],
                            stops: [0, .68, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 10,
                        bottom: 10,
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Tap to inspect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .44),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .24),
                                ),
                              ),
                              child: const Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white,
                                size: 16,
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  color: PrescriptionFlowTheme.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check that the full page, doctor details and test names are clear.',
                    style: TextStyle(
                      color: PrescriptionFlowTheme.text,
                      fontSize: 11.2,
                      height: 1.38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionAddressCard extends StatelessWidget {
  const _CollectionAddressCard({
    required this.location,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final LocationData? location;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null && !location!.isEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled && !loading ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: PrescriptionFlowTheme.card(
            color: hasLocation
                ? PrescriptionFlowTheme.surface
                : PrescriptionFlowTheme.primaryContainer,
            borderColor: hasLocation
                ? PrescriptionFlowTheme.outline
                : PrescriptionFlowTheme.primaryOutline,
            radius: 18,
            shadow: false,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasLocation
                      ? PrescriptionFlowTheme.primaryContainer
                      : PrescriptionFlowTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: loading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(
                        Icons.location_on_outlined,
                        color: PrescriptionFlowTheme.primary,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COLLECTION ADDRESS',
                      style: TextStyle(
                        color: PrescriptionFlowTheme.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .65,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading
                          ? 'Loading saved address…'
                          : hasLocation
                          ? location!.label
                          : 'Choose collection address',
                      style: const TextStyle(
                        color: PrescriptionFlowTheme.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLocation
                          ? location!.displayAddress
                          : 'Required before sending for medical review',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PrescriptionFlowTheme.text,
                        fontSize: 11.5,
                        height: 1.36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                hasLocation ? Icons.edit_outlined : Icons.chevron_right_rounded,
                color: PrescriptionFlowTheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({
    required this.uploading,
    required this.loadingLocation,
    required this.hasLocation,
    required this.onLocationTap,
    required this.onSubmit,
  });

  final bool uploading;
  final bool loadingLocation;
  final bool hasLocation;
  final VoidCallback onLocationTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: PrescriptionFlowTheme.outline)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1410213D),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (uploading) ...[
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(99)),
                child: LinearProgressIndicator(minHeight: 3),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: uploading || loadingLocation
                    ? null
                    : hasLocation
                    ? onSubmit
                    : onLocationTap,
                icon: uploading
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Icon(
                        hasLocation
                            ? Icons.lock_outline_rounded
                            : Icons.location_on_outlined,
                        size: 19,
                      ),
                label: Text(
                  uploading
                      ? 'Sending securely…'
                      : hasLocation
                      ? 'Send for medical review'
                      : 'Choose address to continue',
                ),
                style: PrescriptionFlowTheme.filledButtonStyle(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              uploading
                  ? 'Keep this screen open until submission is complete.'
                  : 'No test is booked until you approve the reviewed list.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PrescriptionFlowTheme.muted,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowProgress extends StatelessWidget {
  const _FlowProgress({required this.currentStep});

  final int currentStep;

  static const _labels = ['Prescription', 'Address', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentStep + 1} of 3: ${_labels[currentStep]}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
        decoration: PrescriptionFlowTheme.card(
          color: PrescriptionFlowTheme.surface,
          radius: 16,
          shadow: false,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _labels[currentStep],
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  'Step ${currentStep + 1} of ${_labels.length}',
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var index = 0; index < _labels.length; index++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= currentStep
                            ? PrescriptionFlowTheme.primary
                            : PrescriptionFlowTheme.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  if (index != _labels.length - 1)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PrescriptionFlowTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: PrescriptionFlowTheme.card(radius: 18, shadow: false),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PrescriptionFlowTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: PrescriptionFlowTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PrescriptionFlowTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PrescriptionFlowTheme.text,
                        fontSize: 11.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: PrescriptionFlowTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.title,
    required this.description,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PrescriptionFlowTheme.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: PrescriptionFlowTheme.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: PrescriptionFlowTheme.text,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPrescriptionViewer extends StatelessWidget {
  const _FullScreenPrescriptionViewer({required this.image});

  final File image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Hero(
                      tag: image.path,
                      child: Image.file(
                        image,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) =>
                            const _FullScreenImageFallback(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: .58),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Text(
                'Pinch to zoom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PrescriptionFlowTheme.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: PrescriptionFlowTheme.muted,
          size: 36,
        ),
      ),
    );
  }
}

class _FullScreenImageFallback extends StatelessWidget {
  const _FullScreenImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44),
    );
  }
}
