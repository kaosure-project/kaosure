import 'package:flutter/material.dart';
import 'package:kaosure/shared/design_system/colors/app_colors.dart';

/// Initial-letter badge for an app. Remote logos are not loaded, so a client's
/// registration cannot make Kao ID fetch third-party images.
class SsoAppAvatar extends StatelessWidget {
  const SsoAppAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.kaoBlueSoft, borderRadius: BorderRadius.circular(size / 4)),
      child: Text(initial, style: TextStyle(
        fontSize: size * 0.42, fontWeight: FontWeight.w700, color: AppColors.kaoBlue)),
    );
  }
}
