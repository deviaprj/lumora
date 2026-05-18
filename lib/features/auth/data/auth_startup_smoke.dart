import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthStartupSmoke {
  static const bool _enabled = bool.fromEnvironment(
    'STAGING_SMOKE_AUTH',
    defaultValue: false,
  );

  static const String _facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');
  static const String _facebookClientToken = String.fromEnvironment('FACEBOOK_CLIENT_TOKEN');

  static Future<void> runIfEnabled() async {
    if (!_enabled) {
      return;
    }

    final checks = <String, bool>{};

    checks['firebase_initialized'] = Firebase.apps.isNotEmpty;

    try {
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        'smoke-check@lumora.invalid',
      );
      checks['email_auth_reachable'] = true;
    } catch (_) {
      checks['email_auth_reachable'] = false;
    }

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        checks['apple_available'] = await SignInWithApple.isAvailable();
      } catch (_) {
        checks['apple_available'] = false;
      }
    } else {
      checks['apple_available'] = true;
    }

    checks['facebook_native_config_present'] =
        _facebookAppId.isNotEmpty && _facebookClientToken.isNotEmpty;

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendEmailVerificationCode',
      );
      final response = await callable.call(<String, dynamic>{
        'email': 'smoke+startup@lumora.invalid',
        'intent': 'signup',
      });
      final data = Map<String, dynamic>.from(
        response.data as Map<dynamic, dynamic>,
      );
      checks['email_code_function_reachable'] = (data['sent'] as bool?) ?? false;
    } catch (_) {
      checks['email_code_function_reachable'] = false;
    }

    final failing = checks.entries.where((entry) => !entry.value).toList();
    if (failing.isEmpty) {
      debugPrint('AUTH SMOKE [STAGING]: OK (${checks.length} checks)');
      return;
    }

    final failedKeys = failing.map((entry) => entry.key).join(', ');
    debugPrint('AUTH SMOKE [STAGING]: FAIL -> $failedKeys');
  }
}
