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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF7FF), Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF08B1AC).withValues(alpha: .08),
        ),
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
        children: [
          // Recommended Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF08B1AC).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_alt_rounded,
                  size: 14,
                  color: Color(0xFF08B1AC),
                ),
                SizedBox(width: 6),
                Text(
                  "RECOMMENDED",
                  style: TextStyle(
                    color: Color(0xFF08B1AC),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: .6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Main Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Not Sure Which\nTests To Book?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2A44),
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Upload your doctor's prescription and our experts will recommend the right tests for you.",
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Process Flow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: .04)),
            ),
            child: Row(
              children: [
                _flowItem("1", "Upload"),

                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),

                _flowItem("2", "Review"),

                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),

                _flowItem("3", "Book"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () => _handleUploadTap(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF08B1AC),
                elevation: 2,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
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

  Widget _flowItem(String number, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFF08B1AC).withValues(alpha: .12),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF08B1AC),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),

        const SizedBox(height: 2),

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
