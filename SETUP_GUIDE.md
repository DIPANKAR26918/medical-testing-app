# Firebase Setup Guide

This guide will help you configure Firebase for the Medical Diagnostic App.

## Prerequisites

- Firebase project created
- Flutter CLI installed
- Android Studio / Xcode (for mobile development)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create Project"
3. Follow the setup wizard
4. Enable Google Analytics (optional)

## Step 2: Configure Platforms

### For Android:

1. In Firebase Console, go to Project Settings
2. Click "Add App" → Select Android
3. Enter package name: `com.medicaldiagnostic.app`
4. Download `google-services.json`
5. Place in `android/app/` directory
6. Register SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
7. Copy SHA-1 hash and add to Firebase Console

### For iOS:

1. Click "Add App" → Select iOS
2. Enter Bundle ID: `com.medicaldiagnostic.app`
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag and drop the plist file into Xcode
6. Ensure "Copy items if needed" is checked

### For Web:

1. Click "Add App" → Select Web
2. Copy the configuration
3. Add to your web `index.html` or environment file

## Step 3: Update firebase_options.dart

```bash
# Install Firebase CLI tools
flutter pub global activate flutterfire_cli

# Generate Firebase configuration
flutterfire configure
```

Or manually update the file with your credentials.

## Step 4: Enable Authentication

1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable these providers:
   - Email/Password
   - Anonymous (for demo)

## Step 5: Create Firestore Database

1. Go to Firestore Database
2. Click "Create Database"
3. Start in **Test Mode** (for development)
4. Choose region closest to you

### Security Rules (for testing):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /orders/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## Step 6: Setup Storage

1. Go to Storage
2. Click "Get Started"
3. Start in Test Mode
4. Choose region

### Security Rules:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /prescriptions/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 7: Add Dependencies

All dependencies are already in `pubspec.yaml`. Run:

```bash
flutter pub get
```

## Step 8: Build and Run

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## Database Collections Setup

### Create 'orders' Collection

1. In Firestore, click "Create Collection"
2. Name: `orders`
3. Add sample document with these fields:
   - `userId` (string)
   - `prescriptionImageUrl` (string)
   - `status` (string)
   - `testList` (array)
   - `price` (number)
   - `agentId` (string)
   - `createdAt` (timestamp)

### Create 'users' Collection

1. Click "Create Collection"
2. Name: `users`
3. Fields:
   - `email` (string)
   - `phoneNumber` (string)
   - `displayName` (string)
   - `createdAt` (timestamp)

## Testing the Setup

### 1. Test Authentication

```dart
// In your app, try signing up with:
Email: test@example.com
Password: Test@123456
Name: Test User
```

### 2. Test Upload

- Upload a prescription image
- Check Firebase Storage for the image
- Verify order created in Firestore

### 3. Test Real-time Updates

- Create an order
- Manually update status in Firestore Console
- Check if app reflects changes in real-time

## Troubleshooting

### Issue: Firebase not initializing

**Solution:**
- Ensure `google-services.json` (Android) is in `android/app/`
- Ensure `GoogleService-Info.plist` (iOS) is added to Xcode
- Verify credentials in `firebase_options.dart`

### Issue: Firestore read permission denied

**Solution:**
- Check Firestore Security Rules
- Ensure user is authenticated
- Verify userId matches in Firestore

### Issue: Image upload fails

**Solution:**
- Check Storage Security Rules
- Verify user is authenticated
- Ensure image file is not too large

### Issue: Localization not working

**Solution:**
- Check `pubspec.yaml` asset paths
- Ensure JSON files are in `assets/translations/`
- Restart app after configuration

## Production Setup

Before releasing:

1. **Update Security Rules**: Remove Test Mode
   
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if false;
       }
     }
   }
   ```

2. **Enable Only Needed Auth Methods**

3. **Setup App Signing** for Android/iOS

4. **Enable App Check** for security

5. **Setup Backups** for Firestore

6. **Monitor Usage** and set quotas

## Documentation Links

- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire Guide](https://firebase.flutter.dev)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Storage Guide](https://firebase.google.com/docs/storage)

## Next Steps

- Configure your app preferences in Firebase Console
- Test all features before production
- Setup monitoring and analytics
- Plan for Agent App integration

---

**Successfully configured? Your app is ready to run!**

```bash
flutter run
```
