import 'package:flutter/material.dart';

class SecuraNotifications {
  static void showSnackBar(
    BuildContext context, 
    String message, {
    bool isError = false,
    bool isSuccess = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Choose colors based on status
    Color bgColor;
    IconData displayIcon = icon ?? Icons.info_outline_rounded;
    
    if (isError) {
      bgColor = const Color(0xFFFF4D4D);
      displayIcon = icon ?? Icons.error_outline_rounded;
    } else if (isSuccess) {
      bgColor = const Color(0xFF4CAF50);
      displayIcon = icon ?? Icons.check_circle_outline_rounded;
    } else {
      bgColor = isDark ? const Color(0xFF2C3344) : const Color(0xFF575992);
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(displayIcon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, isSuccess: true);
  }
}
