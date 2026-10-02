import 'package:flutter/material.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({
    super.key,
    this.errorMessage,
  });

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Setup Required',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'The app could not initialize Firebase. Connect this Android app to your Firebase project in Android Studio and add the Firebase configuration before signing in.',
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Required Android file: android/app/google-services.json',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

