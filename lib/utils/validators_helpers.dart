/// Utility class for validators
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?1?\d{9,15}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

/// Utility class for helper functions
class AppHelpers {
  /// Format currency
  static String formatCurrency(double amount, {String symbol = '৳'}) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Format date to readable format
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format date time to readable format
  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get status color based on status value
  static String getStatusColor(String status) {
    switch (status) {
      case 'uploaded':
        return '#FFC107'; // Amber
      case 'confirmed':
        return '#2196F3'; // Blue
      case 'assigned':
        return '#9C27B0'; // Purple
      case 'collected':
        return '#FF9800'; // Orange
      case 'testing':
        return '#F44336'; // Red
      case 'completed':
        return '#4CAF50'; // Green
      default:
        return '#757575'; // Gray
    }
  }

  /// Generate unique order ID
  static String generateOrderId() {
    return 'ORD${DateTime.now().millisecondsSinceEpoch}';
  }
}
