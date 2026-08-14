import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/app_exception.dart';
import '../../../home/domain/location_data.dart';
import '../../../home/domain/repositories/weather_repository.dart';
import '../../../home/presentation/providers/weather_provider.dart';

class SearchState {
  final List<LocationData> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    List<LocationData>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final WeatherRepository _repository;
  CancelToken? _activeCancelToken;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query, {CancelToken? cancelToken}) async {
    if (query.trim().isEmpty) {
      _activeCancelToken?.cancel();
      _activeCancelToken = null;
      state = const SearchState();
      return;
    }
    // 取消上一次未完成的搜索，避免过期结果覆盖新结果
    _activeCancelToken?.cancel();
    final token = cancelToken ?? CancelToken();
    _activeCancelToken = token;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.searchCity(query, cancelToken: token);
      if (token.isCancelled) return;
      state = SearchState(results: results, isLoading: false);
    } catch (e) {
      if (token.isCancelled) return;
      final message = e is AppException ? e.message : '未知错误';
      state = SearchState(error: '搜索失败：$message', isLoading: false);
    }
  }

  void cancelActiveSearch() {
    _activeCancelToken?.cancel();
    _activeCancelToken = null;
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repo = ref.read(weatherRepositoryProvider);
  return SearchNotifier(repo);
});
