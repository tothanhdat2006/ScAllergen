import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/features/profile/profile_screen.dart';
import 'package:NutriViet/features/scanner/ocr/scanner_screen.dart';
import 'package:NutriViet/features/community/community_screen.dart';
import 'home_content_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  File? _userAvatar;

  bool _isBarVisible = true;

  final List<Widget> _screens = <Widget>[
    const HomeContentScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAvatar();
  }

  Future<void> _loadUserAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_${user.uid}_avatar_path');
    if (path != null && await File(path).exists()) {
      if (mounted) setState(() => _userAvatar = File(path));
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) _loadUserAvatar();
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  void _toggleBarVisibility(bool visible) {
    if (_isBarVisible != visible) {
      setState(() => _isBarVisible = visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF252525) : Colors.white;
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),

          if (!_isBarVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -5) {
                    _toggleBarVisibility(true);
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 20,
            right: 20,
            bottom: _isBarVisible ? 25 : -120,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 5) {
                  _toggleBarVisibility(false);
                }
              },
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: navBarColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(context, Icons.home_rounded, Icons.home_outlined, 'Home', 0),
                          _buildNavItem(context, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Community', 1),
                          _buildProfileNavItem(context, 2),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: 25,

            bottom: _isBarVisible ? 110 : 25,

            child: SizedBox(
              width: 70,
              height: 70,
              child: FloatingActionButton(
                onPressed: _openScanner,
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: isDark
                        ? const BorderSide(color: Colors.white24, width: 1)
                        : BorderSide.none
                ),
                child: const Icon(Icons.document_scanner_outlined, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNavItem(BuildContext context, IconData selectedIcon, IconData unselectedIcon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.white54 : Colors.grey[400];
    final color = isSelected ? AppColors.primary : unselectedColor;

    return InkResponse(
      onTap: () => _onTabTapped(index),
      radius: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? selectedIcon : unselectedIcon, size: 28, color: color),
            const SizedBox(height: 2),
            if (isSelected)
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(BuildContext context, int index) {
    final bool isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.white54 : Colors.grey[400];
    final color = isSelected ? AppColors.primary : unselectedColor;

    return InkResponse(
      onTap: () => _onTabTapped(index),
      radius: 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userAvatar != null)
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
                ),
                child: CircleAvatar(radius: 13, backgroundImage: FileImage(_userAvatar!), backgroundColor: Colors.grey[300]),
              )
            else
              Icon(isSelected ? Icons.person : Icons.person_outline, size: 28, color: color),
            const SizedBox(height: 2),
            if (isSelected)
              Text('Profile', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}