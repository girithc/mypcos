import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  /// Text used by the default tap-handler’s bottom-sheet
  final String title;

  /// The header—could be a Text or any custom widget
  final Widget titleWidget;

  /// Usually a progress / status / countdown widget
  final Widget indicatorWidget;

  /// Card’s fill color
  final Color backgroundColor;

  /// Optional tap callback; if null a default bottom-sheet appears
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.titleWidget,
    required this.indicatorWidget,
    this.backgroundColor = Colors.white,
    this.onTap,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    // ── default preview bottom-sheet ──
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(height: 200, child: Center(child: Text(title))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        // Let the card size itself to its children ↓
        child: Column(
          mainAxisSize: MainAxisSize.min, // ← SHRINK-WRAP vertically
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [titleWidget, const SizedBox(height: 8), indicatorWidget],
        ),
      ),
    );
  }
}
