import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_authSubscription != null) {
      return;
    }

    _setLoading(true);

    _authSubscription = _authService.authStateChanges().listen(
      (user) {
        _user = user;
        _isInitialized = true;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Authentication state failed: $error';
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_messageForAuthException(e));
      return false;
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_messageForAuthException(e));
      return false;
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
    } on FirebaseAuthException catch (e) {
      _setError(_messageForAuthException(e));
    } catch (e) {
      _setError('Logout failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  String _messageForAuthException(FirebaseAuthException exception) {
    final rawMessage = exception.message ?? '';
    final normalizedMessage = rawMessage.toUpperCase();

    if (normalizedMessage.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Authentication is not fully configured for this app yet. In Firebase Console, open Authentication > Sign-in method and enable Email/Password, then try again.';
    }

    switch (exception.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase. Enable it in Firebase Console under Authentication > Sign-in method.';
      case 'internal-error':
        return rawMessage.isNotEmpty
            ? 'Firebase returned an internal configuration error: $rawMessage'
            : 'Firebase returned an internal configuration error. Check Firebase Authentication setup in the console.';
      default:
        return exception.message ?? 'Authentication failed.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

