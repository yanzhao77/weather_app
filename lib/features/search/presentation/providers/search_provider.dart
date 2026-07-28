import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _repository.searchCity(query);
      state = SearchState(results: results, isLoading: false);
    } catch (e) {
      state = SearchState(error: '搜索失败: $e', isLoading: false);
    }
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
