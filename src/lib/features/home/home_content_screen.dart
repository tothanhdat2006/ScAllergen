// lib/features/home/presentation/home_content_screen.dart
import 'package:flutter/material.dart';
import 'package:ScAllergen/features/home/header_widget.dart';
import 'package:ScAllergen/features/home/news_section.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});
  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const AppHeader(),

            const SizedBox(height: 24),
            const NewsSection(),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}