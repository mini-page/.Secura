import 'package:flutter/material.dart';

class TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final int step;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onSkip;

  const TourTooltip({
    required this.title,
    required this.description,
    required this.step,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.onPrev,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps;
    final isFirst = step == 1;

    return Card(
      elevation: 12,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  '$step/$totalSteps',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isFirst)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: onPrev,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Finish' : 'Next',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
