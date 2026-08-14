import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/settings_data.dart';

class SettingsLocalDataSource {
  static const String _boxName = AppConstants.hiveBoxSettings;
  static const String _key = 'settings';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  SettingsData loadSettings() {
    final box = Hive.box(_boxName);
    final data = box.get(_key);
    if (data == null) return const SettingsData();
    try {
      return SettingsData.fromJson(
          Map<String, dynamic>.from(data as Map));
    } catch (_) {
      return const SettingsData();
    }
  }

  Future<void> saveSettings(SettingsData settings) async {
    final box = Hive.box(_boxName);
    await box.put(_key, settings.toJson());
  }
}
