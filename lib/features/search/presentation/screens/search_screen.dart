import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/search_provider.dart';
import '../../../home/presentation/providers/location_provider.dart';
import '../../../home/presentation/providers/weather_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    ref.read(searchProvider.notifier).cancelActiveSearch();
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    // 300ms 防抖：停止输入后才发起请求
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索城市', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, letterSpacing: 1)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderGlow, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onSearch,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: '输入城市名称...',
                  hintStyle: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, color: AppColors.textDim),
                  prefixIcon: Icon(Icons.search, color: AppColors.accentCyan, size: 18),
                  suffixIcon: Icon(Icons.my_location, color: AppColors.textDim, size: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 1.5));
    }

    if (searchState.results.isEmpty) {
      return const Center(
        child: Text('输入城市名开始搜索', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textDim)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: searchState.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final location = searchState.results[index];
        return ListTile(
          leading: const Icon(Icons.location_city, color: AppColors.accentCyan, size: 18),
          title: Text(
            location.localName ?? location.name,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            location.displayName,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textDim),
          ),
          onTap: () {
            ref.read(locationProvider.notifier).setLocation(location);
            ref.read(weatherProvider.notifier).fetchWeather(
                  location.latitude,
                  location.longitude,
                );
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
