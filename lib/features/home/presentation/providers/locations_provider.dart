import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/locations_datasource.dart';
import '../../domain/location_data.dart';

class LocationsState {
  final List<LocationData> locations;
  final int currentIndex;

  const LocationsState({this.locations = const [], this.currentIndex = 0});

  LocationsState copyWith({
    List<LocationData>? locations,
    int? currentIndex,
  }) {
    return LocationsState(
      locations: locations ?? this.locations,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class LocationsNotifier extends StateNotifier<LocationsState> {
  final LocationsDataSource _dataSource;

  LocationsNotifier(this._dataSource)
      : super(LocationsState(
          locations: _dataSource.loadLocations(),
          currentIndex: _dataSource.loadCurrentIndex(),
        ));

  /// 添加地区（同经纬度去重），添加后自动切换到该地区，返回其索引
  int add(LocationData location) {
    final exists = state.locations.indexWhere(
      (l) =>
          (l.latitude - location.latitude).abs() < 0.001 &&
          (l.longitude - location.longitude).abs() < 0.001,
    );
    final List<LocationData> updated = [...state.locations];
    if (exists >= 0) {
      // 已存在：仅更新名称信息，仍返回其索引
      updated[exists] = location;
      _persist(updated, currentIndex: exists);
      return exists;
    }
    updated.add(location);
    final newIndex = updated.length - 1;
    _persist(updated, currentIndex: newIndex);
    return newIndex;
  }

  /// 仅更新指定地区的名称信息（保留坐标），不改变当前索引
  void updateName(int index, LocationData location) {
    if (index < 0 || index >= state.locations.length) return;
    final current = state.locations[index];
    final updated = [...state.locations];
    updated[index] = LocationData(
      name: location.name,
      latitude: current.latitude,
      longitude: current.longitude,
      country: location.country,
      adminArea: location.adminArea,
      localName: location.localName,
    );
    _persist(updated);
  }

  /// 移除指定索引的地区
  void removeAt(int index) {
    if (state.locations.isEmpty || index < 0 || index >= state.locations.length) {
      return;
    }
    final updated = [...state.locations]..removeAt(index);
    var newIndex = state.currentIndex;
    if (state.currentIndex >= updated.length) {
      newIndex = updated.isEmpty ? 0 : updated.length - 1;
    } else if (index < state.currentIndex) {
      newIndex = state.currentIndex - 1;
    }
    _persist(updated, currentIndex: newIndex);
    state = LocationsState(locations: updated, currentIndex: newIndex);
  }

  void setCurrentIndex(int index) {
    if (index < 0 || index >= state.locations.length) return;
    state = state.copyWith(currentIndex: index);
    _dataSource.saveCurrentIndex(index);
  }

  void _persist(List<LocationData> locations, {int? currentIndex}) {
    _dataSource.saveLocations(locations);
    if (currentIndex != null) {
      _dataSource.saveCurrentIndex(currentIndex);
    }
    state = LocationsState(
      locations: locations,
      currentIndex: currentIndex ?? state.currentIndex,
    );
  }
}

final locationsDataSourceProvider =
    Provider<LocationsDataSource>((ref) => LocationsDataSource());

final locationsProvider =
    StateNotifierProvider<LocationsNotifier, LocationsState>((ref) {
  return LocationsNotifier(ref.read(locationsDataSourceProvider));
});
