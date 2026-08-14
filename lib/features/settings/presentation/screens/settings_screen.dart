import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/api_key_text_field.dart';
import '../../../../shared/widgets/section_header.dart';
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
          const SectionHeader(title: '单位', icon: Icons.straighten),
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
          const SectionHeader(title: '时间', icon: Icons.schedule),
          const SizedBox(height: 8),
          _SettingsTile(
            title: '24 小时制',
            subtitle: '使用 24 小时制显示时间',
            value: settings.use24Hour,
            onChanged: (_) =>
                ref.read(settingsProvider.notifier).toggle24Hour(),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: '通知', icon: Icons.notifications),
          const SizedBox(height: 8),
          _SettingsTile(
            title: '天气通知',
            subtitle: '每天 08:00 推送当日天气提醒',
            value: settings.showNotifications,
            onChanged: (_) async {
              final notifier = ref.read(settingsProvider.notifier);
              await notifier.toggleNotifications();
              if (ref.read(settingsProvider).showNotifications) {
                await NotificationService.requestPermissions();
                await NotificationService.scheduleDailyWeatherReminder();
              } else {
                await NotificationService.cancelDailyWeatherReminder();
              }
            },
          ),
          const SizedBox(height: 32),
          const SectionHeader(title: 'API Key', icon: Icons.key),
          const SizedBox(height: 8),
          _ApiKeyTile(
            apiKey: settings.apiKey,
            onTap: () => _showApiKeyDialog(context, ref),
          ),
          const SizedBox(height: 32),
          // About section
          const SectionHeader(title: '关于', icon: Icons.info_outline),
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
                  'v1.1.0',
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

  Future<void> _showApiKeyDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.accentCyan.withValues(alpha: 0.35)),
        ),
        title: const Text(
          '配置 API Key',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '密钥仅用于请求天气数据，掩码显示，不可复制；支持粘贴输入。',
              style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, height: 1.5, color: AppColors.textDim),
            ),
            const SizedBox(height: 12),
            ApiKeyTextField(
              controller: controller,
              hintText: '输入 API Key',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('清除', style: TextStyle(color: AppColors.accentPink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存', style: TextStyle(color: AppColors.accentCyan)),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null) return; // 取消
    await ref.read(settingsProvider.notifier).setApiKey(result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isEmpty ? '已清除 API Key' : 'API Key 已保存',
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11),
          ),
          backgroundColor: AppColors.accentCyan.withValues(alpha: 0.85),
        ),
      );
    }
  }

}

class _ApiKeyTile extends StatelessWidget {
  final String? apiKey;
  final VoidCallback onTap;

  const _ApiKeyTile({required this.apiKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final configured = apiKey != null && apiKey!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGlow, width: 0.2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.key,
          size: 18,
          color: configured ? AppColors.accentCyan : AppColors.textDim,
        ),
        title: const Text(
          'API Key',
          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          configured ? '已配置（掩码显示，不可复制，可粘贴输入）' : '未配置，点击设置',
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textDim),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: configured ? AppColors.accentCyan : AppColors.textDim,
        ),
      ),
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
