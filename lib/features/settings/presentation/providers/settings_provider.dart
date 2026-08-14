import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/settings_datasource.dart';
import '../../domain/settings_data.dart';

final settingsDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) => SettingsLocalDataSource());

class SettingsNotifier extends StateNotifier<SettingsData> {
  final SettingsLocalDataSource _dataSource;

  SettingsNotifier(this._dataSource)
      : super(_dataSource.loadSettings());

  Future<void> updateSettings(SettingsData newSettings) async {
    state = newSettings;
    await _dataSource.saveSettings(newSettings);
  }

  Future<void> toggleCelsius() async {
    final updated = state.copyWith(useCelsius: !state.useCelsius);
    await updateSettings(updated);
  }

  Future<void> toggleKmh() async {
    final updated = state.copyWith(useKmh: !state.useKmh);
    await updateSettings(updated);
  }

  Future<void> toggle24Hour() async {
    final updated = state.copyWith(use24Hour: !state.use24Hour);
    await updateSettings(updated);
  }

  Future<void> toggleNotifications() async {
    final updated =
        state.copyWith(showNotifications: !state.showNotifications);
    await updateSettings(updated);
  }

  Future<void> setDefaultCity(String? city) async {
    final updated = state.copyWith(defaultCity: city);
    await updateSettings(updated);
  }

  /// 设置/清除 API Key（空值视为清除）
  Future<void> setApiKey(String? key) async {
    final trimmed = key?.trim() ?? '';
    final updated = SettingsData(
      useCelsius: state.useCelsius,
      useKmh: state.useKmh,
      use24Hour: state.use24Hour,
      showNotifications: state.showNotifications,
      defaultCity: state.defaultCity,
      apiKey: trimmed.isEmpty ? null : trimmed,
    );
    await updateSettings(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsData>((ref) {
  final ds = ref.read(settingsDataSourceProvider);
  return SettingsNotifier(ds);
});

/// 当前生效的 API Key：优先应用内设置，其次 --dart-define，最后 .env（开发）
/// 全部未配置时返回 null（App 会引导用户配置）
final apiKeyProvider = Provider<String?>((ref) {
  final saved = ref.watch(settingsProvider).apiKey;
  if (saved != null && saved.isNotEmpty) return saved;

  const defineKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  if (defineKey.isNotEmpty) return defineKey;

  try {
    final envKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) return envKey;
  } catch (_) {
    // dotenv 未初始化（release 包无 .env 资源）
  }

  return null;
});
