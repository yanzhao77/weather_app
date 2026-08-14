import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 科幻风格的小节标题（竖条 + 图标 + 大写标题）
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showBar;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.showBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          if (showBar) ...[
            Container(width: 2, height: 14, color: AppColors.accentCyan),
            const SizedBox(width: 8),
          ],
          Icon(icon, size: 12, color: AppColors.accentCyan),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: AppColors.accentCyan,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
