import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tour_controller.dart';
import 'tour_tooltip.dart';

class TourOverlay extends ConsumerStatefulWidget {
  const TourOverlay({super.key});

  @override
  ConsumerState<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends ConsumerState<TourOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _updateTargetRect();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateTargetRect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tourState = ref.read(tourProvider);
      final step = tourSteps[tourState.currentStep];
      final renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
      
      if (renderBox != null) {
        final size = renderBox.size;
        final offset = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _targetRect = offset & size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(tourProvider);
    if (!tourState.isVisible) return const SizedBox.shrink();

    // Re-calculate rect whenever the step changes
    _updateTargetRect();

    final currentStepData = tourSteps[tourState.currentStep];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark Background with Spotlight
          GestureDetector(
            onTap: () {}, // Prevent taps reaching below
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: SpotlightPainter(
                    targetRect: _targetRect,
                    opacity: 0.7 * _animationController.value,
                  ),
                );
              },
            ),
          ),

          // Tooltip Positioned relatively to target
          if (_targetRect != null)
            _buildPositionedTooltip(context, tourState, currentStepData),
        ],
      ),
    );
  }

  Widget _buildPositionedTooltip(BuildContext context, TourState state, TourStep stepData) {
    final screenSize = MediaQuery.of(context).size;
    final targetCenter = _targetRect!.center;
    
    // Determine if tooltip should be above or below
    bool isAbove = targetCenter.dy > screenSize.height / 2;
    
    double? top = isAbove ? null : _targetRect!.bottom + 20;
    double? bottom = isAbove ? (screenSize.height - _targetRect!.top) + 20 : null;
    
    // Horizontal centering with screen padding
    double left = (targetCenter.dx - 140).clamp(20, screenSize.width - 300);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      top: top,
      bottom: bottom,
      left: left,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _targetRect == null ? 0 : 1,
        child: TourTooltip(
          title: stepData.title,
          description: stepData.description,
          step: state.currentStep + 1,
          totalSteps: tourSteps.length,
          onNext: () => ref.read(tourProvider.notifier).nextStep(),
          onPrev: () => ref.read(tourProvider.notifier).prevStep(),
          onSkip: () => ref.read(tourProvider.notifier).skipTour(),
        ),
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double opacity;

  SpotlightPainter({this.targetRect, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // Use BlendMode.dstOut to "punch a hole"
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Draw dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw the cutout (Hole)
    final holePaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.black;

    // Inflate rect slightly for padding around target
    final inflatedRect = targetRect!.inflate(8);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(inflatedRect, const Radius.circular(16)),
      holePaint,
    );

    canvas.restore();
    
    // Draw a subtle border/glow around the hole
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    canvas.drawRRect(
      RRect.fromRectAndRadius(inflatedRect, const Radius.circular(16)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.opacity != opacity;
  }
}
