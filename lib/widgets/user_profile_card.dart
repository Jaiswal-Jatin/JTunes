// ignore_for_file: deprecated_member_use, use_colored_box, require_trailing_commas, sort_constructors_first, directives_ordering

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:j3tunes/models/user_model.dart';
import 'package:j3tunes/services/auth_service.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/screens/user_profile_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserProfile {
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
  UserModel? userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService().getUserDetails();
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
        NavigationManager.router.push(NavigationManager.profilePath).then((_) => _loadUserProfile());
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
                      getGreeting(),
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
                File(userProfile!.profileImagePath!).existsSync() // This check is for local files
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

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}
