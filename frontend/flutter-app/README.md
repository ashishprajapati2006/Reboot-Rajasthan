# Flutter SAAF-SURKSHA App

Complete Flutter-based mobile application for SAAF-SURKSHA civic issue tracking system.

## Features

✅ **Authentication**
- Login with email/password
- Registration with validation
- Secure token storage
- Auto-logout on token expiry

✅ **Camera with AI Detection**
- Live camera feed
- GPS location capture
- Accelerometer sensor data (X, Y, Z axes)
- Light sensor data (lux)
- AI-powered issue detection (YOLOv8)
- Real-time confidence scoring
- Fraud prevention with multi-sensor validation

✅ **Home Dashboard**
- Civic Health Score display
- Recent issues feed
- Quick action buttons
- Pull-to-refresh

✅ **Bottom Navigation**
- Home
- Camera
- Map (placeholder)
- My Issues (placeholder)
- Profile (placeholder)

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart 3.0.0 or higher
- Android Studio / Xcode for emulator
- Physical device recommended for camera/sensors

## Setup

### 1. Install Flutter Dependencies

\`\`\`bash
cd frontend/flutter-app
flutter pub get
\`\`\`

### 2. Update API Base URL

Edit `lib/utils/constants.dart` and update the base URL:

\`\`\`dart
static const String baseUrl = 'http://YOUR_IP:8000/api/v1';
\`\`\`

**For Android Emulator:** Use `http://10.0.2.2:8000/api/v1`  
**For Physical Device:** Use your computer's local IP (e.g., `http://192.168.1.100:8000/api/v1`)

### 3. Android Configuration

Add permissions to `android/app/src/main/AndroidManifest.xml`:

\`\`\`xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application ...>
        ...
    </application>
</manifest>
\`\`\`

Update `android/app/build.gradle`:

\`\`\`gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
\`\`\`

### 4. iOS Configuration

Add to `ios/Runner/Info.plist`:

\`\`\`xml
<key>NSCameraUsageDescription</key>
<string>Need camera access to capture civic issues</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Need location to tag civic issues</string>
<key>NSMotionUsageDescription</key>
<string>Need motion sensor to prevent fraud</string>
\`\`\`

## Run the App

### On Android Emulator/Device

\`\`\`bash
flutter run
\`\`\`

### On iOS Simulator/Device

\`\`\`bash
flutter run -d ios
\`\`\`

### Build APK (Android)

\`\`\`bash
flutter build apk --release
\`\`\`

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (Google Play)

\`\`\`bash
flutter build appbundle --release
\`\`\`

### Build iOS (requires Mac)

\`\`\`bash
flutter build ios --release
\`\`\`

## Project Structure

\`\`\`
lib/
├── main.dart                    # App entry point
├── services/
│   └── api_service.dart         # API integration layer (Dio)
├── utils/
│   ├── constants.dart           # Colors, spacing, API URLs
│   └── app_theme.dart           # Material Theme configuration
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Login with validation
│   │   └── register_screen.dart # Registration form
│   ├── home/
│   │   └── home_screen.dart     # Dashboard with civic health
│   └── camera/
│       └── camera_screen.dart   # Camera + AI detection + sensors
└── models/                      # Data models (future)
\`\`\`

## Key Dependencies

- **dio**: HTTP client with interceptors
- **camera**: Camera access and capture
- **geolocator**: GPS location services
- **sensors_plus**: Accelerometer access
- **light**: Light sensor (may not work on all devices)
- **permission_handler**: Runtime permissions
- **flutter_secure_storage**: Secure token storage
- **google_maps_flutter**: Map integration (future)

## Testing

### 1. Start Backend

\`\`\`bash
cd reboot-rajasthan
docker-compose up -d
\`\`\`

### 2. Test Complete Flow

1. Open app → Should show splash screen
2. Register account with valid data
3. Login with credentials
4. Navigate to Camera tab
5. Grant camera and location permissions
6. Take photo of any object
7. Watch sensor data update in real-time
8. Submit → AI detects issue type
9. Confirm → Issue created in backend
10. View on Home dashboard

## Troubleshooting

### Camera not working
- Check permissions in device settings
- Restart the app
- Use physical device instead of emulator

### Location not updating
- Enable location services
- Grant location permission to app
- Use physical device for best results

### API connection failed
- Check backend is running: `docker-compose ps`
- Verify base URL in constants.dart
- For Android emulator, use `10.0.2.2` instead of `localhost`
- For physical device, ensure device and computer are on same network

### Build errors
\`\`\`bash
flutter clean
flutter pub get
flutter pub upgrade
flutter run
\`\`\`

## Next Steps

- [ ] Implement Map screen with Google Maps
- [ ] Create My Issues screen with filters
- [ ] Build Profile screen with stats
- [ ] Add push notifications
- [ ] Implement offline mode with local database
- [ ] Add social sharing features
- [ ] Create Worker app variant
- [ ] Add Hindi/regional language support

## Performance Tips

- Use release build for testing: `flutter run --release`
- Enable minification for production builds
- Optimize images before uploading
- Implement pagination for issue lists
- Cache API responses locally

## License

Proprietary - REBOOT RAJASTHAN Hackathon Project
