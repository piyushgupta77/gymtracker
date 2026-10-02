
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'firebase_setup_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.firebaseInitializationError,
  });

  final String? firebaseInitializationError;

  @override
  Widget build(BuildContext context) {
    if (firebaseInitializationError != null) {
      return FirebaseSetupScreen(errorMessage: firebaseInitializationError);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isInitialized || authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

