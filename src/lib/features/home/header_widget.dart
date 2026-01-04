// lib/features/home/header_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ScAllergen/core/constants/colors.dart';
import 'package:ScAllergen/core/constants/app_quotes.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  Future<Map<String, String?>> _getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'name': 'User', 'avatar': null};
    }

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'profile_$uid';

    String name = prefs.getString('${prefix}_name') ?? '';
    if (name.isEmpty) {
      name = user.displayName ?? 'User';
    }

    String? avatarUrl = prefs.getString('${prefix}_avatar_url');

    if (avatarUrl == null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          avatarUrl = doc.data()?['avatar_url'];
          if (avatarUrl != null) {
            await prefs.setString('${prefix}_avatar_url', avatarUrl);
          }
        }
      } catch (e) {
        debugPrint("Header fetch error: $e");
      }
    }

    return {
      'name': name,
      'avatar': avatarUrl,
    };
  }

  String _getDailyQuote() {
    if (dailyQuotes.isEmpty) return "A healthy outside starts from the inside.";
    final int daysSinceEpoch = DateTime.now().difference(DateTime(1970)).inDays;
    final int index = daysSinceEpoch % dailyQuotes.length;
    return dailyQuotes[index];
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final String todayQuote = _getDailyQuote();

    return FutureBuilder<Map<String, String?>>(
      future: _getUserProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final name = data?['name'] ?? "User";
        final avatarUrl = data?['avatar'];
        final displayName = name.split(" ").last;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 10, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? const Icon(Icons.person, size: 24, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back,",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.format_quote, color: Colors.white70, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "DAILY INSPIRATION",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        todayQuote,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}