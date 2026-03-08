import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.ink,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.inkSoft,
    height: 1.5,
  );

  static const TextStyle bodyXs = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
    height: 1.4,
  );

  static const TextStyle shellTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.inkSoft,
    letterSpacing: 1.2,
    height: 1.0,
  );

  static const TextStyle shellAction = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.gold,
    height: 1.0,
  );

  static const TextStyle eyebrow = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
    letterSpacing: 1.1,
    height: 1.1,
  );

  static const TextStyle panelTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.25,
  );

  static const TextStyle panelTitleOnDark = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.25,
  );

  static const TextStyle heroTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.2,
  );

  // Buttons & CTAs
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.0,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.0,
  );
}
