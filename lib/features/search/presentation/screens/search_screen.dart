import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/search_provider.dart';
import '../../../home/domain/location_data.dart';
import '../../../home/presentation/providers/location_provider.dart';
import '../../../home/presentation/providers/weather_provider.dart';
import '../../../home/presentation/providers/locations_provider.dart';

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

  Future<void> _useCurrentLocation() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.requestLocation();
    final loc = ref.read(locationProvider).location;
    if (loc == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('获取定位失败，请检查定位权限',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11)),
            backgroundColor: AppColors.warning.withValues(alpha: 0.9),
          ),
        );
      }
      return;
    }
    // 反查结果只取名称，坐标始终用定位坐标
    LocationData named = loc;
    try {
      final geo = await ref
          .read(weatherRepositoryProvider)
          .reverseGeocode(loc.latitude, loc.longitude);
      named = LocationData(
        name: geo.name,
        latitude: loc.latitude,
        longitude: loc.longitude,
        country: geo.country,
        adminArea: geo.adminArea,
        localName: geo.localName,
      );
    } catch (_) {}
    final index = ref.read(locationsProvider.notifier).add(named);
    ref
        .read(weatherProvider(
                locationKey(named.latitude, named.longitude))
            .notifier)
        .fetchWeather(named.latitude, named.longitude);
    if (mounted) Navigator.pop(context, index);
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
                decoration: InputDecoration(
                  hintText: '输入城市名称...',
                  hintStyle: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, color: AppColors.textDim),
                  prefixIcon: const Icon(Icons.search, color: AppColors.accentCyan, size: 18),
                  suffixIcon: IconButton(
                    tooltip: '使用当前位置',
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location, color: AppColors.accentCyan, size: 16),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            // 添加到地区列表，首页会自动跳转到新地区
            final index =
                ref.read(locationsProvider.notifier).add(location);
            ref
                .read(weatherProvider(
                        locationKey(location.latitude, location.longitude))
                    .notifier)
                .fetchWeather(location.latitude, location.longitude);
            Navigator.pop(context, index);
          },
        );
      },
    );
  }
}
