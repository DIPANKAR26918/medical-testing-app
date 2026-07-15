import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/index.dart';
import '../services/index.dart';
import 'location_selector_sheet.dart';

const Color _rxBackground = Color(0xFFF7F9FC);
const Color _rxSurface = Color(0xFFFFFFFF);

const Color _rxInk = Color(0xFF12172B);
const Color _rxText = Color(0xFF667085);
const Color _rxMuted = Color(0xFF8A96AA);

const Color _rxPrimary = Color(0xFF2F67F5);
const Color _rxPrimarySoft = Color(0xFFEEF4FF);

const Color _rxBorder = Color(0xFFE2E9F3);
const Color _rxDanger = Color(0xFFDC3545);

class PrescriptionUploadCard extends StatefulWidget {
  const PrescriptionUploadCard({super.key});

  @override
  State<PrescriptionUploadCard> createState() => _PrescriptionUploadCardState();
}

class _PrescriptionUploadCardState extends State<PrescriptionUploadCard> {
  static const int _maxImageBytes = 10 * 1024 * 1024;

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
    final location = await _locationService.loadSavedLocation();
    if (!mounted) return;
    setState(() {
      _collectionLocation = location;
      _loadingLocation = false;
    });
  }

  Future<void> _chooseCollectionLocation() async {
    final selected = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .38),
      builder: (_) => LocationSelectorSheet(
        currentLocation: _collectionLocation,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _collectionLocation = selected);
  }

  Future<void> _takePhoto() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    if (!cameraStatus.isGranted) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera access is required to take a photo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (photo == null) return;

    await _setSelectedImage(photo);
  }

  Future<void> _chooseFromGallery() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2200,
      maxHeight: 2200,
    );

    if (photo == null) return;

    await _setSelectedImage(photo);
  }

  Future<void> _setSelectedImage(XFile photo) async {
    final file = File(photo.path);
    final fileSize = await file.length();

    if (!mounted) return;

    if (fileSize > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose an image smaller than 10 MB.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _selectedImage = file;
    });
  }

  void _removeImage() {
    if (_uploading) return;

    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _uploadPrescription() async {
    final image = _selectedImage;
    final location = _collectionLocation;

    if (image == null || _uploading) return;

    if (location == null || location.isEmpty) {
      await _chooseCollectionLocation();
      return;
    }

    final user = _authService.currentUser;

    if (user == null) {
      Navigator.of(context).pushNamed('/auth');
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final imagePath = await _storageService.uploadPrescription(
        image,
        user.id,
      );

      final now = DateTime.now();
      final profile = await _authService.getUserProfile(user.id);

      final createdOrder = await _firestoreService.createOrder(
        Order(
          orderId: '',
          userId: user.id,
          prescriptionImagePath: imagePath,
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
              'message': 'Prescription uploaded. Review is in progress.',
              'timestamp': now.toIso8601String(),
            },
          ],
          createdAt: now,
        ),
        patient: profile,
      );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _SubmissionSuccessSheet(order: createdOrder),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: const {'tabIndex': 1},
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StorageServiceException: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedImage != null;

    return ColoredBox(
      color: _rxBackground,
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: hasImage
                  ? _SelectedPrescriptionView(
                      key: ValueKey(_selectedImage!.path),
                      image: _selectedImage!,
                      uploading: _uploading,
                      onChange: _showPickerSheet,
                      onRemove: _removeImage,
                    )
                  : _EmptyPrescriptionView(
                      key: const ValueKey('empty-prescription'),
                      onChoose: _showPickerSheet,
                      onValidPrescription: _showValidPrescriptionSheet,
                    ),
            ),
          ),
          if (hasImage)
            _BottomReviewBar(
              uploading: _uploading,
              loadingLocation: _loadingLocation,
              location: _collectionLocation,
              onLocationTap: _chooseCollectionLocation,
              onUpload: _uploadPrescription,
            ),
        ],
      ),
    );
  }

  void _showPickerSheet() {
    if (_uploading) return;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _rxSurface,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add prescription',
                style: TextStyle(
                  color: _rxInk,
                  fontSize: 21,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Make sure the entire prescription is clear and visible.',
                style: TextStyle(
                  color: _rxText,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _PickerOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a photo',
                subtitle: 'Use your phone camera',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 12),
              _PickerOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                subtitle: 'Select an existing image',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _chooseFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showValidPrescriptionSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _rxSurface,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A clear prescription should include',
                style: TextStyle(
                  color: _rxInk,
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 18),
              const _PrescriptionRequirement(
                icon: Icons.crop_free_rounded,
                text: 'The entire prescription with all corners visible',
              ),
              const SizedBox(height: 13),
              const _PrescriptionRequirement(
                icon: Icons.visibility_outlined,
                text: 'Readable test names and doctor details',
              ),
              const SizedBox(height: 13),
              const _PrescriptionRequirement(
                icon: Icons.light_mode_outlined,
                text: 'Good lighting without blur, glare, or shadows',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showPickerSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rxPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Add prescription'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyPrescriptionView extends StatelessWidget {
  const _EmptyPrescriptionView({
    required this.onChoose,
    required this.onValidPrescription,
    super.key,
  });

  final VoidCallback onChoose;
  final VoidCallback onValidPrescription;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: _surfaceDecoration(radius: 23),
          child: Column(
            children: [
              const _PrescriptionIllustration(),
              const SizedBox(height: 17),
              const Text(
                'Upload your prescription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _rxInk,
                  fontSize: 21,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 9),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Take a photo or upload an image of your prescription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _rxText,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.upload_file_outlined, size: 21),
                  label: const Text('Upload prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rxPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    splashFactory: InkRipple.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'JPG or PNG  •  Maximum 10 MB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _rxMuted,
                  fontSize: 11.8,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SecurityNote(),
        const SizedBox(height: 14),
        const _ReviewExplanation(),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onValidPrescription,
            style: TextButton.styleFrom(
              foregroundColor: _rxText,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
            child: const Text('What makes a prescription valid?'),
          ),
        ),
      ],
    );
  }
}

class _SelectedPrescriptionView extends StatelessWidget {
  const _SelectedPrescriptionView({
    required this.image,
    required this.uploading,
    required this.onChange,
    required this.onRemove,
    super.key,
  });

  final File image;
  final bool uploading;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return _FullScreenPrescriptionViewer(image: image);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _surfaceDecoration(radius: 23),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: _rxPrimarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _rxPrimary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Prescription selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _rxInk,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !uploading,
                    color: _rxSurface,
                    elevation: 6,
                    tooltip: 'Prescription options',
                    icon: const Icon(Icons.more_horiz_rounded, color: _rxText),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'change') {
                        onChange();
                      }

                      if (value == 'remove') {
                        onRemove();
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'change',
                          child: Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: _rxPrimary,
                              ),
                              SizedBox(width: 10),
                              Text('Replace image'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: _rxDanger,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Remove',
                                style: TextStyle(color: _rxDanger),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                button: true,
                label: 'View full prescription',
                child: GestureDetector(
                  onTap: () {
                    _openFullScreen(context);
                  },
                  child: Hero(
                    tag: image.path,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: double.infinity,
                        height: 230,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return const _ImageFallback();
                              },
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.54),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.open_in_full_rounded,
                                  color: Colors.white,
                                  size: 18,
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
            ],
          ),
        ),
      ],
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
                builder: (context, constraints) {
                  return InteractiveViewer(
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
                          gaplessPlayback: true,
                          errorBuilder: (context, error, stackTrace) {
                            return const _FullScreenImageFallback();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
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

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_outline_rounded, color: _rxMuted, size: 17),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Private and secure. Nothing is booked until you review and approve.',
              style: TextStyle(
                color: _rxText,
                fontSize: 12.2,
                height: 1.42,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewExplanation extends StatelessWidget {
  const _ReviewExplanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 16, 15),
      decoration: BoxDecoration(
        color: _rxSurface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _rxBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InformationIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A test list prepared for you',
                  style: TextStyle(
                    color: _rxInk,
                    fontSize: 14.4,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'We identify the prescribed tests. You review and approve the list before booking.',
                  style: TextStyle(
                    color: _rxText,
                    fontSize: 12.5,
                    height: 1.45,
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

class _InformationIcon extends StatelessWidget {
  const _InformationIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _rxPrimarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fact_check_outlined, color: _rxPrimary, size: 19),
    );
  }
}

class _PrescriptionIllustration extends StatelessWidget {
  const _PrescriptionIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      height: 136,
      child: ClipRect(
        child: Transform.scale(
          scale: 1.30,
          child: Image.asset(
            'assets/images/prescription_upload_icon.jpeg',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.upload_file_outlined,
                color: _rxPrimary,
                size: 62,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomReviewBar extends StatelessWidget {
  const _BottomReviewBar({
    required this.uploading,
    required this.loadingLocation,
    required this.location,
    required this.onLocationTap,
    required this.onUpload,
  });

  final bool uploading;
  final bool loadingLocation;
  final LocationData? location;
  final VoidCallback onLocationTap;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
      decoration: BoxDecoration(
        color: _rxSurface,
        border: const Border(top: BorderSide(color: _rxBorder)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14213D).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: uploading || loadingLocation ? null : onLocationTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _rxPrimarySoft,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: loadingLocation
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.location_on_rounded,
                                color: _rxPrimary,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loadingLocation
                                  ? 'Loading collection address…'
                                  : location == null || location!.isEmpty
                                  ? 'Choose collection address'
                                  : location!.label,
                              style: const TextStyle(
                                color: _rxInk,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              location == null || location!.isEmpty
                                  ? 'Required before sending for review'
                                  : location!.displayAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _rxText,
                                fontSize: 11.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_location_alt_outlined,
                        color: _rxPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: uploading || loadingLocation
                    ? null
                    : location == null || location!.isEmpty
                    ? onLocationTap
                    : onUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: _rxPrimary,
              disabledBackgroundColor: _rxPrimary.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
                child: uploading
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        location == null || location!.isEmpty
                            ? Icons.location_on_outlined
                            : Icons.cloud_upload_outlined,
                        size: 21,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        location == null || location!.isEmpty
                            ? 'Choose address to continue'
                            : 'Send for medical review',
                      ),
                    ],
                  ),
              ),
            ),
          ],
          ),
      ),
    );
  }
}

class _SubmissionSuccessSheet extends StatelessWidget {
  const _SubmissionSuccessSheet({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: _rxBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prescription sent securely',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _rxInk,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Request #${order.orderId} is now with the medical review team. You’ll approve the prepared tests before the booking is confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _rxText,
                fontSize: 13,
                height: 1.48,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Track in Bookings'),
                style: FilledButton.styleFrom(
                  backgroundColor: _rxPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class _PickerOption extends StatelessWidget {
  const _PickerOption({
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
      color: _rxSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _rxBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _rxPrimarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _rxPrimary, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _rxInk,
                        fontSize: 14.5,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _rxText,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _rxMuted,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionRequirement extends StatelessWidget {
  const _PrescriptionRequirement({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _rxPrimarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _rxPrimary, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              text,
              style: const TextStyle(
                color: _rxText,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _rxBackground,
      child: Center(
        child: Icon(Icons.broken_image_outlined, color: _rxMuted, size: 35),
      ),
    );
  }
}

class _FullScreenImageFallback extends StatelessWidget {
  const _FullScreenImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 42),
    );
  }
}

BoxDecoration _surfaceDecoration({double radius = 20}) {
  return BoxDecoration(
    color: _rxSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _rxBorder),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF17213A).withValues(alpha: 0.035),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
