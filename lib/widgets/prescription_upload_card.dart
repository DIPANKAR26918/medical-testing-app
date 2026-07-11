import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/index.dart';
import '../services/index.dart';
import '../utils/app_theme.dart';

const Color _primary = AppTheme.primaryColor;
const Color _dark = AppTheme.textDark;
const Color _muted = AppTheme.textLight;
const Color _weak = AppTheme.textWeak;
const Color _border = AppTheme.borderColor;
const Color _uploadBg = Color(0xFFF8FBFF);

class PrescriptionUploadCard extends StatefulWidget {
  const PrescriptionUploadCard({super.key});

  @override
  State<PrescriptionUploadCard> createState() => _PrescriptionUploadCardState();
}

class _PrescriptionUploadCardState extends State<PrescriptionUploadCard> {
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _selectedImage;
  bool _uploading = false;

  Future<void> _takePhoto() async {
    final PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    if (!cameraStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera access is required.')),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) return;
    _setSelectedImage(photo);
  }

  Future<void> _chooseFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (photo == null) return;
    _setSelectedImage(photo);
  }

  void _setSelectedImage(XFile photo) {
    setState(() {
      _selectedImage = File(photo.path);
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _uploadPrescription() async {
    final image = _selectedImage;
    if (image == null || _uploading) return;

    final user = _authService.currentUser;
    if (user == null) {
      Navigator.of(context).pushNamed('/auth');
      return;
    }

    setState(() => _uploading = true);

    try {
      final imagePath = await _storageService.uploadPrescription(
        image,
        user.id,
      );
      final now = DateTime.now();
      final profile = await _authService.getUserProfile(user.id);

      await _firestoreService.createOrder(
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: const {'tabIndex': 1},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cleanError(error))));
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
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _selectedImage == null
                ? KeyedSubtree(
                    key: const ValueKey('empty-upload'),
                    child: _buildEmptyState(),
                  )
                : KeyedSubtree(
                    key: ValueKey(_selectedImage!.path),
                    child: _buildPreviewState(),
                  ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UploadZone(onTap: _showPickerSheet),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: _takePhoto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _chooseFromGallery,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPreviewState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: .58),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _removeImage,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showPickerSheet,
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retake or choose another'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bool hasImage = _selectedImage != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SecurityNote(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: hasImage && !_uploading ? _uploadPrescription : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: const Color(0xFFE7EAF0),
                  disabledForegroundColor: const Color(0xFFA4ADBB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Prescription'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select source',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SheetOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take a photo',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _takePhoto();
                  },
                ),
                const SizedBox(height: 8),
                _SheetOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from gallery',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _chooseFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: _uploadBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _primary.withValues(alpha: .24),
            width: 1.4,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: _primary.withValues(alpha: .06),
          highlightColor: _primary.withValues(alpha: .04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: .09),
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary.withValues(alpha: .10)),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: _primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Upload Prescription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Tap to take a photo or choose from gallery',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: _muted,
                    fontWeight: FontWeight.w500,
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

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: _weak),
        SizedBox(width: 6),
        Text(
          'Your prescription is secure & private',
          style: TextStyle(
            fontSize: 12,
            color: _weak,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: _primary.withValues(alpha: .06),
          highlightColor: _primary.withValues(alpha: .04),
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: _primary),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _dark,
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

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: _primary),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _dark,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 20, color: _weak),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
