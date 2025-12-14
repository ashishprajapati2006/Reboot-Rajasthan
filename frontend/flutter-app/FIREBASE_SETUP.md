# Firebase Integration Setup Guide

## ✅ Completed Steps

1. **Firebase Core Integration**
   - ✅ Added Firebase packages to `pubspec.yaml`
   - ✅ Created `firebase_options.dart` with configuration placeholders
   - ✅ Updated `main.dart` to initialize Firebase on startup
   - ✅ Added `.env` file for environment configuration
   - ✅ All dependencies installed via `flutter pub get`

## 🔧 Next Steps: Complete Firebase Configuration

### Step 1: Get Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **Reboot-Rajasthan** project
3. Click **Project Settings** (gear icon)
4. Go to **Your Apps** section

### Step 2: Configure Each Platform

#### **For Web Platform:**
1. Click on your Web app
2. Copy the Firebase config object
3. Update `.env` file with:
   ```
   FIREBASE_API_KEY_WEB=your_actual_api_key
   FIREBASE_APP_ID_WEB=your_actual_app_id
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_PROJECT_ID=reboot-rajasthan
   FIREBASE_AUTH_DOMAIN=reboot-rajasthan.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=reboot-rajasthan.appspot.com
   FIREBASE_MEASUREMENT_ID=your_measurement_id
   ```

#### **For Android Platform:**
1. Click on your Android app
2. Copy the API key
3. Update `android/app/google-services.json` (auto-generated if you register the app)
4. Update `.env` file:
   ```
   FIREBASE_API_KEY_ANDROID=your_actual_android_api_key
   FIREBASE_APP_ID_ANDROID=your_actual_android_app_id
   ```

#### **For iOS Platform:**
1. Click on your iOS app
2. Download `GoogleService-Info.plist`
3. Add to Xcode: `ios/Runner/GoogleService-Info.plist`
4. Update `.env` file:
   ```
   FIREBASE_API_KEY_IOS=your_actual_ios_api_key
   FIREBASE_APP_ID_IOS=your_actual_ios_app_id
   FIREBASE_IOS_CLIENT_ID=your_ios_client_id
   FIREBASE_IOS_BUNDLE_ID=com.saafsurksha.app
   ```

### Step 3: Update firebase_options.dart

Replace the demo values in `lib/firebase_options.dart` with actual credentials from `.env`:

```dart
static FirebaseOptions get currentPlatform {
  // For web
  if (kIsWeb) return web;
  // For Android
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return android;
    case TargetPlatform.iOS:
      return ios;
    case TargetPlatform.macOS:
      return macos;
    default:
      throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }
}
```

### Step 4: Enable Firebase Services

In Firebase Console, enable:
- ✅ **Authentication** (Email/Password, Phone, Google)
- ✅ **Cloud Firestore** (Database)
- ✅ **Cloud Storage** (File uploads)
- ✅ **Cloud Messaging** (Push notifications)
- ✅ **Analytics** (Optional but recommended)

### Step 5: Configure Firestore Rules

Set up Firestore security rules in `Firestore Database → Rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    // Allow authenticated users to read issues
    match /issues/{document=**} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == resource.data.reported_by;
    }
    
    // Allow admins to access worker verification
    match /workers/{document=**} {
      allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

### Step 6: Test Firebase Connection

Run the app:

```bash
flutter run -d chrome
```

The app should now:
- ✅ Initialize Firebase on startup
- ✅ Connect to Firestore
- ✅ Enable Firebase Authentication
- ✅ Support push notifications via Cloud Messaging
- ✅ Handle file uploads to Cloud Storage

## 📁 Files Modified

| File | Changes |
|------|---------|
| `main.dart` | Added Firebase initialization |
| `firebase_options.dart` | Created with Firebase config |
| `.env` | Created with credential placeholders |
| `pubspec.yaml` | Added flutter_dotenv |

## 🚀 Firebase Ready Features

Once configured, these features are enabled:

1. **Authentication** - Sign up, login, password reset
2. **Firestore Database** - Real-time issue tracking, worker data
3. **Cloud Storage** - Store issue photos/videos
4. **Cloud Messaging** - Push notifications for issue updates
5. **Analytics** - Track user behavior and engagement

## ⚠️ Important Notes

- Keep `.env` file secret - add to `.gitignore` before pushing to GitHub
- Never commit `GoogleService-Info.plist` or `google-services.json` to public repos
- Firebase credentials in `firebase_options.dart` are for demo purposes - replace with actual values
- Use environment variables for sensitive credentials in production

## 📚 Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Cloud Firestore Security Rules](https://firebase.google.com/docs/firestore/security/start)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
