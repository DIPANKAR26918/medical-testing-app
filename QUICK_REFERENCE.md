# Quick Reference Guide

## 📋 File Structure at a Glance

```
Testified/
├── lib/
│   ├── main.dart ⭐                    # App entry point
│   ├── firebase_options.dart           # Firebase config (UPDATE THIS)
│   ├── screens/                        # 5 UI screens
│   │   ├── language_selection_screen.dart
│   │   ├── authentication_screen.dart
│   │   ├── home_screen.dart
│   │   ├── upload_prescription_screen.dart
│   │   └── order_details_screen.dart
│   ├── widgets/                        # Reusable components
│   │   ├── common_widgets.dart
│   │   ├── status_badge.dart
│   │   └── order_card.dart
│   ├── services/                       # Firebase integration
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   └── storage_service.dart
│   ├── models/                         # Data models
│   │   ├── order.dart
│   │   └── app_user.dart
│   └── utils/                          # Helpers
│       ├── app_theme.dart
│       ├── localization_keys.dart
│       └── validators_helpers.dart
├── assets/
│   └── translations/
│       ├── en.json                     # English translations
│       └── bn.json                     # Bangla translations
├── android/app/
│   └── google-services.json            # ADD THIS (from Firebase)
├── ios/Runner/
│   └── GoogleService-Info.plist        # ADD THIS (from Firebase)
├── pubspec.yaml ⭐                     # Dependencies (already updated)
├── README.md                           # Quick start
├── SETUP_GUIDE.md                      # Firebase setup (READ THIS)
├── ARCHITECTURE.md                     # Technical details
└── IMPLEMENTATION_SUMMARY.md           # Project overview
```

## 🚀 Quick Start (5 Steps)

### 1. Get Dependencies
```bash
cd Testified
flutter pub get
```

### 2. Setup Firebase
- Go to Firebase Console
- Create project
- Add Android/iOS/Web apps
- Download config files (google-services.json, GoogleService-Info.plist)
- Place in correct directories

### 3. Update Credentials
Edit `lib/firebase_options.dart` with your Firebase credentials

### 4. Run App
```bash
flutter run
```

### 5. Test
- Select language
- Sign up with email
- Upload prescription
- View order details

## 📱 Screen Navigation Flow

```
LanguageSelectionScreen
        ↓
AuthenticationScreen
        ↓
HomeScreen ← ← ← ← ← ← ← ← ↓
  ├→ UploadPrescriptionScreen ↓
  └→ OrderDetailsScreen ← ← ←
```

## 🔧 Services Quick Reference

### AuthService
```dart
signUpWithEmail(email, password, name)
signInWithEmail(email, password)
signUpWithPhone(phoneNumber)
signInAnonymously()
signOut()
getCurrentUser()
getUserId()
isLoggedIn()
```

### FirestoreService
```dart
createOrder(order)
getOrder(orderId)
getUserOrders(userId)  // Real-time stream
updateOrderStatus(orderId, newStatus)
assignAgent(orderId, agentId)
updateTestList(orderId, testList)
deleteOrder(orderId)
```

### StorageService
```dart
uploadPrescription(imageFile, userId)
deleteImage(imageUrl)
getDownloadUrl(filePath)
```

## 🎨 Customization Hotspots

### Change Colors
`lib/utils/app_theme.dart` → AppTheme class constants

### Add Language
Add JSON file in `assets/translations/[locale].json`

### Change Currency
`lib/utils/validators_helpers.dart` → AppHelpers.formatCurrency()

### Change Theme
`main.dart` → ThemeMode property

## 🔄 Status Lifecycle

```
User uploads prescription
          ↓
    Status: "uploaded" (with imageUrl)
          ↓
  Agent views in Agent App
          ↓
Agent clicks "Confirm" → Status: "confirmed"
Agent assigns self → Status: "assigned", agentId: "agent123"
Agent collects sample → Status: "collected"
Agent runs tests → Status: "testing"
Agent uploads results → Status: "completed"
```

## 📊 Firestore Collections

### orders/
- Required: userId, prescriptionImageUrl, status, testList, price, createdAt
- Optional: agentId (null until assigned)

### users/
- Required: email/phoneNumber, createdAt
- Optional: displayName

## 🔐 Firebase Setup Checklist

```
AUTHENTICATION
☐ Enable Email/Password
☐ Enable Anonymous

DATABASE
☐ Create Firestore database (Test Mode)
☐ Create orders collection
☐ Create users collection
☐ Set Firestore rules

STORAGE
☐ Create Storage bucket (Test Mode)
☐ Set Storage rules

CONFIGURATION
☐ Update firebase_options.dart
☐ Add google-services.json (Android)
☐ Add GoogleService-Info.plist (iOS)
```

## ⚙️ Key Dependencies

```dart
firebase_core: ^3.0.0          // Firebase initialization
firebase_auth: ^5.0.0          // Authentication
cloud_firestore: ^5.0.0        // Database
firebase_storage: ^12.0.0      // File storage
easy_localization: ^3.0.0      // Translations
image_picker: ^1.0.0           // Camera/Gallery
provider: ^6.0.0               // State management
```

## 🐛 Debug Commands

```bash
# Check Flutter setup
flutter doctor

# Get dependencies
flutter pub get

# Run with logs
flutter run -v

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## 💾 Database Rules (Firestore)

```
users/{userId}        → User can read/write their own
orders/{orderId}      → User can read/write if userId matches
```

## 🎯 Agent App Integration Points

The architecture supports Agent App by:
1. Sharing Firestore database
2. Sharing Authentication
3. Sharing Storage
4. Orders accessible via agentId
5. Real-time status updates

## 📞 Files to Review

| File | Purpose |
|------|---------|
| main.dart | App initialization and routing |
| firebase_options.dart | Firebase credentials ⭐ UPDATE |
| auth_service.dart | Authentication logic |
| firestore_service.dart | Database operations |
| storage_service.dart | Image upload logic |
| app_theme.dart | Colors and styling |
| localization_keys.dart | i18n constants |

## ✅ Before Running

```
☐ Flutter installed
☐ Firebase project created
☐ Firebase credentials obtained
☐ google-services.json placed
☐ GoogleService-Info.plist placed
☐ firebase_options.dart updated
☐ Dependencies installed (flutter pub get)
☐ Android SDK configured (for Android)
☐ Xcode configured (for iOS)
```

## 🚨 Common Errors & Fixes

| Error | Solution |
|-------|----------|
| Firebase not initialized | Check firebase_options.dart |
| Permission denied | Check Firestore rules |
| Image upload failed | Check Storage rules |
| Language not working | Restart app |
| Build fails | Run `flutter pub get` |

## 🎓 Learning Path

1. Read IMPLEMENTATION_SUMMARY.md
2. Follow SETUP_GUIDE.md
3. Review ARCHITECTURE.md
4. Check code comments in lib/
5. Test all screens manually
6. Deploy to Firebase

## 📈 Next Phases

**Phase 2**: Build Agent App (same backend)
**Phase 3**: Add Web Dashboard
**Phase 4**: Add Analytics
**Phase 5**: Production Deployment

## 📚 Documentation Map

- **README.md** → Quick overview
- **SETUP_GUIDE.md** → Firebase setup
- **ARCHITECTURE.md** → Technical design
- **IMPLEMENTATION_SUMMARY.md** → Complete guide
- **This file** → Quick reference
- **Code comments** → Implementation details

---

**Ready? Start with Step 1 of Quick Start! 🚀**
