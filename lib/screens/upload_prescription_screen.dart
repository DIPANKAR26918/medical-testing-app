import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';
import '../widgets/index.dart';

/// Screen for uploading prescription and creating an order
class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;
  final int _currentNavIndex = 1;
  final TextEditingController _testListController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _testListController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final validationError = _validateSelectedFile(File(pickedFile.path));
        if (validationError != null) {
          setState(() => _errorMessage = validationError);
          return;
        }

        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = AppStrings.failedToPickImage);
    }
  }

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final validationError = _validateSelectedFile(File(pickedFile.path));
        if (validationError != null) {
          setState(() => _errorMessage = validationError);
          return;
        }

        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = AppStrings.failedToCaptureImage);
    }
  }

  String? _validateSelectedFile(File file) {
    const maxSizeBytes = 10 * 1024 * 1024; // 10 MB
    final fileSize = file.lengthSync();
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png'];

    if (!allowedExtensions.contains(extension)) {
      return AppStrings.failedToUpload;
    }

    if (fileSize > maxSizeBytes) {
      return AppStrings.failedToUpload;
    }

    return null;
  }

  /// Upload prescription and create order
  Future<void> _uploadPrescription() async {
    setState(() => _errorMessage = null);

    // Validation
    if (_selectedImage == null) {
      setState(() => _errorMessage = AppStrings.pleaseSelectPrescriptionImage);
      return;
    }

    String testListText = _testListController.text.trim();
    String priceText = _priceController.text.trim();

    if (testListText.isEmpty || priceText.isEmpty) {
      setState(() => _errorMessage = AppStrings.pleaseFillAllFields);
      return;
    }

    final userId = _authService.getUserId();
    if (userId == null || userId.isEmpty) {
      setState(() => _errorMessage = AppStrings.networkRequestFailed);
      return;
    }

    final price = double.tryParse(priceText.replaceAll(',', ''));
    if (price == null || price <= 0 || price > 100000) {
      setState(() => _errorMessage = AppStrings.pleaseEnterValidPrice);
      return;
    }

    final testList = testListText
        .split(RegExp(r'[;,\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (testList.isEmpty) {
      setState(() => _errorMessage = AppStrings.pleaseFillAllFields);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload image to Supabase Storage
      String imagePath = await _storageService.uploadPrescription(
        _selectedImage!,
        userId,
      );

      // Create order
      Order newOrder = Order(
        orderId: AppHelpers.generateOrderId(),
        userId: userId,
        prescriptionImagePath: imagePath,
        status: 'uploaded',
        testList: testList,
        price: price,
        timeline: [
          {
            'status': 'uploaded',
            'message': AppStrings.uploading,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ],
        createdAt: DateTime.now(),
      );

      // Save order to Firestore
      await _firestoreService.createOrder(newOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.success),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate back to home
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      debugPrint('Upload failed: $e');
      debugPrint('$stack');
      setState(() => _errorMessage = AppStrings.failedToUpload);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Handle bottom navigation taps
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        // Already on upload screen
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/test-status');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(AppStrings.uploadPrescription)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLarge,
                      ),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  const SizedBox(height: AppTheme.paddingMedium),

                // Image preview or upload buttons
                if (_selectedImage == null)
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.borderColor,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusLarge,
                          ),
                          color: AppTheme.lightGreen.withValues(alpha: 0.05),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: AppTheme.paddingMedium),
                            Text(
                              AppStrings.prescription,
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                fontSize: AppTheme.fontSizeMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingLarge),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: Text(AppStrings.uploadFromGallery),
                      ),
                      const SizedBox(height: AppTheme.paddingMedium),
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(AppStrings.uploadFromCamera),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusLarge,
                        ),
                        child: Image.file(
                          _selectedImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingMedium),
                      TextButton.icon(
                        onPressed: _isUploading ? null : _pickFromGallery,
                        icon: const Icon(Icons.edit),
                        label: Text(AppStrings.changeImage),
                      ),
                    ],
                  ),

                const SizedBox(height: AppTheme.paddingXLarge),

                // Test List Input
                FloatingLabelTextField(
                  controller: _testListController,
                  label: AppStrings.testList,
                  hint: AppStrings.testListHint,
                  prefixIcon: Icons.list,
                  maxLines: 3,
                ),
                const SizedBox(height: AppTheme.paddingMedium),

                // Price Input
                FloatingLabelTextField(
                  controller: _priceController,
                  label: AppStrings.price,
                  hint: '5000',
                  prefixIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.paddingXLarge),

                // Upload button
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadPrescription,
                  child: _isUploading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(AppStrings.confirm),
                ),
              ],
            ),
          ),
          if (_isUploading)
            AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      AppStrings.uploading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSizeMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
