import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PrescriptionUploadCard extends StatelessWidget {
  const PrescriptionUploadCard({super.key});

  static const Color _teal = Color(0xFF0E8C93);
  static const Color _deepBlue = Color(0xFF0F2A44);
  static const Color _orange = Color(0xFFF97316);

  Future<void> _handleUploadTap(BuildContext context) async {
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upload prescription",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _deepBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose a photo from camera or gallery.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: .60),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sheetTile(
                  icon: Icons.camera_alt_rounded,
                  title: "Take a photo",
                  subtitle: "Use camera now",
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _takePhoto(context);
                  },
                ),
                const SizedBox(height: 8),
                _sheetTile(
                  icon: Icons.photo_library_rounded,
                  title: "Choose from gallery",
                  subtitle: "Pick an existing image",
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _chooseFromGallery(context);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _takePhoto(BuildContext context) async {
    final PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    if (!cameraStatus.isGranted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera access is required.")),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      debugPrint("Camera Path: ${photo.path}");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription photo selected.")),
      );
    }
  }

  Future<void> _chooseFromGallery(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (photo != null) {
      debugPrint("Gallery Path: ${photo.path}");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription image selected.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF7FF), Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _teal.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.thumb_up_alt_rounded, size: 14, color: _teal),
                    SizedBox(width: 6),
                    Text(
                      "RECOMMENDED",
                      style: TextStyle(
                        color: _teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  "SAVE 20%",
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: .4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Not sure which\ntests to book?",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: _deepBlue,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      "Upload the prescription. We'll map it to the right tests and help you book in one tap.",
                      style: TextStyle(
                        fontSize: 13.3,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SoftChip(icon: Icons.verified_rounded, text: "Expert review"),
              _SoftChip(icon: Icons.savings_outlined, text: "Save 20%"),
              _SoftChip(icon: Icons.flash_on_rounded, text: "Faster booking"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _handleUploadTap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_upload_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Upload Prescription",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Camera or gallery - No test-name guesswork",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionIcon() {
    return Container(
      height: 62,
      width: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: .18), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/prescription_icon.png',
          color: const Color(0xFF044B4B),
          width: 30,
          height: 30,
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: .05)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _deepBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.black.withValues(alpha: .60),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SoftChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 1),
          Icon(icon, size: 15, color: Color(0xFF0E8C93)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F2A44),
            ),
          ),
        ],
      ),
    );
  }
}
