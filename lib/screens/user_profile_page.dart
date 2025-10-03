// ignore_for_file: use_colored_box, deprecated_member_use, require_trailing_commas, omit_local_variable_types

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:j3tunes/models/user_model.dart';
import 'package:j3tunes/services/auth_service.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;

  UserModel? userProfile;
  String? selectedImagePath;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getUserDetails();
    setState(() {
      userProfile = profile;
      _nameController.text = profile?.name ?? '';
      _emailController.text = profile?.email ?? '';
      _mobileController.text = profile?.mobile ?? '';
      _addressController.text = profile?.address ?? '';
      _selectedDate = profile?.dob;
      selectedImagePath = profile?.profileImagePath;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        isLoading = true;
      });

      final savedPath = await _saveProfileImage(image);

      setState(() {
        selectedImagePath = savedPath;
        isLoading = false;
      });

      if (savedPath == null) {
        showToast(context, 'Failed to save image');
      }
    }
  }

  Future<String?> _saveProfileImage(XFile imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileImageDir = Directory('${appDir.path}/profile_images');

      if (!await profileImageDir.exists()) {
        await profileImageDir.create(recursive: true);
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${profileImageDir.path}/$fileName');

      await File(imageFile.path).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (userProfile == null) return;

    setState(() {
      isLoading = true;
    });

    final updatedProfile = userProfile!.copyWith(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      dob: _selectedDate,
      profileImagePath: selectedImagePath,
    );
    await AuthService().updateUserProfile(updatedProfile);

    setState(() {
      isLoading = false;
    });

    showToast(context, 'Profile updated successfully!');
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!isLoading)
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(FluentIcons.checkmark_24_filled),
            ),
        ],
      ),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: selectedImagePath != null &&
                                      File(selectedImagePath!).existsSync()
                                  ? Image.file(
                                      File(selectedImagePath!),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: theme.colorScheme.primaryContainer,
                                      child: Icon(
                                        FluentIcons.person_24_filled,
                                        color: theme.colorScheme.primary,
                                        size: 60,
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: isLoading ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  FluentIcons.camera_24_filled,
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: const Icon(FluentIcons.person_24_regular),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                     TextFormField(
                      controller: _emailController,
                      readOnly: true, // Email is not editable
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(FluentIcons.mail_24_regular),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mobile Field
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(
                        labelText: 'Mobile',
                        prefixIcon: const Icon(FluentIcons.phone_24_regular),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(FluentIcons.location_24_regular),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // DOB Field
                    TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selectedDate == null
                            ? ''
                            : DateFormat.yMMMd().format(_selectedDate!),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Profile Stats
                    _buildProfileStats(),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Profile Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                child: _buildStatItem(
                  'Member Since',
                  _formatDate(userProfile!.dob), // Using dob as a placeholder for creation date
                  FluentIcons.calendar_24_regular,
                ),
              ),
              Flexible(
                child: _buildStatItem(
                  'Profile Complete',
                  '${_calculateProfileCompletion()}%',
                  FluentIcons.checkmark_circle_24_regular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  int _calculateProfileCompletion() {
    if (userProfile == null) return 0;
    int completion = 20; // Base for existing account
    if (userProfile!.name.isNotEmpty) completion += 20;
    if (userProfile!.mobile.isNotEmpty) completion += 20;
    if (userProfile!.address.isNotEmpty) completion += 20;
    if (userProfile!.profileImagePath != null) completion += 20;
    return completion;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
