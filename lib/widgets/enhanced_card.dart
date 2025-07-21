import 'package:flutter/material.dart';

class EnhancedCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;
  final bool showBorder;

  const EnhancedCard({
    super.key,
    required this.child,
    this.accentColor,
    this.elevation,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.showShadow = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultAccentColor = accentColor ?? theme.colorScheme.primary;
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: defaultBorderRadius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: defaultBorderRadius,
              border: showBorder
                  ? Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    )
                  : null,
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: defaultAccentColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;

  const GradientIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
