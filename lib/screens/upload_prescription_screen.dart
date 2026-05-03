import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../utils/index.dart';

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
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
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
        setState(() {
          _selectedImage = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to capture image: $e');
    }
  }

  /// Upload prescription and create order
  Future<void> _uploadPrescription() async {
    setState(() => _errorMessage = null);

    // Validation
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Please select a prescription image');
      return;
    }

    String testListText = _testListController.text.trim();
    String priceText = _priceController.text.trim();

    if (testListText.isEmpty || priceText.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    double? price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      setState(() => _errorMessage = 'Please enter a valid price');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String userId = _authService.getUserId() ?? '';

      // Upload image to Firebase Storage
      String imageUrl = await _storageService.uploadPrescription(
        _selectedImage!,
        userId,
      );

      // Parse test list
      List<String> testList = testListText
          .split(',')
          .map((e) => e.trim())
          .toList();

      // Create order
      Order newOrder = Order(
        orderId: AppHelpers.generateOrderId(),
        userId: userId,
        prescriptionImageUrl: imageUrl,
        status: 'uploaded',
        testList: testList,
        price: price,
        createdAt: DateTime.now(),
      );

      // Save order to Firestore
      await _firestoreService.createOrder(newOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationKeys.success.tr()),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate back to home
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to upload: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(LocalizationKeys.uploadPrescription.tr())),
      body: SingleChildScrollView(
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
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
                          LocalizationKeys.prescription.tr(),
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
                    label: Text(LocalizationKeys.uploadFromGallery.tr()),
                  ),
                  const SizedBox(height: AppTheme.paddingMedium),
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(LocalizationKeys.uploadFromCamera.tr()),
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
                    label: const Text('Change Image'),
                  ),
                ],
              ),

            const SizedBox(height: AppTheme.paddingXLarge),

            // Test List Input
            TextField(
              controller: _testListController,
              decoration: InputDecoration(
                labelText: LocalizationKeys.testList.tr(),
                hintText: 'Blood Test, X-Ray, CT Scan',
                prefixIcon: const Icon(Icons.list),
              ),
              maxLines: 3,
              enabled: !_isUploading,
            ),
            const SizedBox(height: AppTheme.paddingMedium),

            // Price Input
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: LocalizationKeys.price.tr(),
                hintText: '5000',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isUploading,
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
                  : Text(LocalizationKeys.confirm.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
