import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('单位'),
          const SizedBox(height: 8),
          _SettingsTile(
            title: '摄氏度 (°C)',
            subtitle: '使用摄氏度显示温度',
            value: settings.useCelsius,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleCelsius(),
          ),
          _SettingsTile(
            title: '公里/小时 (km/h)',
            subtitle: '使用公制速度单位',
            value: settings.useKmh,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleKmh(),
          ),
          const SizedBox(height: 24),
          _sectionHeader('时间'),
          const SizedBox(height: 8),
          _SettingsTile(
            title: '24 小时制',
            subtitle: '使用 24 小时制显示时间',
            value: settings.use24Hour,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggle24Hour(),
          ),
          const SizedBox(height: 24),
          _sectionHeader('通知'),
          const SizedBox(height: 8),
          _SettingsTile(
            title: '天气通知',
            subtitle: '接收每日天气预报推送',
            value: settings.showNotifications,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggleNotifications(),
          ),
          const SizedBox(height: 32),
          // About section
          _sectionHeader('关于'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGlow, width: 0.3),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXUS WEATHER',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentCyan,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '数据来源: OpenWeatherMap',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          color: AppColors.accentCyan,
        ),
        const SizedBox(width: 8),
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
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGlow, width: 0.2),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
            color: AppColors.textDim,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentCyan,
        activeTrackColor: AppColors.accentCyanDim,
        inactiveThumbColor: AppColors.textDim,
        inactiveTrackColor: AppColors.bgPanel,
      ),
    );
  }
}
