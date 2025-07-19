// ignore_for_file: deprecated_member_use, unawaited_futures

/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     J3Tunes is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     J3Tunes is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about J3Tunes, including how to contribute,
 *     please visit: https://github.com/gokadzev/J3Tunes
 */

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:j3tunes/services/router_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.easeInOut,
      ),
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start particle animation immediately
    _particleController.repeat();

    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Start pulse animation
    await Future.delayed(const Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);

    // Navigate to home after total duration
    await Future.delayed(const Duration(milliseconds: 2500));
    _navigateToHome();
  }

  void _navigateToHome() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Navigate to home
    NavigationManager.router.go('/home');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              Theme.of(context).colorScheme.tertiary?.withOpacity(0.4) ??
                  Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    animation: _particleAnimation.value,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  size: size,
                );
              },
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_logoController, _pulseController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value * _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * 0.1, // Subtle rotation
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 60,
                              color: Color(0xFF6366F1), // Indigo color
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // App name with animation
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFF1F5F9)],
                        ).createShader(bounds),
                        child: const Text(
                          'JTunes',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Features text with animation
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.audiotrack,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Audio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.videocam,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Creator credit with animation
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          Text(
                            'Created by',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Jatin Jaiswal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading indicator at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your music experience...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animation;
  final Color color;

  ParticlePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent animation

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;

      // Animate particles with floating effect
      final animatedY = y + sin(animation * 2 * pi + i) * 20;
      final animatedX = x + cos(animation * 2 * pi + i * 0.5) * 10;

      canvas.drawCircle(
        Offset(animatedX, animatedY),
        radius * (0.5 + 0.5 * sin(animation * 2 * pi + i)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
