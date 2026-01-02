import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:NutriViet/core/constants/colors.dart';
import 'package:NutriViet/features/home/main_home_screen.dart';

class HealthProfileScreen extends StatefulWidget {
  final bool isEditing;
  const HealthProfileScreen({super.key, this.isEditing = false});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  int _currentStep = 0;
  final int _totalSteps = 2;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late TextEditingController _allergySearchController;

  final Set<String> _allergies = {};

  File? _localAvatarFile;
  String? _avatarUrl;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _allergySearchController = TextEditingController();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _allergySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'profile_$uid';

    String savedName = prefs.getString('${prefix}_name') ?? '';
    String savedPhone = prefs.getString('${prefix}_phone') ?? '';
    List<String> savedAllergies = prefs.getStringList('${prefix}_allergies') ?? [];
    String? savedAvatarUrl = prefs.getString('${prefix}_avatar_url');

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        savedName = data['name'] ?? savedName;
        savedPhone = data['phone'] ?? savedPhone;
        savedAvatarUrl = data['avatar_url'] ?? savedAvatarUrl;

        if (data['allergies'] != null) {
          savedAllergies = List<String>.from(data['allergies']);
        }
      }
    } catch (e) {
      debugPrint("Error loading from Firestore: $e");
    }

    if (!mounted) return;

    setState(() {
      _nameController.text = savedName.isNotEmpty ? savedName : (user.displayName ?? '');
      _phoneController.text = savedPhone;
      _avatarUrl = savedAvatarUrl;

      _allergies.clear();
      _allergies.addAll(savedAllergies);
    });
  }

  Future<void> _saveDraftData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'profile_${user.uid}';

    await prefs.setString('${prefix}_name', _nameController.text.trim());
    await prefs.setStringList('${prefix}_allergies', _allergies.toList());
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        _localAvatarFile = File(picked.path);
        _isUploading = true;
      });

      final storageRef = FirebaseStorage.instance.ref().child('user_avatars').child('${user.uid}.jpg');
      await storageRef.putFile(_localAvatarFile!);

      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _avatarUrl = downloadUrl;
        _isUploading = false;
      });

      if (widget.isEditing) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'avatar_url': downloadUrl
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_${user.uid}_avatar_url', downloadUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar updated!"), backgroundColor: AppColors.success),
          );
        }
      }

    } catch (e) {
      debugPrint("Avatar upload error: $e");
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name"), backgroundColor: AppColors.error));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'phone': _phoneController.text.trim(),
        'allergies': _allergies.toList(),
        'avatar_url': _avatarUrl,
        'has_completed_profile': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      final prefix = 'profile_$uid';
      await prefs.setString('${prefix}_name', _nameController.text.trim());
      await prefs.setString('${prefix}_phone', _phoneController.text.trim());
      await prefs.setStringList('${prefix}_allergies', _allergies.toList());
      await prefs.setBool('${prefix}_has_completed_profile', true);

      if (_avatarUrl != null) {
        await prefs.setString('${prefix}_avatar_url', _avatarUrl!);
      }

      try {
        await user.updateDisplayName(_nameController.text.trim());
      } catch (_) {}

      if (!mounted) return;
      Navigator.pop(context);

      if (widget.isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes saved!"), backgroundColor: AppColors.success));
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainHomeScreen()), (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in your name"), backgroundColor: AppColors.warning));
        return;
      }
      _saveDraftData();
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? "Food Allergies" : "Any Allergies?",
          style: TextStyle(
            fontSize: widget.isEditing ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        if (!widget.isEditing) ...[
          const SizedBox(height: 10),
          Text("Select or search so we can warn you", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
        const SizedBox(height: 20),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) return const Iterable<String>.empty();
            final String query = textEditingValue.text.trim();
            final Uri url = Uri.parse('https://fuscous-actiniform-javion.ngrok-free.dev/node?text=$query');
            try {
              final response = await http.get(url);
              if (response.statusCode == 200) {
                final Map<String, dynamic> data = jsonDecode(response.body);
                final List<dynamic> suggestions = data['suggest_nodes'] ?? [];
                return suggestions.map((item) => item['label'].toString()).toList();
              }
            } catch (e) { debugPrint("Err: $e"); }
            return const Iterable<String>.empty();
          },
          onSelected: (String selection) {
            if (!_allergies.contains(selection)) setState(() => _allergies.add(selection));
            _allergySearchController.clear();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _allergySearchController = controller;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Search (apple, milk, egg...)",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.food_bank_outlined, color: AppColors.warning),
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        if (_allergies.isEmpty)
          Text("No allergies selected", style: TextStyle(color: Colors.grey[600]))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((allergy) {
              return Chip(
                label: Text(allergy),
                backgroundColor: AppColors.error.withOpacity(0.15),
                labelStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => setState(() => _allergies.remove(allergy)),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStep1Info() {
    ImageProvider? bgImage;
    if (_localAvatarFile != null) {
      bgImage = FileImage(_localAvatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      bgImage = NetworkImage(_avatarUrl!);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const Text("Welcome!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Update your profile to get started"),
          const SizedBox(height: 40),

          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: bgImage,
                  child: (bgImage == null) ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) : null,
                ),
                if (_isUploading)
                  const Positioned.fill(child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),

          const SizedBox(height: 40),
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter name',
                  prefixIcon: Icon(Icons.person_outline)
              )
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Allergies() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _buildAllergiesSection(),
      ),
    );
  }

  Widget _buildWizardLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(padding: const EdgeInsets.all(24.0), child: Column(children: [
        LinearProgressIndicator(value: (_currentStep + 1) / _totalSteps, backgroundColor: Colors.grey.withOpacity(0.2), color: AppColors.primary, minHeight: 6, borderRadius: BorderRadius.circular(10)),
        const SizedBox(height: 20),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: KeyedSubtree(key: ValueKey(_currentStep),
            child: _currentStep == 0 ? _buildStep1Info() : _buildStep2Allergies()))),
        const SizedBox(height: 10),
        Row(children: [
          if (_currentStep > 0) Expanded(flex: 1, child: OutlinedButton(onPressed: _prevStep, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text("Back", style: TextStyle(color: AppColors.primary)))),
          if (_currentStep > 0) const SizedBox(width: 15),
          Expanded(flex: 2, child: ElevatedButton(onPressed: _nextStep, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: Text(_currentStep == _totalSteps - 1 ? "Finish" : "Next", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
        ]),
      ]));
    });
  }

  Widget _buildEditLayout() {
    ImageProvider? bgImage;
    if (_localAvatarFile != null) {
      bgImage = FileImage(_localAvatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      bgImage = NetworkImage(_avatarUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: bgImage,
                    child: bgImage == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) : null,
                  ),
                  if (!_isUploading)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  if (_isUploading)
                    const Positioned.fill(child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person))),
          const SizedBox(height: 20),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 30),
          _buildAllergiesSection(),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text("Save Changes", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEditing ? AppBar(title: const Text("Edit Profile"), centerTitle: true) : null,
      body: SafeArea(child: widget.isEditing ? _buildEditLayout() : _buildWizardLayout()),
    );
  }
}