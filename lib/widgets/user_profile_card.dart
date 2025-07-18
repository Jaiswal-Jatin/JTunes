// ignore_for_file: deprecated_member_use, use_colored_box, require_trailing_commas, sort_constructors_first, directives_ordering

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:j3tunes/screens/user_profile_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserProfile {
  final String name;
  final String email;
  final String? profileImagePath;
  final DateTime createdAt;

  UserProfile({
    required this.name,
    required this.email,
    this.profileImagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'profileImagePath': profileImagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? 'Music Lover',
        email: json['email'] ?? '',
        profileImagePath: json['profileImagePath'],
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
      );
}

class UserProfileService {
  static const String _profileKey = 'user_profile';
  static UserProfile? _cachedProfile;

  static Future<UserProfile> getUserProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);

    if (profileJson != null) {
      _cachedProfile = UserProfile.fromJson(json.decode(profileJson));
    } else {
      _cachedProfile = UserProfile(
        name: 'Music Lover',
        email: '',
        createdAt: DateTime.now(),
      );
    }

    return _cachedProfile!;
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(profile.toJson()));
    _cachedProfile = profile;
  }

  static Future<String?> saveProfileImage(XFile imageFile) async {
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

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

class UserProfileCard extends StatefulWidget {
  final bool showGreeting;
  final bool isCompact;

  const UserProfileCard({
    super.key,
    this.showGreeting = true,
    this.isCompact = false,
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  UserProfile? userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfileService.getUserProfile();
    if (mounted) {
      setState(() {
        userProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const SizedBox(
          height: 80, child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfilePage(),
          ),
        ).then((_) => _loadUserProfile()); // Refresh after returning
      },
      child: Container(
        padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            _buildProfileImage(),
            const SizedBox(width: 12),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showGreeting) ...[
                    Text(
                      UserProfileService.getGreeting(),
                      style: TextStyle(
                        fontSize: widget.isCompact ? 12 : 14,
                        color: theme.colorScheme.onPrimaryContainer
                            .withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    userProfile!.name,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (userProfile!.email.isNotEmpty && !widget.isCompact) ...[
                    const SizedBox(height: 2),
                    Text(
                      userProfile!.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer
                            .withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              FluentIcons.chevron_right_24_regular,
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.6),
              size: widget.isCompact ? 16 : 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final size = widget.isCompact ? 40.0 : 50.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: userProfile!.profileImagePath != null &&
                File(userProfile!.profileImagePath!).existsSync()
            ? Image.file(
                File(userProfile!.profileImagePath!),
                fit: BoxFit.cover,
              )
            : Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  FluentIcons.person_24_filled,
                  color: Theme.of(context).colorScheme.primary,
                  size: size * 0.6,
                ),
              ),
      ),
    );
  }
}
