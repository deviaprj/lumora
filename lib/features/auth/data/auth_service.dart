import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class EmailCodeRequestResult {
  final bool sent;
  final bool emailAlreadyExists;
  final String? message;

  const EmailCodeRequestResult({
    required this.sent,
    required this.emailAlreadyExists,
    this.message,
  });
}

class EmailCodeVerifyResult {
  final bool verified;
  final String? verificationToken;
  final String? message;

  const EmailCodeVerifyResult({
    required this.verified,
    this.verificationToken,
    this.message,
  });
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _authOverride = auth,
        _functionsOverride = functions;

  final FirebaseAuth? _authOverride;
  final FirebaseFunctions? _functionsOverride;

  FirebaseAuth get _auth {
    if (_authOverride != null) {
      return _authOverride!;
    }
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Vérifie la configuration mobile (google-services / dart-define).',
      );
    }
    return FirebaseAuth.instance;
  }

  FirebaseFunctions get _functions {
    if (_functionsOverride != null) {
      return _functionsOverride!;
    }
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Impossible d\'appeler les Cloud Functions.',
      );
    }
    return FirebaseFunctions.instance;
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-cancelled',
        message: 'Connexion Google annulée.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    if (!(Platform.isIOS || Platform.isMacOS)) {
      throw FirebaseAuthException(
        code: 'apple-not-supported',
        message: 'Apple Sign-In est disponible sur iOS/macOS.',
      );
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: <AppleIDAuthorizationScopes>[
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return _auth.signInWithCredential(oauthCredential);
  }

  Future<UserCredential> signInWithFacebook() async {
    final loginResult = await FacebookAuth.instance.login();
    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw FirebaseAuthException(
        code: 'facebook-cancelled',
        message: 'Connexion Facebook annulée ou refusée.',
      );
    }

    final credential = FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<EmailCodeRequestResult> requestEmailVerificationCode({
    required String email,
  }) async {
    final callable = _functions.httpsCallable('sendEmailVerificationCode');
    final result = await callable.call(<String, dynamic>{
      'email': email.trim(),
      'intent': 'signup',
    });

    final data = Map<String, dynamic>.from(result.data as Map<dynamic, dynamic>);
    return EmailCodeRequestResult(
      sent: (data['sent'] as bool?) ?? false,
      emailAlreadyExists: (data['emailAlreadyExists'] as bool?) ?? false,
      message: data['message'] as String?,
    );
  }

  Future<EmailCodeVerifyResult> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('verifyEmailVerificationCode');
    final result = await callable.call(<String, dynamic>{
      'email': email.trim(),
      'code': code.trim(),
    });

    final data = Map<String, dynamic>.from(result.data as Map<dynamic, dynamic>);
    return EmailCodeVerifyResult(
      verified: (data['verified'] as bool?) ?? false,
      verificationToken: data['verificationToken'] as String?,
      message: data['message'] as String?,
    );
  }

  Future<UserCredential> finalizeEmailSignup({
    required String email,
    required String password,
    required String verificationToken,
  }) async {
    final callable = _functions.httpsCallable('finalizeEmailSignup');
    final result = await callable.call(<String, dynamic>{
      'email': email.trim(),
      'password': password,
      'verificationToken': verificationToken,
    });

    final data = Map<String, dynamic>.from(result.data as Map<dynamic, dynamic>);
    final customToken = data['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-custom-token',
        message: 'Le backend n\'a pas renvoyé de token de connexion.',
      );
    }

    return _auth.signInWithCustomToken(customToken);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
