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
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsData>((ref) {
  final ds = ref.read(settingsDataSourceProvider);
  return SettingsNotifier(ds);
});
