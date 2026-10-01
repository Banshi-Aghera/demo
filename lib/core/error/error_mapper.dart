import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_strings.dart';
import 'app_exception.dart';

/// Turns any thrown error into a friendly message.
/// Returns null when the user cancelled on purpose and nothing should show.
class ErrorMapper {
  ErrorMapper._();

  static String? message(Object error) {
    if (error is AppException) return error.message;

    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      return AppStrings.errGoogle;
    }

    // Cloud Functions send messages written for users (see functions/src).
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'invalid-argument':
        case 'failed-precondition':
        case 'not-found':
        case 'permission-denied':
        case 'unauthenticated':
          return error.message ?? AppStrings.errGeneric;
        case 'unavailable':
        case 'deadline-exceeded':
          return AppStrings.errNoInternet;
        default:
          return AppStrings.errGeneric;
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'INVALID_LOGIN_CREDENTIALS':
          return AppStrings.errWrongCredentials;
        case 'invalid-email':
          return AppStrings.errEmail;
        case 'email-already-in-use':
          return AppStrings.errEmailInUse;
        case 'weak-password':
          return AppStrings.errWeakPassword;
        case 'network-request-failed':
          return AppStrings.errNoInternet;
        case 'too-many-requests':
          return AppStrings.errTooManyRequests;
        case 'user-disabled':
          return AppStrings.errUserDisabled;
        case 'invalid-verification-code':
          return AppStrings.errInvalidOtp;
        case 'session-expired':
        case 'code-expired':
          return AppStrings.errOtpExpired;
        case 'invalid-phone-number':
          return AppStrings.errInvalidPhone;
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-canceled':
          return null;
        default:
          return AppStrings.errGeneric;
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return AppStrings.errNoInternet;
        case 'permission-denied':
          return AppStrings.errPermission;
        default:
          return AppStrings.errGeneric;
      }
    }

    if (error is TimeoutException) return AppStrings.errNoInternet;

    return AppStrings.errGeneric;
  }
}
