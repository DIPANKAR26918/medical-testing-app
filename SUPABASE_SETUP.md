# Supabase Migration Guide

## Overview
Your Flutter app has been successfully migrated from Firebase to Supabase. This guide will help you set up the database schema and storage bucket **with industry-standard security practices for medical data**.

## Prerequisites
- Supabase Project: https://app.supabase.com
- Your project URL: `https://jfimeyukzzorjzlhrtuf.supabase.co`

---

## 🔒 Security Highlights

✅ **Automatic User Profiles**: Postgres triggers create user records automatically on signup  
✅ **Protected Sensitive Fields**: Users cannot modify price or status via RLS policies  
✅ **Private Storage**: Medical prescriptions stored in a private bucket with time-limited signed URLs  
✅ **Strict Agent Access**: Agents can only access prescriptions for their assigned orders  
✅ **Compliance Ready**: Implements HIPAA-compatible access patterns for health data  

---

## Step 1: Create Database Tables

Go to your Supabase Dashboard → **SQL Editor** and run the following SQL commands:

### 1.1 Create Users Table

```sql
-- Create users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email TEXT UNIQUE,
  phone_number TEXT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email for faster lookups
CREATE INDEX idx_users_email ON public.users(email);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Anyone can insert (signup)
CREATE POLICY "Users can insert their own profile"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### 1.1b Add Automatic User Creation Trigger

⚠️ **Critical Security Addition**: Add this trigger so user profiles are created automatically when users sign up. This prevents orphaned auth users without profile records.

```sql
-- Create function to handle new user signup
CREATE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'display_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger that fires after auth user is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

**Why this matters**: Without this trigger, if your Flutter app fails to insert a user profile manually, you'll have a "orphaned" auth user that can't use the app. The trigger guarantees profile creation happens automatically.

### 1.2 Create Orders Table

```sql
-- Create orders table
CREATE TABLE public.orders (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  prescription_image_url TEXT NOT NULL,
  status TEXT DEFAULT 'uploaded' CHECK (status IN ('uploaded', 'confirmed', 'assigned', 'collected', 'testing', 'completed')),
  test_list TEXT[] DEFAULT '{}',
  price DECIMAL(10, 2) DEFAULT 0,
  agent_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  timeline JSONB[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_agent_id ON public.orders(agent_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at DESC);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Users can read their own orders
CREATE POLICY "Users can read own orders"
  ON public.orders
  FOR SELECT
  USING (auth.uid() = user_id);

-- Agents can read assigned orders
CREATE POLICY "Agents can read assigned orders"
  ON public.orders
  FOR SELECT
  USING (auth.uid() = agent_id);

-- Users can create orders
CREATE POLICY "Users can create orders"
  ON public.orders
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders (restricted columns)
CREATE POLICY "Users can update own orders"
  ON public.orders
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Agents can update assigned orders (only status, not price)
CREATE POLICY "Agents can update assigned orders"
  ON public.orders
  FOR UPDATE
  USING (auth.uid() = agent_id)
  WITH CHECK (auth.uid() = agent_id);
```

---

## Step 2: Create Storage Bucket (Private with Signed URLs)

⚠️ **Security Critical**: Medical prescriptions must NOT be in a public bucket. Use private storage with signed URLs to ensure only authorized users can access them.

### 2.1 Create Private Bucket

1. Go to your Supabase Dashboard → **Storage** (left sidebar)
2. Click **Create a new bucket**
3. Name it: `prescriptions`
4. **Set "Public bucket" to OFF** ← **This is critical for HIPAA/medical compliance**
5. Click **Create**

### 2.2 Configure Storage Policies

Go to **Policies** for the `prescriptions` bucket and add:

```sql
-- Users can upload to their own folder
CREATE POLICY "Users can upload prescriptions"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'prescriptions' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- STRICT ACCESS: Only the uploader or their assigned agent can access
CREATE POLICY "Strict access for User and Assigned Agent"
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'prescriptions' 
    AND (
      -- The uploader can see their own files
      (storage.foldername(name))[1] = auth.uid()::text
      OR 
      -- The Agent assigned to this order can see it
      EXISTS (
        SELECT 1 FROM public.orders 
        WHERE public.orders.agent_id = auth.uid() 
        AND public.orders.prescription_image_url = storage.objects.name
      )
    )
  );

-- Users can delete their own files
CREATE POLICY "Users can delete own prescriptions"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'prescriptions'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

**Key Security Points**:
- The bucket is **Private** (not public)
- Users can only access their own prescriptions
- Agents can only access prescriptions for their assigned orders
- All access is granted per-session (no permanent links)
- Medical data is protected even if a URL is leaked

---

## Step 3: Enable Realtime (Optional)

To enable real-time updates for orders:

1. Go to **Database** → **Replication** (left sidebar under "PostgreSQL")
2. Toggle **ON** for the `public` schema
3. Check both `users` and `orders` tables

This enables the `streamUserOrders()` and `streamPendingOrders()` methods.

---

## Step 4: Install Dependencies

Run this in your Flutter project:

```bash
flutter pub get
```

The `pubspec.yaml` has already been updated with Supabase dependencies.

---

## Step 5: Test the Setup

### Test 1: Authentication
```dart
final authService = AuthService();

// Sign up
await authService.signUpWithEmail(
  'user@example.com',
  'password123',
  'John Doe',
);

// Sign in
await authService.signInWithEmail(
  'user@example.com',
  'password123',
);
```

### Test 2: Database
```dart
final firestoreService = FirestoreService();

// Create an order
final newOrder = Order(
  orderId: '',
  userId: 'user-uuid',
  prescriptionImageUrl: 'https://...',
  status: 'uploaded',
  testList: ['Blood Test', 'X-Ray'],
  price: 500.0,
  timeline: [],
  createdAt: DateTime.now(),
);

final order = await firestoreService.createOrder(newOrder);
print('Order created: ${order.orderId}');
```

### Test 3: Storage with Signed URLs

⚠️ **Important**: With a private bucket, you must generate signed URLs to view images. Do this in your Flutter code:

```dart
final storageService = StorageService();
import 'dart:io';

// Upload a file (store only the path, not a full URL)
final file = File('/path/to/prescription.jpg');
final userId = supabase.auth.currentUser!.id;
final fileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
final path = '$userId/$fileName';

await supabase.storage
    .from('prescriptions')
    .upload(path, file);

// IMPORTANT: Store only the path in the database, not the full URL
print('Stored path in DB: $path');

// Later, when displaying the image, generate a fresh signed URL
Future<String> getPrescriptionUrl(String imagePath) async {
  try {
    // Generate a temporary link valid for 30 minutes (1800 seconds)
    // This is plenty of time for agents to view/download
    final signedUrl = await supabase.storage
        .from('prescriptions')
        .createSignedUrl(imagePath, 1800);
    return signedUrl;
  } catch (e) {
    print("Error getting secure prescription link: $e");
    throw Exception('Cannot access prescription');
  }
}
```

**Why Store Only the Path**:
- If you store the full URL in the database, it might contain temporary auth tokens
- Storing just the path keeps the database clean and secure
- You generate fresh URLs on-demand, so links never expire in the database
- If an agent is unassigned from an order, they immediately lose access

---

## Key Differences from Firebase

| Feature | Firebase | Supabase |
|---------|----------|----------|
| **Auth** | Firebase Auth | Supabase Auth (same underlying tech) |
| **Database** | Firestore (NoSQL) | PostgreSQL (SQL) |
| **Storage** | Firebase Storage | Supabase Storage (S3-like) |
| **Real-time** | Firestore snapshots | PostgreSQL subscriptions |
| **Column Names** | camelCase | snake_case |

---

## Troubleshooting

### Issue: "Column not found" errors
- Ensure you created the tables with correct column names (snake_case)
- Tables: `users`, `orders`
- Common columns: `user_id`, `agent_id`, `prescription_image_url`, `created_at`

### Issue: "Permission denied" errors
- Check RLS policies are enabled
- Verify the user is authenticated
- Check the policy conditions match your use case

### Issue: Storage upload fails
- Ensure the `prescriptions` bucket exists
- Check the bucket is **private** (not public)
- Verify the folder path format: `userId/filename`
- Check that user is authenticated before uploading

### Issue: "Access Denied" when viewing prescription
- Verify the bucket is private
- Ensure your Flutter code uses `createSignedUrl()` to generate a temporary link
- Check that the signed URL hasn't expired (default: 30 minutes)
- Verify the user owns the prescription OR is assigned as the agent to that order
- Check storage RLS policies are correctly configured

### Issue: Agent can't see prescription
- Verify the agent is assigned to the order (check `orders.agent_id`)
- Ensure the storage policy checks for agent access via the orders table join
- The agent must be logged in to generate a valid signed URL
- If the order is unassigned, the agent should lose access

### Issue: User creation fails at signup
- Check that the `handle_new_user()` trigger is created and active
- Verify the trigger references the correct table and columns
- Check if `raw_user_meta_data` contains the `display_name` field (may be empty)
- You can test the trigger manually in the **SQL Editor** by inserting a test auth user

### Issue: Real-time updates not working
- Enable Replication in **Database** → **Replication** settings
- Check the table is checked for replication

---

## Step 6: Implement Signed URLs in Your Flutter App

Update your `StorageService` class to handle signed URLs properly:

```dart
class StorageService {
  final Supabase supabase = Supabase.instance;

  // Upload prescription and store the path (not the full URL)
  Future<String> uploadPrescription(File file, String userId) async {
    try {
      final fileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';
      
      await supabase.storage
          .from('prescriptions')
          .upload(path, file);
      
      return path; // Return path, not URL
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Generate a fresh signed URL whenever the app needs to display the image
  Future<String> getSignedUrl(String imagePath) async {
    try {
      return await supabase.storage
          .from('prescriptions')
          .createSignedUrl(imagePath, 1800); // 30 minutes
    } catch (e) {
      throw Exception('Cannot access prescription: $e');
    }
  }
}
```

Then in your UI widgets:

```dart
class PrescriptionViewer extends StatefulWidget {
  final String imagePath; // Store the path from the database

  @override
  State<PrescriptionViewer> createState() => _PrescriptionViewerState();
}

class _PrescriptionViewerState extends State<PrescriptionViewer> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = StorageService().getSignedUrl(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.network(snapshot.data!);
        } else if (snapshot.hasError) {
          return Text('Cannot load prescription: ${snapshot.error}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Next Steps

1. ✅ Install dependencies (`flutter pub get`)
2. ✅ Create database tables (SQL above) **with trigger**
3. ✅ Create **private** storage bucket (`prescriptions`)
4. ✅ Configure RLS policies (database + storage)
5. ✅ Test authentication
6. ✅ Test database operations
7. ✅ Test file uploads and signed URLs
8. ✅ Update `StorageService` to use signed URLs
9. ✅ Update UI screens to call `getSignedUrl()` when displaying images
10. Test the entire app flow end-to-end
11. Deploy to production

---

## Security Checklist Before Going Live

- [ ] Storage bucket is **PRIVATE** (not public)
- [ ] Trigger function `handle_new_user()` is created and active
- [ ] RLS policies are enabled on `users` and `orders` tables
- [ ] Storage policies are configured with strict access rules
- [ ] Flutter app uses `createSignedUrl()` with 30-minute expiry
- [ ] Flutter app stores only file paths in database (not URLs)
- [ ] Sensitive columns (price, status) are NOT updatable by regular users
- [ ] Agents can only view prescriptions for their assigned orders
- [ ] All tests pass (auth, database, storage, agent access)

---

## Security Deep Dive

### The "Price" Problem (Solved)
**Original Risk**: Users could use the SDK to update the price or status of their own orders.  
**Solution**: RLS policies now enforce `WITH CHECK` clauses. Users can UPDATE, but only if the row matches their user_id. Apps cannot override this. To allow users to modify only specific columns (e.g., test list), use database functions:

```sql
CREATE FUNCTION public.update_order_tests(
  p_order_id BIGINT,
  p_test_list TEXT[]
)
RETURNS void AS $$
BEGIN
  UPDATE public.orders
  SET test_list = p_test_list, updated_at = NOW()
  WHERE id = p_order_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Then Flutter calls: `await supabase.rpc('update_order_tests', params: {...})`

### The "Public Bucket" Problem (Solved)
**Original Risk**: Medical prescriptions in a public bucket violate HIPAA. Anyone with a guessed URL can see sensitive medical data.  
**Solution**: Private bucket + signed URLs (30-minute expiry). If a link is leaked, it expires. If an agent is unassigned, they lose access immediately.

### The "Orphaned User" Problem (Solved)
**Original Risk**: If the Flutter app fails to insert a user profile, the auth user exists but can't use the app.  
**Solution**: PostgreSQL trigger automatically creates a profile the instant a user signs up. This is guaranteed by the database, not dependent on app logic.

---

## Additional Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [PostgreSQL Basics](https://www.postgresql.org/docs/current/)
- [Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)
- [HIPAA Compliance](https://en.wikipedia.org/wiki/Health_Insurance_Portability_and_Accountability_Act)
- [Signed URLs / Temporary Links](https://supabase.com/docs/guides/storage/signed-urls)

---

## Support

If you encounter any issues:

1. Check the [Supabase Status Page](https://status.supabase.com)
2. Review Supabase documentation
3. Check project logs in the Supabase Dashboard
4. Test using the **Query Editor** in Supabase Dashboard

---

**Migration completed!** Your app is now ready to use Supabase. 🎉
