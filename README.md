# Medical Diagnostic App - User App

A clean and scalable Flutter mobile app for medical diagnostic services. This MVP allows users to upload prescriptions, track order status, and view test details with real-time updates from Firebase.

## Features

✅ **Welcome Screen** - English-only app text
✅ **Authentication** - Email/Password and Phone number login
✅ **Upload Prescription** - Select from gallery or camera
✅ **Order Management** - Create and track medical test orders
✅ **Real-time Updates** - Firestore integration for live status updates
✅ **Order Details** - View prescription image, test list, price, and agent info
✅ **Pull-to-Refresh** - Refresh orders on demand
✅ **Error Handling** - Comprehensive error handling and validation
✅ **Responsive UI** - Material Design 3 with clean and minimal interface

## Tech Stack

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore, Storage)
- **State Management**: Provider
- **Image Handling**: image_picker

## Project Structure

```
lib/
├── screens/              # All UI screens
│   ├── welcome_screen.dart
│   ├── authentication_screen.dart
│   ├── home_screen.dart
│   ├── upload_prescription_screen.dart
│   └── order_details_screen.dart
├── widgets/             # Reusable UI components
│   ├── common_widgets.dart      # Loading, Error, Empty widgets
│   ├── status_badge.dart        # Status display badge
│   └── order_card.dart          # Order list item
├── services/            # Firebase services
│   ├── auth_service.dart        # Authentication logic
│   ├── firestore_service.dart   # Database operations
│   └── storage_service.dart     # Image upload
├── models/              # Data models
│   ├── order.dart       # Order model
│   └── app_user.dart    # User model
├── utils/               # Utilities and helpers
│   ├── app_theme.dart           # Theme and colors
│   ├── app_strings.dart   # English text constants
│   ├── validators_helpers.dart  # Validation and formatting
│   └── index.dart               # Export file
├── assets/
│   └── images/    # image assets
└── main.dart            # App entry point
```

## Setup Instructions

### Prerequisites

- Flutter 3.x installed
- Firebase project created
- Dart 3.x

### Step 1: Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get
```

### Step 2: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create or select your project
3. Add your app platforms (Android, iOS, Web, etc.)
4. Download the configuration files and follow platform-specific instructions

#### Update firebase_options.dart:
Replace placeholders with your Firebase credentials from Firebase Console

### Step 3: Setup Firestore Database

Create Firestore collections:

```
orders/
├── userId
├── prescriptionImageUrl
├── status
├── testList (array)
├── price
├── agentId (optional)
└── createdAt

users/
├── email
├── phoneNumber
├── displayName
└── createdAt
```

### Step 4: Run the App

```bash
flutter run
```

## Database Structure

### Orders Collection

Status flow: `uploaded → confirmed → assigned → collected → testing → completed`

### Ready for Agent App

✅ Architecture supports agent app integration with shared backend

## Customization

- **Colors**: Edit `lib/utils/app_theme.dart`
- **Text**: Update English strings in `lib/utils/app_strings.dart`
- **Currency**: Update `AppHelpers.formatCurrency()`

## Architecture Highlights

- **Scalable**: Ready for Agent App integration
- **Modular**: Services, models, widgets separated
- **English-only**: Centralized app text
- **Type-safe**: Null safety throughout
- **Reactive**: Real-time Firebase integration

## Support

Configure Firebase credentials and Firestore database structure as per documentation.
