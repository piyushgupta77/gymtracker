import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/firebase_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseInitializationError;

  try {
    await Firebase.initializeApp();
  } catch (error) {
    firebaseInitializationError = error.toString();
  }

  runApp(
    MyApp(
      enableFirebase: firebaseInitializationError == null,
      firebaseInitializationError: firebaseInitializationError,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.enableFirebase = false,
    this.firebaseInitializationError,
  });

  final bool enableFirebase;
  final String? firebaseInitializationError;

  @override
  Widget build(BuildContext context) {
    if (!enableFirebase) {
      return MaterialApp(
        title: 'Gym Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FirebaseSetupScreen(errorMessage: firebaseInitializationError),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider(),
          update: (_, authProvider, workoutProvider) {
            workoutProvider ??= WorkoutProvider();
            workoutProvider.updateCurrentUser(authProvider.user?.uid);
            return workoutProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Gym Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
