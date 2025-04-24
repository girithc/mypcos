import 'package:flutter/material.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/components/period/period_calendar.dart';

class SecondaryActionCard extends StatelessWidget {
  const SecondaryActionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.iconsSrc = "assets/img/google.png",
    this.colorl = const Color(0xFF7553F6),
    this.trailingIcon,
    this.onTapCallback, // 👈 add this
  });

  final String title, iconsSrc;
  final Color colorl;
  final Widget? trailingIcon; // New optional icon widget
  final VoidCallback? onTapCallback; // 👈 declare callback
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return GestureDetector(
      onTap: onTapCallback,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02),
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color:
                            colorl == Colors.white
                                ? Colors.deepPurpleAccent
                                : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      this.subtitle ?? "Watch video - 15 mins",
                      style: TextStyle(
                        color:
                            colorl == Colors.white
                                ? Colors.deepPurple
                                : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailingIcon!,
            ],
          ),
        ),
      ),
    );
  }
}

class FileItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const FileItemCard({
    Key? key,
    required this.title,
    required this.subtitle,
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
            color: Colors.greenAccent.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2, // Allow up to 2 lines
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: IconButton(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit, size: 18, color: Colors.deepPurple),
                  tooltip: 'Edit file name',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
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
