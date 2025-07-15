# AndCo School Transport - Deployment Guide

This guide covers the complete deployment process for AndCo School Transport mobile application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Build Configuration](#build-configuration)
4. [Android Deployment](#android-deployment)
5. [iOS Deployment](#ios-deployment)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Release Management](#release-management)
8. [Monitoring and Analytics](#monitoring-and-analytics)

## Prerequisites

### Development Environment
- **Flutter SDK**: 3.16.0 or later
- **Dart SDK**: 3.2.0 or later
- **Android Studio**: Latest stable version
- **Xcode**: 15.0 or later (for iOS builds)
- **Git**: Latest version

### Platform Requirements
- **Android**: API level 23+ (Android 6.0+)
- **iOS**: iOS 12.0+
- **macOS**: Required for iOS builds

### Third-party Services
- Firebase project with all required services enabled
- Google Maps API key
- Stripe account (for payments)
- M-Pesa developer account (for Kenya payments)
- Apple Developer account (for iOS)
- Google Play Console account (for Android)

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/andco/school-transport.git
cd school-transport
```

### 2. Install Dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

### 3. Environment Configuration
Create environment-specific configuration files:

#### Firebase Configuration
- Place `google-services.json` in `android/app/`
- Place `GoogleService-Info.plist` in `ios/Runner/`

#### API Keys
Create `lib/core/config/api_keys.dart`:
```dart
class ApiKeys {
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const String stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  // Add other API keys
}
```

## Build Configuration

### Android Configuration

#### 1. Signing Setup
Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

#### 2. Generate Keystore
```bash
keytool -genkey -v -keystore android/app/keystore.jks \
  -alias andco-release-key -keyalg RSA -keysize 2048 -validity 10000
```

#### 3. Build Variants
- **Dev**: Development environment with debug features
- **Prod**: Production environment with optimizations

### iOS Configuration

#### 1. Code Signing
- Configure development and distribution certificates
- Set up provisioning profiles for dev and prod
- Update `ios/Flutter/Development.xcconfig` and `ios/Flutter/Production.xcconfig`

#### 2. App Store Connect
- Create app record in App Store Connect
- Configure app metadata, screenshots, and descriptions

## Android Deployment

### 1. Build APK (Debug)
```bash
./scripts/build_android.sh debug dev
```

### 2. Build APK (Release)
```bash
./scripts/build_android.sh release prod
```

### 3. Build App Bundle
```bash
./scripts/build_android.sh bundle prod
```

### 4. Deploy to Google Play Store

#### Internal Testing
```bash
# Upload AAB to Google Play Console
# Configure internal testing track
# Add internal testers
```

#### Production Release
1. Upload signed AAB to Google Play Console
2. Complete store listing information
3. Set up pricing and distribution
4. Submit for review

### 5. Firebase App Distribution
```bash
firebase appdistribution:distribute build/android/andco-dev-debug.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "internal-testers"
```

## iOS Deployment

### 1. Build for Device (Debug)
```bash
./scripts/build_ios.sh debug dev
```

### 2. Build Archive
```bash
./scripts/build_ios.sh archive prod
```

### 3. Build IPA
```bash
./scripts/build_ios.sh ipa prod
```

### 4. Deploy to TestFlight
```bash
# Upload IPA using Xcode or altool
xcrun altool --upload-app --type ios --file build/ios/AndCo.ipa \
  --username YOUR_APPLE_ID --password YOUR_APP_SPECIFIC_PASSWORD
```

### 5. App Store Release
1. Submit build from TestFlight to App Store
2. Complete app metadata and screenshots
3. Submit for App Store review

## CI/CD Pipeline

### GitHub Actions Workflow

The project includes a comprehensive CI/CD pipeline that:

1. **Runs on every push/PR**:
   - Code quality checks
   - Unit and integration tests
   - Security scanning

2. **Builds artifacts**:
   - Android APK and AAB
   - iOS IPA and archive

3. **Deploys automatically**:
   - Development builds to Firebase App Distribution
   - Production builds to app stores (on release)

### Required Secrets

Configure these secrets in GitHub repository settings:

#### Android
- `ANDROID_KEYSTORE`: Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_PASSWORD`: Key password
- `ANDROID_KEY_ALIAS`: Key alias

#### iOS
- `IOS_CERTIFICATE`: Base64 encoded P12 certificate
- `IOS_CERTIFICATE_PASSWORD`: Certificate password
- `IOS_PROVISIONING_PROFILE`: Base64 encoded provisioning profile

#### App Stores
- `GOOGLE_PLAY_SERVICE_ACCOUNT`: Google Play service account JSON
- `APPLE_ID`: Apple ID for App Store uploads
- `APP_SPECIFIC_PASSWORD`: App-specific password for Apple ID

#### Firebase
- `FIREBASE_TOKEN`: Firebase CLI token
- `FIREBASE_ANDROID_APP_ID`: Firebase Android app ID
- `FIREBASE_IOS_APP_ID`: Firebase iOS app ID

#### Notifications
- `SLACK_WEBHOOK`: Slack webhook URL for notifications

## Release Management

### Version Management

Use the release management script:

```bash
# Create patch release (1.0.0 -> 1.0.1)
./scripts/release_management.sh patch

# Create minor release (1.0.1 -> 1.1.0)
./scripts/release_management.sh minor

# Create major release (1.1.0 -> 2.0.0)
./scripts/release_management.sh major
```

### Release Process

1. **Prepare Release**:
   - Update version numbers
   - Generate changelog
   - Create release notes
   - Build and test artifacts

2. **Create GitHub Release**:
   - Tag the release
   - Upload build artifacts
   - Publish release notes

3. **Deploy to Stores**:
   - Submit to Google Play Store
   - Submit to Apple App Store
   - Monitor deployment status

### Rollback Strategy

If issues are discovered after release:

1. **Immediate Actions**:
   - Stop rollout in app stores
   - Communicate with users
   - Investigate and fix issues

2. **Rollback Options**:
   - Revert to previous app store version
   - Deploy hotfix release
   - Use staged rollout to limit impact

## Monitoring and Analytics

### Firebase Analytics
- Track user engagement and app usage
- Monitor crash reports and performance
- Set up custom events for business metrics

### Performance Monitoring
- Firebase Performance Monitoring
- Crashlytics for crash reporting
- Custom performance metrics

### App Store Analytics
- Google Play Console analytics
- App Store Connect analytics
- User reviews and ratings monitoring

### Alerts and Notifications
- Set up alerts for:
  - High crash rates
  - Performance degradation
  - Unusual user behavior
  - Security incidents

## Security Considerations

### Code Security
- Regular dependency updates
- Security scanning in CI/CD
- Code obfuscation for release builds
- API key protection

### Data Security
- Encrypt sensitive data at rest
- Use HTTPS for all network communication
- Implement proper authentication
- Follow GDPR and data protection guidelines

### App Store Security
- Enable app signing by app stores
- Use app bundle format for Android
- Implement certificate pinning
- Regular security audits

## Troubleshooting

### Common Build Issues

#### Android
- **Gradle build failures**: Check Java version and Gradle compatibility
- **Signing issues**: Verify keystore configuration
- **Dependency conflicts**: Update dependencies and resolve conflicts

#### iOS
- **Code signing errors**: Check certificates and provisioning profiles
- **Build failures**: Update Xcode and CocoaPods
- **Archive issues**: Verify project configuration

### Deployment Issues

#### Google Play Store
- **Review rejections**: Address policy violations
- **Upload failures**: Check AAB format and signing
- **Rollout issues**: Monitor staged rollout metrics

#### Apple App Store
- **Review rejections**: Address App Store guidelines
- **TestFlight issues**: Check build processing status
- **Metadata issues**: Verify app information completeness

## Support and Maintenance

### Regular Maintenance Tasks
- Update dependencies monthly
- Monitor app store reviews
- Analyze crash reports
- Update security configurations
- Review and update documentation

### Emergency Response
- 24/7 monitoring for critical issues
- Escalation procedures for security incidents
- Communication plan for user-facing issues
- Rollback procedures for failed deployments

---

For additional support, contact the development team or refer to the project documentation.
