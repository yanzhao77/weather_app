import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/location_data.dart';

/// 多地区列表持久化：保存用户手动添加的所有天气地区
class LocationsDataSource {
  static const String _boxName = AppConstants.hiveBoxLocations;
  static const String _locationsKey = 'locations';
  static const String _currentIndexKey = 'current_index';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<LocationData> loadLocations() {
    final box = Hive.box(_boxName);
    final raw = box.get(_locationsKey) as List?;
    if (raw == null) return const [];
    try {
      return raw
          .map((e) => LocationData.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveLocations(List<LocationData> locations) async {
    final box = Hive.box(_boxName);
    await box.put(
      _locationsKey,
      locations.map((e) => e.toJson()).toList(),
    );
  }

  int loadCurrentIndex() {
    final box = Hive.box(_boxName);
    return box.get(_currentIndexKey) as int? ?? 0;
  }

  Future<void> saveCurrentIndex(int index) async {
    final box = Hive.box(_boxName);
    await box.put(_currentIndexKey, index);
  }
}
