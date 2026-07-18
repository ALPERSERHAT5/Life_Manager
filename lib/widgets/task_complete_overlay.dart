import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Görev tamamlandığında ekranın ortasında kısa süreliğine oynayan
/// yeşil tik + parçacık patlaması animasyonu (Lottie asset gerektirmez).
void showTaskCompleteCelebration(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CelebrationOverlay(onFinished: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CelebrationOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const _CelebrationOverlay({required this.onFinished});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = List.generate(10, (i) {
    final angle = (i / 10) * 2 * pi;
    return _Particle(angle: angle, color: _randomColor(i));
  });

  static Color _randomColor(int i) {
    const colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.warning,
    ];
    return colors[i % colors.length];
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: size.width / 2 - 40,
            top: size.height / 2 - 40,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final scale = t < 0.5 ? (t / 0.5) : 1.0;
                final opacity = t < 0.7 ? 1.0 : 1.0 - ((t - 0.7) / 0.3);
                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                );
              },
            ),
          ),
          ..._particles.map((p) => AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(_controller.value);
                  final distance = 90 * t;
                  final dx = cos(p.angle) * distance;
                  final dy = sin(p.angle) * distance;
                  final opacity = 1.0 - t;
                  return Positioned(
                    left: size.width / 2 + dx - 4,
                    top: size.height / 2 + dy - 4,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                      ),
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

class _Particle {
  final double angle;
  final Color color;
  _Particle({required this.angle, required this.color});
}
