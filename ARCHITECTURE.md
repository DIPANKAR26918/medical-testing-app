# Architecture Documentation

## Overview

This Flutter application is designed with scalability in mind. The architecture is modular and ready for **Agent App integration** using the same backend.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User App & Agent App                     │
├─────────────────┬───────────────────────────────────────────┤
│   UI Layer      │ Screens, Widgets, Navigation              │
├─────────────────┼───────────────────────────────────────────┤
│   Service Layer │ Auth, Firestore, Storage Services         │
├─────────────────┼───────────────────────────────────────────┤
│   Model Layer   │ Order, User Data Models                   │
├─────────────────┼───────────────────────────────────────────┤
│   Firebase      │ Auth, Firestore, Storage                  │
└─────────────────┴───────────────────────────────────────────┘
```

## Layered Architecture

### 1. **Presentation Layer** (`/screens` & `/widgets`)

Handles all UI rendering and user interactions.

**Screens:**
- `WelcomeScreen` - Onboarding
- `AuthenticationScreen` - Login/Signup
- `HomeScreen` - Order listing
- `UploadPrescriptionScreen` - New order
- `OrderDetailsScreen` - Order info

**Widgets:**
- `OrderCard` - Order list item
- `StatusBadge` - Status indicator
- `AppLoadingWidget` - Loading state
- `AppErrorWidget` - Error state
- `AppEmptyWidget` - Empty state

### 2. **Service Layer** (`/services`)

Encapsulates Firebase operations and business logic.

```dart
AuthService          // Auth operations
  ├── signUpWithEmail()
  ├── signInWithEmail()
  ├── signInAnonymously()
  ├── signOut()
  └── getCurrentUser()

FirestoreService     // Database operations
  ├── createOrder()
  ├── getOrder()
  ├── getUserOrders() // Real-time stream
  ├── updateOrderStatus()
  ├── assignAgent()
  └── updateTestList()

StorageService       // File management
  ├── uploadPrescription()
  ├── deleteImage()
  └── getDownloadUrl()
```

### 3. **Model Layer** (`/models`)

Data representations for type safety and serialization.

```dart
Order
  ├── orderId
  ├── userId
  ├── prescriptionImageUrl
  ├── status
  ├── testList
  ├── price
  ├── agentId (nullable for future)
  └── createdAt

AppUser
  ├── userId
  ├── email
  ├── phoneNumber
  ├── displayName
  └── createdAt
```

### 4. **Firebase Layer**

Backend as a Service providing:
- Authentication
- Real-time database (Firestore)
- File storage
- Security rules

## Data Flow

### Uploading a Prescription

```
┌──────────────────────┐
│ UploadPrescriptionUI │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────┐
│ Pick Image from Gallery  │
│ Input Tests & Price      │
└──────────┬───────────────┘
           │
           ▼
┌──────────────────────────────┐
│ StorageService.uploadImage() │──┐
└──────────┬───────────────────┘  │
           │                       │
           ▼                       ▼
    ┌──────────────┐      ┌─────────────┐
    │Firebase File │      │Download URL │
    └──────────────┘      └─────────────┘
           │                       │
           │                       ▼
           │         ┌──────────────────────────┐
           │         │FirestoreService.create() │
           │         └──────────┬───────────────┘
           │                    │
           ▼                    ▼
    ┌───────────────────────────────────┐
    │ Order Document Created in Database│
    │ Status: "uploaded"                │
    │ AgentId: null                     │
    └───────────────────────────────────┘
```

### Real-time Updates

```
Agent App                           User App
┌─────────────────┐                ┌─────────────────┐
│ Update Status   │                │ Stream Listener │
│ "testing"       │                │ getUserOrders() │
└────────┬────────┘                └────────┬────────┘
         │                                  │
         │         ┌─────────────┐          │
         └────────►│  Firestore  │◄─────────┘
                   │  Database   │
                   └─────────────┘
                         │
            Status: "testing"
                         │
                   All connected
                   clients updated
                   in real-time
```

## Scalability for Agent App

### Shared Backend

Both User App and Agent App use the same Firebase backend:

```
┌─────────────────────────────────────┐
│         Firebase Backend            │
├─────────────────────────────────────┤
│ Authentication (Users & Agents)     │
│ Firestore (Orders, Users, Agents)   │
│ Storage (Prescriptions)             │
└─────────────────────────────────────┘
     ▲              ▲              ▲
     │              │              │
┌────┴────┐    ┌────┴────┐    ┌────┴────┐
│ User    │    │  Web    │    │ Agent   │
│ App     │    │Dashboard│    │ App     │
└─────────┘    └─────────┘    └─────────┘
```

### Agent App Integration Points

#### 1. **Existing Orders Collection**
- Agent can query orders with `status != "uploaded"`
- Monitor newly assigned orders
- Update status in real-time

#### 2. **User Assignment**
```dart
// FirestoreService.assignAgent(orderId, agentId)
// Updates: agentId field + status to "assigned"
```

#### 3. **Real-time Status Updates**
```dart
// Agent updates status
await firestore.collection('orders')
  .doc(orderId)
  .update({'status': 'testing'});

// User receives update via stream
getUserOrders() // Real-time
```

#### 4. **Agent Tracking**
```dart
// New collection can be added
agents/
  ├── agentId
  ├── name
  ├── email
  ├── assignedOrders (reference array)
  └── completedOrders
```

## Service Dependencies

```
User App/Agent App
    │
    ├── AuthService
    │   └── Firebase Authentication
    │
    ├── FirestoreService
    │   └── Firestore Database
    │
    └── StorageService
        └── Firebase Storage
```

## State Management

The app uses a simple approach:
- **StatefulWidget** for local state
- **StreamBuilder** for real-time data from Firestore
- **Provider** can be added for complex state

### Adding Provider (Optional)

```dart
// Example for shared state
final orderProvider = StreamProvider<List<Order>>((ref) async* {
  // Share across app
});
```

## Folder Structure Benefits

1. **Separation of Concerns**: Each layer has specific responsibility
2. **Testability**: Services can be mocked easily
3. **Reusability**: Widgets and services used in multiple screens
4. **Scalability**: Easy to add Agent App with same services
5. **Maintainability**: Clear organization and naming

## Extension Points for Agent App

### 1. New Screens
```
agent_screens/
├── agent_login_screen.dart
├── agent_home_screen.dart
├── order_assignment_screen.dart
└── order_completion_screen.dart
```

### 2. Additional Services
```
services/
├── agent_service.dart      # Agent-specific operations
└── assignment_service.dart # Order assignment logic
```

### 3. New Models
```
models/
├── agent.dart              # Agent data model
└── assignment.dart         # Assignment tracking
```

### 4. Firestore Collections
```
agents/        # Agent profiles
assignments/   # Assignment history
activities/    # Activity logs
```

## Best Practices Implemented

✅ **Type Safety**: Models with null safety
✅ **Error Handling**: Try-catch with user feedback
✅ **Real-time**: Firestore streams for live updates
✅ **English-only text**: Centralized app strings
✅ **Theme**: Centralized theming
✅ **Validation**: Input validation on all forms
✅ **Loading States**: UI feedback for async operations
✅ **Error States**: Graceful error handling
✅ **Empty States**: Helpful messages when no data

## Performance Optimization

1. **Image Compression**: 80% quality for uploads
2. **Indexed Queries**: Firestore queries optimized
3. **Stream Filtering**: Where clauses reduce data
4. **Lazy Loading**: Orders loaded on demand
5. **Efficient Re-rendering**: Only rebuild when needed

## Security Considerations

1. **Firestore Rules**: User-scoped access
2. **Storage Rules**: User-owned file access
3. **Auth Check**: User verified before operations
4. **Data Validation**: Server-side validation ready
5. **No Hardcoded Secrets**: Config externalized

## Testing Strategy

```
Unit Tests
├── Model serialization
├── Service methods (with mocks)
└── Utility functions

Widget Tests
├── Screen rendering
├── User interactions
└── Error states

Integration Tests
├── Full user flow
├── Firebase integration
└── Real-time updates
```

## Migration Path

From User App to Full Platform:

1. **Phase 1**: User App (Current) ✅
2. **Phase 2**: Agent App (Shared backend)
3. **Phase 3**: Web Dashboard (Same services)
4. **Phase 4**: Analytics & Reporting
5. **Phase 5**: Mobile Agent App for iOS

## Conclusion

This architecture provides:
- ✅ Clean separation of concerns
- ✅ Easy to extend for Agent App
- ✅ Scalable to multiple platforms
- ✅ Type-safe and maintainable
- ✅ Production-ready best practices

The foundation is solid for building a complete medical diagnostic platform.
