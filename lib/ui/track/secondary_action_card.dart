import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

class SecondaryActionCard extends StatelessWidget {
  const SecondaryActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.colorl = const Color(0xFF7553F6),
    this.trailingIcon,
    this.onTapCallback,
  });

  final Widget title; // Now a Widget, not a String
  final Widget subtitle; // Now a Widget, not a String
  final Icon icon;
  final Color colorl;
  final Widget? trailingIcon;
  final VoidCallback? onTapCallback;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return GestureDetector(
      onTap: onTapCallback,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenHeight * 0.02,
          vertical: screenHeight * 0.01,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.04,
          ),
          decoration: BoxDecoration(
            color: colorl,
            borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.04)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title, // directly placing widget
                    const SizedBox(height: 4),
                    subtitle, // directly placing widget
                  ],
                ),
              ),
              const SizedBox(width: 12),

              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // Less round now
                ),
                child: icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FileItemCard extends StatelessWidget {
  final Widget titleWidget;
  final Widget subtitleWidget;
  final String
  imageUrl; // Currently unused, but keeping it if you plan to show image later
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const FileItemCard({
    Key? key,
    required this.titleWidget,
    required this.subtitleWidget,
    required this.imageUrl,
    required this.onTap,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenHeight * 0.02,
          vertical: screenHeight * 0.01,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.04,
          ),
          decoration: BoxDecoration(
            color: tertiaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 32, color: titleColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10), // Less round now
                ),
                child: IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, size: 18, color: iconColor),
                  tooltip: 'Edit file name',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
