import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/services/url_launcher_service.dart';
import '../constants/app_colors.dart';

class SocialMediaLinks extends StatelessWidget {
  final double? iconSize;
  final Color? iconColor;
  final bool showLabels;
  final MainAxisAlignment alignment;

  const SocialMediaLinks({
    super.key,
    this.iconSize,
    this.iconColor,
    this.showLabels = false,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        _SocialMediaButton(
          icon: Icons.facebook,
          label: 'Facebook',
          onTap: () => UrlLauncherService.openFacebook(),
          iconSize: iconSize,
          iconColor: iconColor,
          showLabel: showLabels,
        ),
        SizedBox(width: 16.w),
        _SocialMediaButton(
          icon: Icons.camera_alt, // Instagram icon alternative
          label: 'Instagram',
          onTap: () => UrlLauncherService.openInstagram(),
          iconSize: iconSize,
          iconColor: iconColor,
          showLabel: showLabels,
        ),
        SizedBox(width: 16.w),
        _SocialMediaButton(
          icon: Icons.contact_mail,
          label: 'Contact',
          onTap: () => UrlLauncherService.openContactPage(),
          iconSize: iconSize,
          iconColor: iconColor,
          showLabel: showLabels,
        ),
      ],
    );
  }
}

class _SocialMediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? iconSize;
  final Color? iconColor;
  final bool showLabel;

  const _SocialMediaButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize,
    this.iconColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize ?? 24.sp,
              color: iconColor ?? AppColors.primary,
            ),
            if (showLabel) ...[
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ContactButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const ContactButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: iconColor ?? Colors.white, size: 20.sp),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: iconColor ?? Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
