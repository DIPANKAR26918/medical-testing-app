class AppStrings {
  const AppStrings._();

  static const String appTitle = 'TESTIFIED';
  static const String next = 'Next';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String logout = 'Logout';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String login = 'Login';
  static const String phone = 'Phone number';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String signUp = 'Sign up';
  static const String or = 'or';
  static const String fullName = 'Full name';
  static const String fullNameHint = 'Enter your full name';
  static const String pleaseFillAllFields = 'Please fill all fields';
  static const String pleaseEnterYourName = 'Please enter your name';
  static const String pleaseEnterPhoneNumber = 'Please enter phone number';
  static const String networkRequestFailed =
      'Network error. Please check your connection.';
  static const String pleaseSelectPrescriptionImage =
      'Please select prescription image';
  static const String pleaseEnterValidPrice = 'Please enter a valid price';
  static const String failedToPickImage = 'Failed to pick image';
  static const String failedToCaptureImage = 'Failed to capture image';
  static const String failedToUpload = 'Failed to upload';
  static const String alreadyHaveAnAccount = 'Already have an account?';
  static const String dontHaveAnAccount = "Don't have an account?";
  static const String created = 'Created';
  static const String noTestsAssigned = 'No tests assigned';
  static const String changeImage = 'Change image';
  static const String testListHint = 'Blood tests, X-ray, CT scan';
  static const String logoutPrompt = 'Are you sure you want to logout?';
  static const String home = 'Home';
  static const String uploadPrescription = 'Upload prescription';
  static const String noOrders =
      'No orders yet. Upload your first prescription!';
  static const String orderId = 'Order ID';
  static const String orderDetails = 'Order details';
  static const String status = 'Status';
  static const String testList = 'Test list';
  static const String price = 'Price';
  static const String agentName = 'Agent name';
  static const String notAssigned = 'Not assigned';
  static const String uploaded = 'Uploaded';
  static const String confirmed = 'Confirmed';
  static const String assigned = 'Assigned';
  static const String collected = 'Collected';
  static const String testing = 'Testing';
  static const String completed = 'Completed';
  static const String uploadFromGallery = 'Upload from gallery';
  static const String uploadFromCamera = 'Upload from camera';
  static const String uploading = 'Uploading...';
  static const String prescription = 'Prescription';
  static const String userId = 'User ID';

  static String statusLabel(String value) {
    switch (value.toLowerCase()) {
      case 'uploaded':
        return uploaded;
      case 'confirmed':
        return confirmed;
      case 'assigned':
        return assigned;
      case 'collected':
        return collected;
      case 'testing':
        return testing;
      case 'completed':
        return completed;
      default:
        return value;
    }
  }
}
