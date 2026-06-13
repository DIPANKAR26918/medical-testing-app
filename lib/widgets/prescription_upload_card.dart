import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PrescriptionUploadCard extends StatelessWidget {
  const PrescriptionUploadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 208, 228, 255),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.09),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upload Prescription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Upload your prescription and our medical experts will review and suggest the right tests for you.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator("1", "Upload"),
              _buildStepIndicator("2", "Review"),
              _buildStepIndicator("3", "Book"),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () async {
              // ক্যামেরা পারমিশন চেক
              PermissionStatus status = await Permission.camera.request();

              if (status.isPermanentlyDenied) {
                openAppSettings();
                return;
              }

              if (status.isGranted) {
                if (!context.mounted) return;

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF08B1AC),
                            ),
                            title: const Text('Take a Photo'),
                            onTap: () async {
                              Navigator.pop(context);
                              final ImagePicker picker = ImagePicker();
                              final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (photo != null)
                                debugPrint("Camera Path: ${photo.path}");
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.photo_library,
                              color: Color(0xFF08B1AC),
                            ),
                            title: const Text('Choose from Gallery'),
                            onTap: () async {
                              Navigator.pop(context);

                              // ১. গ্যালারি পারমিশন রিকোয়েস্ট (অ্যান্ড্রয়েড ১৩+ এর জন্য জরুরি)
                              final PermissionState ps =
                                  await PhotoManager.requestPermissionExtend();

                              if (ps.isAuth || ps.hasAccess) {
                                // ২. পারমিশন থাকলে পিকার ওপেন হবে
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
                                  debugPrint(
                                    "Selected Gallery Path: ${file?.path}",
                                  );
                                }
                              } else {
                                // ৩. পারমিশন ডিনাইড হলে
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Gallery access denied."),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Camera access is required.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF08B1AC),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload_outlined),
                SizedBox(width: 12),
                Text(
                  "Upload Prescription",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
        radius: Radius.circular(12),
      ),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.description_outlined,
          color: Color.fromARGB(255, 4, 135, 126),
          size: 33,
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String number, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFF007A3D).withValues(alpha: 0.1),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF007A3D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F2A44),
          ),
        ),
      ],
    );
  }
}
