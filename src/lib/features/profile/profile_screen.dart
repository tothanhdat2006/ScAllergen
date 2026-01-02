import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:NutriViet/core/services/theme_service.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/features/auth/login_screen.dart';
import 'package:NutriViet/features/profile/health_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _avatarUrl;

  String? _email;
  String? _name;
  String? _phone;

  final Set<String> _allergies = {};
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadProfile();
  }

  Future<void> _loadThemeMode() async {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    setState(() {
      _isDarkMode = brightness == Brightness.dark;
    });
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        setState(() {
          _email = user.email ?? '';
          _name = data['name'] ?? user.displayName ?? 'User';
          _phone = data['phone'];

          _avatarUrl = data['avatar_url'];

          _allergies.clear();
          if (data['allergies'] != null) {
            _allergies.addAll(List<String>.from(data['allergies']));
          }
        });
      } else {
        setState(() {
          _email = user.email;
          _name = user.displayName ?? 'User';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      File file = File(picked.path);
      String uid = user.uid;

      final storageRef = FirebaseStorage.instance.ref().child('user_avatars').child('$uid.jpg');

      await storageRef.putFile(file);

      final String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'avatar_url': downloadUrl
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_${uid}_avatar_url', downloadUrl);

      if (mounted) {
        setState(() {
          _avatarUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar updated successfully!"), backgroundColor: AppColors.success),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remember_me');

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showSettingsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text("Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            ),
            SwitchListTile(
              title: Text("Dark Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
              value: isDark,
              activeColor: AppColors.primary,
              onChanged: (val) {
                ThemeService.instance.toggleTheme(val);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text("Logout", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, Color? color, required List<Widget> children}) {
    final cardColor = Theme.of(context).cardTheme.color;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Card(
      elevation: 4,
      color: cardColor,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color ?? AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))
            ]),
            const Divider(height: 30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 15.5, color: textColor)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Chip(
        label: Text(text),
        backgroundColor: color.withOpacity(0.1),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        side: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 80, color: Colors.grey)
                            : null,
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                      ),
                    ),

                    if (_isUploading)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                  _name ?? "User",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)
              ),
              Text(
                  _email ?? "",
                  style: TextStyle(fontSize: 16, color: subTextColor)
              ),

              const SizedBox(height: 30),

              _buildCard(
                title: 'Basic Info',
                icon: Icons.person_outline,
                children: [
                  _infoRow(Icons.phone_android_outlined, 'Phone', _phone ?? 'Not set'),
                ],
              ),

              const SizedBox(height: 20),

              _buildCard(
                title: 'Food Allergies',
                icon: Icons.warning_amber_outlined,
                color: AppColors.warning,
                children: [
                  const SizedBox(height: 8),
                  if (_allergies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No allergies added',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allergies.map((e) => _chip(e, AppColors.warning)).toList(),
                    ),
                ],
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthProfileScreen(isEditing: true)));
                    _loadProfile();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}