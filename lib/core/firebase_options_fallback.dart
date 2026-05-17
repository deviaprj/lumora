import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

class FirebaseOptionsFallback {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const String _macosAppId = String.fromEnvironment('FIREBASE_MACOS_APP_ID');
  static const String _macosBundleId = String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID');

  static FirebaseOptions? get currentPlatform {
    if (_apiKey.isEmpty || _projectId.isEmpty || _messagingSenderId.isEmpty) {
      return null;
    }

    if (Platform.isAndroid) {
      if (_androidAppId.isEmpty) {
        return null;
      }

      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      );
    }

    if (Platform.isIOS) {
      if (_iosAppId.isEmpty) {
        return null;
      }

      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
        iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
      );
    }

    if (Platform.isMacOS) {
      if (_macosAppId.isEmpty) {
        return null;
      }

      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _macosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
        iosBundleId: _macosBundleId.isEmpty ? null : _macosBundleId,
      );
    }

    return null;
  }
}