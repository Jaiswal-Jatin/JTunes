import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart'; // Uncomment when you add lottie package

class LottieCharacter extends StatefulWidget {
  const LottieCharacter({super.key});

  @override
  State<LottieCharacter> createState() => _LottieCharacterState();
}

class _LottieCharacterState extends State<LottieCharacter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  
  // List of cute Lottie animation URLs (you can download these and put in assets)
  final List<String> _animationAssets = [
    'assets/animations/cute_cat.json',
    'assets/animations/dancing_dog.json',
    'assets/animations/waving_bear.json',
  ];
  
  int _currentAnimationIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    
    // Change animation every 5 seconds
    _startAnimationCycle();
  }

  void _startAnimationCycle() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentAnimationIndex = (_currentAnimationIndex + 1) % _animationAssets.length;
        });
        _startAnimationCycle();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: 
        // Lottie.asset(
        //   _animationAssets[_currentAnimationIndex],
        //   controller: _controller,
        //   width: 35,
        //   height: 35,
        //   repeat: true,
        //   onLoaded: (composition) {
        //     _controller.duration = composition.duration;
        //     _controller.repeat();
        //   },
        // ),
        
        // Temporary fallback until Lottie is added
        const Text('🐱', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
