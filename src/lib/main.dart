import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/main_home_screen.dart';
import 'features/profile/health_profile_screen.dart';
import 'core/services/theme_service.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Camera error: $e");
    cameras = [];
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ThemeService.instance.loadTheme();

  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  final bool rememberMe = prefs.getBool('remember_me') ?? false;

  Widget targetScreen;

  if (user == null) {
    bool hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    targetScreen = hasSeenWelcome ? const LoginScreen() : const WelcomeScreen();
  }
  else {
    if (!rememberMe) {
      await FirebaseAuth.instance.signOut();
      targetScreen = const LoginScreen();
    }
    else {
      final uid = user.uid;
      bool isCompleted = prefs.getBool('profile_${uid}_has_completed_profile') ?? false;

      if (!isCompleted) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data()?['has_completed_profile'] == true) {
            isCompleted = true;
            await prefs.setBool('profile_${uid}_has_completed_profile', true);
          }
        } catch (e) {
          debugPrint("Main Firestore check error: $e");
        }
      }

      if (isCompleted) {
        targetScreen = const MainHomeScreen();
      } else {
        targetScreen = const HealthProfileScreen(isEditing: false);
      }
    }
  }
  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, currentMode, child) {
        return NutriVietApp(
          initialScreen: targetScreen,
          themeMode: currentMode,
        );
      },
    ),
  );
}