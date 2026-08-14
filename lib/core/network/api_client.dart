import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../error/app_exception.dart';

class ApiClient {
  /// 通过 --dart-define=OPENWEATHER_API_KEY=xxx 注入（编译期常量）
  static const String _dartDefineApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

  late final Dio _dio;
  final String _apiKey;

  ApiClient({Dio? dio}) : _apiKey = _resolveApiKey() {
    _dio = dio ?? Dio(_baseOptions());
    _dio.interceptors.add(_loggingInterceptor());
  }

  static String _resolveApiKey() {
    final fromEnv = dotenv.env['OPENWEATHER_API_KEY'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (_dartDefineApiKey.isNotEmpty) return _dartDefineApiKey;
    return AppConstants.defaultApiKey;
  }

  BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      queryParameters: {
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'zh_cn',
      },
    );
  }

  InterceptorsWrapper _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('[DIO] → ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          final duration = response.extra['elapsed'] as Duration?;
          debugPrint('[DIO] ← ${response.statusCode} ${response.requestOptions.uri.path}'
              '${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[DIO] ✗ ${error.type} ${error.message}');
        }
        handler.next(error);
      },
    );
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw const ApiException(
        '未配置 API Key：请通过 --dart-define=OPENWEATHER_API_KEY=xxx 传入',
      );
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    _ensureApiKey();
    return _dio.get(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  Dio get dio => _dio;
}
