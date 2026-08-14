import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/api_key_text_field.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/scanline_overlay.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// 启动引导页：未配置 API Key 时出现，应用内配置密钥（不可见、不可复制）
class ApiKeySetupScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSkip;

  const ApiKeySetupScreen({super.key, this.onSkip});

  @override
  ConsumerState<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends ConsumerState<ApiKeySetupScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = '请输入 API Key');
      return;
    }
    setState(() => _error = null);
    await ref.read(settingsProvider.notifier).setApiKey(key);
    // apiKeyProvider 更新后，NexusWeatherApp 会自动切换到主界面
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ParticleBackground(particleCount: 30),
          const ScanlineOverlay(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.accentCyan, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentCyan.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.key, size: 30, color: AppColors.accentCyan),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'API KEY 配置',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '本应用需要 OpenWeatherMap API Key 才能获取天气数据。\n可在下方输入，或稍后在「设置」中配置。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderGlow, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: ApiKeyTextField(
                          controller: _controller,
                          hintText: '输入 OpenWeatherMap API Key',
                          errorText: _error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
                          foregroundColor: AppColors.accentCyan,
                          side: const BorderSide(color: AppColors.accentCyan, width: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '保存并进入',
                          style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onSkip,
                      child: const Text(
                        '跳过，稍后设置',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
