# Supabase Migration Guide

## Overview
Your Flutter app has been successfully migrated from Firebase to Supabase. This guide will help you set up the database schema and storage bucket.

## Prerequisites
- Supabase Project: https://app.supabase.com
- Your project URL: `https://jfimeyukzzorjzlhrtuf.supabase.co`

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

-- Users can update their own orders
CREATE POLICY "Users can update own orders"
  ON public.orders
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Agents can update assigned orders
CREATE POLICY "Agents can update assigned orders"
  ON public.orders
  FOR UPDATE
  USING (auth.uid() = agent_id);
```

---

## Step 2: Create Storage Bucket

1. Go to your Supabase Dashboard → **Storage** (left sidebar)
2. Click **Create a new bucket**
3. Name it: `prescriptions`
4. Set **Public bucket** to **ON** (so users can access prescription images)
5. Click **Create**

### Configure Storage Policies

Go to **Policies** for the `prescriptions` bucket and add:

```sql
-- Anyone can upload to their own folder
CREATE POLICY "Users can upload prescriptions"
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'prescriptions' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Anyone can read public files
CREATE POLICY "Anyone can read prescriptions"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'prescriptions');

-- Users can delete their own files
CREATE POLICY "Users can delete own prescriptions"
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'prescriptions'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

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

### Test 3: Storage
```dart
final storageService = StorageService();
import 'dart:io';

// Upload a file
final file = File('/path/to/prescription.jpg');
final url = await storageService.uploadPrescription(file, 'user-uuid');
print('Uploaded to: $url');
```

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
- Check the bucket is public
- Verify the folder path format: `userId/filename`

### Issue: Real-time updates not working
- Enable Replication in **Database** → **Replication** settings
- Check the table is checked for replication

---

## Next Steps

1. ✅ Install dependencies (`flutter pub get`)
2. ✅ Create database tables (SQL above)
3. ✅ Create storage bucket (`prescriptions`)
4. ✅ Test authentication
5. ✅ Test database operations
6. ✅ Test file uploads
7. Update your UI screens to handle any differences in the API
8. Test the entire app flow end-to-end
9. Deploy to production

---

## Additional Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [PostgreSQL Basics](https://www.postgresql.org/docs/current/)
- [Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)

---

## Support

If you encounter any issues:

1. Check the [Supabase Status Page](https://status.supabase.com)
2. Review Supabase documentation
3. Check project logs in the Supabase Dashboard
4. Test using the **Query Editor** in Supabase Dashboard

---

**Migration completed!** Your app is now ready to use Supabase. 🎉
