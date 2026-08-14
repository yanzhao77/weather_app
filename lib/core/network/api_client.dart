import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';
import '../error/app_exception.dart';

class ApiClient {
  /// 通过 --dart-define=OPENWEATHER_API_KEY=xxx 注入（编译期常量）
  static const String _dartDefineApiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY');

  late final Dio _dio;
  final String Function() _apiKeyResolver;

  ApiClient({Dio? dio, String Function()? apiKeyResolver})
      : _apiKeyResolver = apiKeyResolver ?? _defaultResolver {
    _dio = dio ?? Dio(_baseOptions());
    _dio.interceptors.add(_loggingInterceptor());
  }

  /// 默认解析：--dart-define 优先，其次 .env（开发环境）
  static String _defaultResolver() {
    if (_dartDefineApiKey.isNotEmpty) return _dartDefineApiKey;
    String? fromEnv;
    try {
      fromEnv = dotenv.env['OPENWEATHER_API_KEY'];
    } catch (_) {
      // dotenv 未初始化（release 包不含 .env 资源），安全降级
      fromEnv = null;
    }
    return fromEnv ?? AppConstants.defaultApiKey;
  }

  BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      queryParameters: {
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

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    // 每次请求动态解析 key：应用内设置可运行时生效，无需重新打包
    final apiKey = _apiKeyResolver();
    if (apiKey.isEmpty) {
      throw const ApiException(
        '未配置 API Key：请在应用「设置」中填写，或通过 --dart-define=OPENWEATHER_API_KEY=xxx 传入',
      );
    }
    return _dio.get(
      path,
      queryParameters: {...?queryParameters, 'appid': apiKey},
      cancelToken: cancelToken,
    );
  }

  Dio get dio => _dio;
}
