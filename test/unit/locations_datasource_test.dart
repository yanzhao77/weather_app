import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nexus_weather/features/home/data/datasources/locations_datasource.dart';
import 'package:nexus_weather/features/home/domain/location_data.dart';
import 'package:nexus_weather/shared/widgets/weather_effect_overlay.dart';

void main() {
  late Directory tempDir;
  late LocationsDataSource ds;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_locations');
    Hive.init(tempDir.path);
    ds = LocationsDataSource();
    await ds.init();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  const beijing = LocationData(
      name: 'Beijing', latitude: 39.9042, longitude: 116.4074, country: 'CN');
  const shanghai = LocationData(
      name: 'Shanghai', latitude: 31.2304, longitude: 121.4737, country: 'CN');

  test('默认空列表，保存后可完整读回', () async {
    expect(ds.loadLocations(), isEmpty);
    await ds.saveLocations([beijing, shanghai]);
    final loaded = ds.loadLocations();
    expect(loaded.length, 2);
    expect(loaded.first.name, 'Beijing');
    expect(loaded.first.latitude, closeTo(39.9042, 1e-6));
  });

  test('当前索引默认 0，保存后读回', () async {
    expect(ds.loadCurrentIndex(), 0);
    await ds.saveCurrentIndex(1);
    expect(ds.loadCurrentIndex(), 1);
  });

  test('损坏数据返回空列表', () async {
    final box = Hive.box('saved_locations');
    await box.put('locations', ['not', 'a', 'map']);
    expect(ds.loadLocations(), isEmpty);
  });

  test('天气主状态映射到特效类型', () {
    expect(weatherEffectTypeFromMain('Thunderstorm'), WeatherEffectType.storm);
    expect(weatherEffectTypeFromMain('rain'), WeatherEffectType.rain);
    expect(weatherEffectTypeFromMain('drizzle'), WeatherEffectType.rain);
    expect(weatherEffectTypeFromMain('snow'), WeatherEffectType.snow);
    expect(weatherEffectTypeFromMain('mist'), WeatherEffectType.fog);
    expect(weatherEffectTypeFromMain('fog'), WeatherEffectType.fog);
    expect(weatherEffectTypeFromMain('haze'), WeatherEffectType.fog);
    expect(weatherEffectTypeFromMain('Clear'), WeatherEffectType.none);
    expect(weatherEffectTypeFromMain('Clouds'), WeatherEffectType.none);
    expect(weatherEffectTypeFromMain(null), WeatherEffectType.none);
  });
}
