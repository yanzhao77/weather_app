import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, {this.statusCode});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});
}

class ApiException extends AppException {
  const ApiException(super.message, {super.statusCode});
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class LocationException extends AppException {
  const LocationException(super.message);
}

AppException handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkException('连接超时，请检查网络');
    case DioExceptionType.connectionError:
      return const NetworkException('网络连接失败');
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode ?? 0;
      final message = _parseErrorMessage(e.response?.data);
      return ApiException(message, statusCode: statusCode);
    case DioExceptionType.cancel:
      return const NetworkException('请求已取消');
    default:
      return const NetworkException('未知网络错误');
  }
}

String _parseErrorMessage(dynamic data) {
  if (data is Map && data.containsKey('message')) {
    return data['message'].toString();
  }
  return '服务器返回错误';
}
