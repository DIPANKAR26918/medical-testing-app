import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class PrescriptionUploadCard extends StatelessWidget {
  const PrescriptionUploadCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF0F9F4), // Subtle green tint for prominence
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFD1E7DD), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrescriptionIcon(),
              SizedBox(width: 16),
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
                    SizedBox(height: 4),
                    Text(
                      "Upload your prescription and our medical experts will review and suggest the right tests for you.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[690],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Steps / Trust Badges Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator("1", "Upload"),
              _buildStepIndicator("2", "Review"),
              _buildStepIndicator("3", "Book"),
            ],
          ),

          SizedBox(height: 20),

          // Action Button
          ElevatedButton(
            onPressed: () {
              // Trigger File Picker or Camera
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(
                255,
                106,
                142,
                142,
              ), // Primary Action Green
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 54), // Taller for better UX
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.file_upload_outlined),
                SizedBox(width: 8),
                Text(
                  "Upload Prescription",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        color: const Color(0xFF007A3D),
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
          color: Color.fromARGB(255, 0, 114, 122),
          size: 30,
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
        SizedBox(width: 6),
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
