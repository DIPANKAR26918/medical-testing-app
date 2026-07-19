# Push notifications

Testified uses Firebase Cloud Messaging (FCM) for delivery and Supabase for
authenticated device registration, authorization and durable notification
history.

## What is already wired

- Android Firebase app configuration (`android/app/google-services.json`)
- Android 13+ permission request, high-priority notification channel and icon
- Foreground, background and terminated-state message handling
- FCM token registration, refresh and logout deactivation
- Notification tap routing with an allowlist of app routes
- Realtime in-app inbox, unread badge and mark-as-read controls
- `push_devices` and `notifications` tables protected by row-level security
- `register-push-device` and `send-push` Supabase Edge Functions
- Automatic order-status notifications from `FirestoreService`

## Privacy boundary

FCM is used only as a generic wake-up signal. Lock-screen pushes say that a
secure update is available and carry only the inbox route plus an opaque
notification ID. Patient, order, test, collection and report details stay in
the row-level-security-protected Supabase inbox and are fetched only after the
user opens the authenticated app.

## Required production secret

Physical remote delivery starts after the Firebase service account is added to
the Supabase project. Never commit this JSON to the repository.

1. Open Firebase Console for project `testified-6d9e6`.
2. Go to **Project settings → Service accounts** and generate a private key.
3. In Supabase Dashboard, open **Edge Functions → Secrets**.
4. Create `FIREBASE_SERVICE_ACCOUNT_JSON` and paste the complete JSON object as
   its value.
5. Confirm that the Firebase Cloud Messaging HTTP v1 API is enabled in the
   linked Google Cloud project.

Until this secret is present, `send-push` deliberately returns HTTP 202 after
saving the inbox notification. This preserves the user-visible update without
pretending that a device push was delivered.

## iOS release setup

The Dart integration and push entitlement are present, but the repository does
not contain the Apple/Firebase credentials needed for physical iOS delivery.

1. Add an iOS app in Firebase with bundle ID
   `com.example.medicalDiagnosticApp`.
2. Download `GoogleService-Info.plist` and add it to the Runner target in Xcode.
3. Keep **Push Notifications** and **Background Modes → Remote notifications**
   enabled for Runner.
4. Upload the Apple APNs authentication key (`.p8`) in Firebase Console under
   **Project settings → Cloud Messaging**.
5. Build with an Apple provisioning profile that contains the APNs entitlement.

The app catches missing Firebase configuration at startup, so an iOS build can
still open while these release credentials are being provisioned; push remains
disabled on that build.

## Sending an update

The caller must have an authenticated `admin` or `agent` profile. Agents may
only notify the patient attached to an order assigned to that agent.

```dart
final session = Supabase.instance.client.auth.currentSession!;

await Supabase.instance.client.functions.invoke(
  'send-push',
  headers: {'Authorization': 'Bearer ${session.accessToken}'},
  body: {
    'user_id': patientId,
    'order_id': orderId,
    'title': 'Your reports are ready',
    'body': 'Open Testified to securely view your completed reports.',
    'kind': 'order_update',
    'data': {
      'route': '/home',
      'tab_index': '2',
      'order_id': '$orderId',
    },
  },
);
```

Allowed tap routes are `/home`, `/notifications`, `/search`,
`/all-categories`, `/upload` and `/test-status`. Unknown routes open the inbox
instead of being executed.

## Device smoke test

1. Install the app on a physical Android device and sign in.
2. Accept the notification permission prompt.
3. Confirm one enabled row exists in `push_devices` for that user.
4. Change an assigned order status from a staff session.
5. Verify the generic secure-update alert appears when the app is foregrounded,
   backgrounded and terminated, without medical or order details on the lock
   screen.
6. Tap the alert and confirm it opens the authenticated notification inbox.
7. Sign out and confirm the device row is disabled.

iOS FCM should be tested on a physical device after the plist, APNs key and
provisioning profile are installed.
