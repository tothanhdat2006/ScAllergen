import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ScAllergen/core/constants/colors.dart';
import 'package:ScAllergen/features/auth/register_screen.dart';
import 'package:ScAllergen/features/home/main_home_screen.dart';
import 'package:ScAllergen/features/profile/health_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email') ?? '';
    final remember = prefs.getBool('remember_me') ?? false;

    if (savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
      setState(() => _rememberMe = remember);
    }
  }

  Future<void> _handleLoginSuccess(UserCredential userCredential) async {
    final user = userCredential.user;
    if (user == null || !mounted) return;

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    await prefs.setBool('has_seen_welcome', true);
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.remove('remember_me');
    }

    bool isCompleted = prefs.getBool('profile_${uid}_has_completed_profile') ?? false;

    if (!isCompleted) {
      debugPrint("Checking Firestore for User: $uid...");
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['has_completed_profile'] == true) {
            isCompleted = true;
            await prefs.setBool('profile_${uid}_has_completed_profile', true);
            debugPrint("Sync success: Profile IS completed.");
          }
        }
      } catch (e) {
        debugPrint("Firestore check failed: $e");
      }
    }

    if (!mounted) return;

    if (isCompleted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()), (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HealthProfileScreen(isEditing: false)), (route) => false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _handleLoginSuccess(userCredential);

    } on FirebaseAuthException catch (e) {
      _showError("Firebase Error: ${e.message}");
    } catch (e) {
      _showError("Google Sign-In Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please enter email and password");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _handleLoginSuccess(userCredential);
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'invalid-credential' => 'Incorrect email or password',
        'invalid-email' => 'Invalid email address',
        'user-disabled' => 'Account has been disabled',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        _ => 'Login failed: ${e.message}',
      };
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Text("Welcome Back", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 50),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined))),
                const SizedBox(height: 20),
                TextField(controller: _passwordController, obscureText: _obscurePassword, decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))),
                const SizedBox(height: 16),
                Row(children: [Checkbox(value: _rememberMe, activeColor: AppColors.primary, onChanged: (v) => setState(() => _rememberMe = v ?? false)), Text("Remember me", style: TextStyle(color: textColor)), const Spacer()]),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
                const SizedBox(height: 25),
                Row(children: [Expanded(child: Divider(color: Colors.grey[300])), const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey))), Expanded(child: Divider(color: Colors.grey[300]))]),
                const SizedBox(height: 25),
                SizedBox(width: double.infinity, height: 56, child: OutlinedButton.icon(onPressed: _isLoading ? null : _signInWithGoogle, icon: const Icon(Icons.g_mobiledata, size: 36, color: AppColors.error), label: Text("Sign in with Google", style: TextStyle(fontSize: 16, color: textColor)), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), side: BorderSide(color: Colors.grey.withOpacity(0.5))))),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account? ", style: TextStyle(color: textColor)), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("Sign Up", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}