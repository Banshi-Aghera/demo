import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/services/push_notification_service.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Returned by [sendOtp] when Android verified the SMS automatically and
  /// the user is already signed in.
  static const autoVerifiedId = '__auto_verified__';
  static const _webVerificationId = '__web__';

  bool _googleInitialized = false;
  ConfirmationResult? _webConfirmation;
  int? _resendToken;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return AppUser.fromJson({...data, 'uid': snap.id});
    });
  }

  // ---------- Email / password ----------

  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _afterSignIn(cred.user!);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone10,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(fullName.trim());
    await _createUserDoc(
      uid: user.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: '${AppConstants.indiaDialCode}${phone10.trim()}',
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ---------- Google ----------

  Future<void> signInWithGoogle() async {
    final UserCredential cred;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()..addScope('email');
      cred = await _auth.signInWithPopup(provider);
    } else {
      final google = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await google.initialize();
        _googleInitialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }
    await _afterSignIn(cred.user!);
  }

  // ---------- Phone OTP ----------

  /// Sends an OTP and completes with a verification id once the code is sent.
  /// Completes with [autoVerifiedId] if Android signed the user in by itself.
  Future<String> sendOtp(String phoneE164) async {
    if (kIsWeb) {
      _webConfirmation = await _auth.signInWithPhoneNumber(phoneE164);
      return _webVerificationId;
    }

    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          await _afterSignIn(cred.user!);
          if (!completer.isCompleted) completer.complete(autoVerifiedId);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, resendToken) {
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  Future<void> verifyOtp(String verificationId, String code) async {
    final UserCredential cred;
    if (verificationId == _webVerificationId) {
      final confirmation = _webConfirmation;
      if (confirmation == null) {
        throw const AppException(AppStrings.errOtpExpired);
      }
      cred = await confirmation.confirm(code.trim());
    } else {
      cred = await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code.trim(),
        ),
      );
    }
    await _afterSignIn(cred.user!);
  }

  // ---------- Profile documents ----------

  /// Creates the Firestore profile if this is the user's first sign-in.
  Future<void> ensureUserDoc(User user) async {
    final snap = await _users.doc(user.uid).get();
    if (snap.exists) return;
    await _createUserDoc(
      uid: user.uid,
      fullName: user.displayName ?? '',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      photoUrl: user.photoURL,
    );
  }

  Future<void> _createUserDoc({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    String? photoUrl,
  }) {
    final profile = AppUser(
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
    return _users.doc(uid).set({
      ...profile.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Makes sure the profile exists and the account isn't blocked.
  Future<void> _afterSignIn(User user) async {
    await ensureUserDoc(user);
    final snap = await _users.doc(user.uid).get();
    if (snap.data()?['blocked'] == true) {
      await signOut();
      throw const AppException(AppStrings.errBlocked);
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    final token = await PushNotificationService.currentToken();
    if (uid != null && token != null) {
      try {
        await _users.doc(uid).collection(FirestoreCollections.fcmTokens).doc(token).delete();
      } catch (_) {
        // Offline: the server prunes dead tokens when sends fail.
      }
    }
    if (!kIsWeb && _googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google session may already be gone; Firebase sign-out still runs.
      }
    }
    await _auth.signOut();
  }
}
