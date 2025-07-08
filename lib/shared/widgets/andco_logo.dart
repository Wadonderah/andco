import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AndcoLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final bool showShadow;

  const AndcoLogo({
    super.key,
    this.size = 120,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bus Icon
          Icon(
            Icons.directions_bus_rounded,
            size: size * 0.5,
            color: AppColors.primary,
          ),
          
          // Safety Badge (small circle in top-right)
          Positioned(
            top: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user,
                size: size * 0.12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedAndcoLogo extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final bool showShadow;
  final Duration animationDuration;

  const AnimatedAndcoLogo({
    super.key,
    this.size = 120,
    this.backgroundColor,
    this.showShadow = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedAndcoLogo> createState() => _AnimatedAndcoLogoState();
}

class _AnimatedAndcoLogoState extends State<AnimatedAndcoLogo>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: AndcoLogo(
              size: widget.size,
              backgroundColor: widget.backgroundColor,
              showShadow: widget.showShadow,
            ),
          ),
        );
      },
    );
  }
}
