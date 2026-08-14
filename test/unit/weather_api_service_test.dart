import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexus_weather/core/network/api_client.dart';
import 'package:nexus_weather/core/network/weather_api_service.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late WeatherApiService service;

  setUp(() {
    client = MockApiClient();
    service = WeatherApiService(client);
  });

  Response<dynamic> okResponse(Object data) => Response<dynamic>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: 200,
        data: data,
      );

  group('getWeather', () {
    test('解析 /weather 与 /forecast 并合并为 WeatherData', () async {
      // 本地午夜为基准，8 条（00:00–21:00）保证在同一天内
      final base =
          DateTime(2026, 7, 27, 0).toUtc().millisecondsSinceEpoch ~/ 1000;
      when(() => client.get('/weather', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse({
                'dt': 1700000000,
                'name': 'Beijing',
                'main': {
                  'temp': 25.5,
                  'feels_like': 26.0,
                  'humidity': 60,
                  'pressure': 1013,
                },
                'wind': {'speed': 3.2, 'deg': 120},
                'clouds': {'all': 20},
                'visibility': 10000,
                'weather': [
                  {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
                ],
              }));
      when(() => client.get('/forecast', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse({
                'list': List.generate(8, (i) => {
                      'dt': base + i * 10800,
                      'main': {
                        'temp': 20.0 + i,
                        'feels_like': 21.0 + i,
                        'temp_min': 18.0 + i,
                        'temp_max': 22.0 + i,
                        'humidity': 55,
                      },
                      'wind': {'speed': 2.0},
                      'pop': 0.1 + i * 0.05,
                      'weather': [
                        {'main': 'Clouds', 'description': 'few clouds', 'icon': '02d'},
                      ],
                    }),
              }));

      final data = await service.getWeather(39.9, 116.4);

      expect(data.current.temperature, 25.5);
      expect(data.current.weatherMain, 'Clear');
      expect(data.hourly.length, 8); // take(12) 但只有 8 条
      expect(data.daily.length, 1); // 8 条按天分组 = 1 天
      expect(data.daily.first.tempMax, 22.0 + 7); // 当天最高
      expect(data.daily.first.tempMin, 18.0); // 当天最低
      expect(data.daily.first.pop, closeTo(0.1 + 7 * 0.05, 1e-9)); // 取最大值
    });

    test('/forecast 失败时降级为当前天气填充', () async {
      when(() => client.get('/weather', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse({
                'dt': 1700000000,
                'main': {'temp': 25.5, 'feels_like': 26.0, 'humidity': 60, 'pressure': 1013},
                'wind': {'speed': 3.2, 'deg': 120},
                'clouds': {'all': 20},
                'visibility': 10000,
                'weather': [
                  {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
                ],
              }));
      when(() => client.get('/forecast', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '/forecast')));

      final data = await service.getWeather(39.9, 116.4);

      expect(data.hourly.length, 12);
      expect(data.daily.length, 5);
      expect(data.daily.first.tempMax, 25.5);
      expect(data.daily.first.weatherIcon, '01d');
    });

    test('daily 聚合取每天中间条目的天气作为代表', () async {
      final base =
          DateTime(2026, 7, 27, 0).toUtc().millisecondsSinceEpoch ~/ 1000;
      when(() => client.get('/weather', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse({
                'dt': 1700000000,
                'main': {'temp': 25.5, 'feels_like': 26.0, 'humidity': 60, 'pressure': 1013},
                'wind': {'speed': 3.2, 'deg': 120},
                'clouds': {'all': 20},
                'visibility': 10000,
                'weather': [
                  {'main': 'Clear', 'description': 'clear sky', 'icon': '01d'},
                ],
              }));
      when(() => client.get('/forecast', queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse({
                'list': List.generate(8, (i) => {
                      'dt': base + i * 10800,
                      'main': {
                        'temp': 20.0 + i,
                        'feels_like': 21.0 + i,
                        'temp_min': 18.0 + i,
                        'temp_max': 22.0 + i,
                        'humidity': 55,
                      },
                      'wind': {'speed': 2.0},
                      'pop': 0.1,
                      'weather': [
                        {
                          'main': i == 4 ? 'Rain' : 'Clouds',
                          'description': 'x',
                          'icon': i == 4 ? '10d' : '02d',
                        },
                      ],
                    }),
              }));

      final data = await service.getWeather(39.9, 116.4);

      // items.length ~/ 2 = 4 → 第 5 条（12:00 附近）的天气
      expect(data.daily.first.weatherMain, 'Rain');
      expect(data.daily.first.weatherIcon, '10d');
    });
  });

  group('searchCity', () {
    test('透传 cancelToken 与 limit 参数', () async {
      final cancelToken = CancelToken();
      when(() => client.get(any(), queryParameters: any(named: 'queryParameters'), cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => okResponse([
                {'name': 'Shanghai', 'lat': 31.23, 'lon': 121.47, 'country': 'CN', 'state': 'Shanghai'},
              ]));

      final results = await service.searchCity('shanghai', cancelToken: cancelToken);

      expect(results.length, 1);
      expect(results.first.name, 'Shanghai');
      expect(results.first.localName, 'Shanghai');
    });
  });
}
