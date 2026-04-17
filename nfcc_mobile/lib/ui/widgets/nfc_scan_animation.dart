import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NfcScanAnimation extends StatefulWidget {
  final bool isScanning;
  final double size;

  const NfcScanAnimation({
    super.key,
    required this.isScanning,
    this.size = 180,
  });

  @override
  State<NfcScanAnimation> createState() => _NfcScanAnimationState();
}

class _NfcScanAnimationState extends State<NfcScanAnimation>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.isScanning) _startAnimations();
  }

  @override
  void didUpdateWidget(NfcScanAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _startAnimations();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _rippleController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _pulseController.reset();
    _rippleController.stop();
    _rippleController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.6,
      height: widget.size * 1.6,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings (only when scanning)
          if (widget.isScanning)
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  final progress =
                      (_rippleController.value + index * 0.33) % 1.0;
                  final opacity = (1.0 - progress).clamp(0.0, 0.4);
                  final scale = 1.0 + progress * 0.6;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.nfcGlow.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // Main circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isScanning ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isScanning
                    ? AppColors.nfcBlue.withValues(alpha: 0.15)
                    : AppColors.surfaceElevated,
                border: Border.all(
                  color: widget.isScanning
                      ? AppColors.nfcGlow.withValues(alpha: 0.5)
                      : AppColors.border,
                  width: widget.isScanning ? 2 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.nfc_rounded,
                  size: widget.size * 0.4,
                  color: widget.isScanning
                      ? AppColors.nfcGlow
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
