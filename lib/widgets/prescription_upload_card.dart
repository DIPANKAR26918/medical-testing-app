import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PrescriptionUploadCard extends StatelessWidget {
  const PrescriptionUploadCard({super.key});

  Future<void> _handleUploadTap(BuildContext context) async {
    final PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    if (!cameraStatus.isGranted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera access is required.")),
      );
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF08B1AC)),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final ImagePicker picker = ImagePicker();
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    debugPrint("Camera Path: ${photo.path}");
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF08B1AC),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  final PermissionState ps =
                      await PhotoManager.requestPermissionExtend();

                  if (ps.isAuth || ps.hasAccess) {
                    if (!context.mounted) return;

                    final List<AssetEntity>? result =
                        await AssetPicker.pickAssets(
                          context,
                          pickerConfig: const AssetPickerConfig(
                            maxAssets: 1,
                            requestType: RequestType.image,
                            themeColor: Color(0xFF08B1AC),
                          ),
                        );

                    if (result != null && result.isNotEmpty) {
                      final file = await result.first.file;
                      debugPrint("Selected Gallery Path: ${file?.path}");
                    }
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gallery access denied.")),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEBFF), Color(0xFFF4F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0E8C93).withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-left recommended badge
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0E8C93).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF0E8C93).withValues(alpha: 0.16),
                ),
              ),
              child: const Text(
                "RECOMMENDED",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: Color(0xFF0E8C93),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Not Sure Which Tests You Need?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2A44),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Upload your doctor's prescription and our medical experts will suggest the right tests for you.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0E8C93).withValues(alpha: 0.10),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, color: Color(0xFF0E8C93), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Avoid wrong tests, save money, and get expert review before booking.",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F2A44),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator("1", "Upload"),
              Expanded(
                child: Center(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF0E8C93).withValues(alpha: 0.14),
                  ),
                ),
              ),
              _buildStepIndicator("2", "Review"),
              Expanded(
                child: Center(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: const Color(0xFF0E8C93).withValues(alpha: 0.14),
                  ),
                ),
              ),
              _buildStepIndicator("3", "Book"),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: const Color(0xFF0E8C93).withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Expert review within 30 mins",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: const Color(0xFF0E8C93).withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Get the right tests, not unnecessary ones",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: () => _handleUploadTap(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08B1AC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload_outlined),
                SizedBox(width: 12),
                Text(
                  "Upload Prescription",
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionIcon() {
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        color: Color.fromARGB(255, 36, 149, 128),
        strokeWidth: 1.5,
        dashPattern: [10, 5],
        radius: Radius.circular(14),
      ),
      child: Container(
        height: 62,
        width: 62,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Image.asset(
          'assets/images/prescription_icon.png',
          color: const Color.fromARGB(255, 4, 75, 75),
          width: 34,
          height: 34,
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String number, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF007A3D).withValues(alpha: 0.12),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF007A3D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F2A44),
          ),
        ),
      ],
    );
  }
}
