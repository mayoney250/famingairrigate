import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ErrorService {
  static String toMessage(Object error) {
    // Firebase Auth specific
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support if this is a mistake.';
        case 'user-not-found':
          return 'No account found for that email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'That email is already registered. Try signing in instead.';
        case 'weak-password':
          return 'Your password is too weak. Use at least 6 characters.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    // Firestore / Firebase generic
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again later.';
        case 'not-found':
          return 'Requested data was not found.';
        case 'already-exists':
          return 'This item already exists.';
        case 'cancelled':
          return 'The operation was cancelled.';
        case 'deadline-exceeded':
          return 'The request timed out. Please try again.';
        default:
          return error.message ?? 'A data error occurred. Please try again.';
      }
    }

    // Platform exceptions
    if (error is PlatformException) {
      return error.message ?? 'A device error occurred. Please try again.';
    }

    // Network and timeouts
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'The request took too long. Please try again.';
    }

    // String-throw or other
    if (error is String) {
      return error;
    }

    return 'Something went wrong. Please try again.';
  }
}


