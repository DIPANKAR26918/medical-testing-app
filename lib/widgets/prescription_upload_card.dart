import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class PrescriptionUploadCard extends StatelessWidget {
  const PrescriptionUploadCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(
          255,
          208,
          228,
          255,
        ), // Subtle green tint for prominence
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.09),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),
              SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Prescription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2A44),
                      ),
                    ),
                    SizedBox(height: 8),
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

          SizedBox(height: 12),

          // Steps / Trust Badges Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator("1", "Upload"),
              _buildStepIndicator("2", "Review"),
              _buildStepIndicator("3", "Book"),
            ],
          ),

          SizedBox(height: 14),

          // Action Button
          ElevatedButton(
            onPressed: () async {
              debugPrint(
                "1. Button Clicked!",
              ); // Check if the button even responds

              PermissionStatus status = await Permission.camera.status;
              debugPrint("2. Current Camera Status: $status");

              if (!status.isGranted) {
                debugPrint("3. Requesting Permission...");
                status = await Permission.camera.request();
                debugPrint("4. New Status after request: $status");
              }

              if (status.isGranted) {
                debugPrint("5. Opening Camera...");
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                );
                debugPrint("6. Photo object: $photo");
              } else {
                debugPrint("ERR: Permission denied by user.");
              }
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(
                255,
                8,
                177,
                172,
              ), // Primary Action Green
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 54), // Taller for better UX
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: Row(
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
      options: RoundedRectDottedBorderOptions(
        color: const Color.fromARGB(255, 36, 149, 128),
        strokeWidth: 1.5, // Fixed naming
        dashPattern: const [10, 5],
        radius: const Radius.circular(12),
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
          backgroundColor: Color(0xFF007A3D).withValues(alpha: 0.1),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF007A3D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F2A44),
          ),
        ),
      ],
    );
  }
}
