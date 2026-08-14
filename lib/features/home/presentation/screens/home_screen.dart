import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../providers/locations_provider.dart';
import '../../domain/location_data.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/scanline_overlay.dart';
import '../../../../shared/widgets/weather_effect_overlay.dart';
import '../widgets/current_weather_panel.dart';
import '../widgets/hourly_forecast_bar.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/detail_metrics_grid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _clockTimer;
  bool _loading = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 状态栏时钟每分钟刷新
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _pageController =
        PageController(initialPage: ref.read(locationsProvider).currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInitialLocation();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// 首次进入：已有地区直接加载（空名称补全）；空列表则尝试定位添加第一个地区
  Future<void> _ensureInitialLocation() async {
    final locations = ref.read(locationsProvider).locations;
    if (locations.isNotEmpty) {
      // 历史数据可能因之前反查失败而缺少名称，启动时逐个补全（不改坐标/索引）
      for (final loc in locations) {
        if (loc.name.isEmpty) {
          await _enrichLocationName(loc);
        }
      }
      await _loadWeatherForIndex(ref.read(locationsProvider).currentIndex);
      return;
    }

    // 空列表：尝试用定位添加首个地区
    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.requestLocation();
    final loc = ref.read(locationProvider).location;
    if (loc == null || !mounted) return; // 定位失败则停留在空状态页

    // 反查结果只取名称，坐标始终用定位坐标（reverse 可能返回不同坐标的行政区）
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
    _jumpToPage(index);
    await _loadWeatherForIndex(index);
  }

  void _jumpToPage(int index) {
    if (!mounted) return;
    ref.read(locationsProvider.notifier).setCurrentIndex(index);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  /// 反查坐标对应的城市名称并就地更新（只取名称，坐标保持原值，不改变索引）
  Future<void> _enrichLocationName(LocationData loc) async {
    try {
      final named = await ref
          .read(weatherRepositoryProvider)
          .reverseGeocode(loc.latitude, loc.longitude);
      if (named.name.isNotEmpty) {
        final notifier = ref.read(locationsProvider.notifier);
        final locations = ref.read(locationsProvider).locations;
        final idx = locations.indexWhere(
          (l) =>
              (l.latitude - loc.latitude).abs() < 0.001 &&
              (l.longitude - loc.longitude).abs() < 0.001,
        );
        if (idx >= 0) {
          notifier.updateName(idx, named);
        }
      }
    } catch (_) {
      // 反查失败保持现状，下次启动会再尝试
    }
  }

  Future<void> _loadWeatherForIndex(int index) async {
    final locations = ref.read(locationsProvider).locations;
    if (index < 0 || index >= locations.length) return;
    final loc = locations[index];
    await ref
        .read(weatherProvider(locationKey(loc.latitude, loc.longitude)).notifier)
        .fetchWeather(loc.latitude, loc.longitude);
  }

  Future<void> _onRefresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final index = ref.read(locationsProvider).currentIndex;
      final locations = ref.read(locationsProvider).locations;
      if (index < 0 || index >= locations.length) return;
      final loc = locations[index];
      await ref
          .read(weatherProvider(locationKey(loc.latitude, loc.longitude)).notifier)
          .fetchWeather(loc.latitude, loc.longitude, force: true);
    } finally {
      _loading = false;
    }
  }

  Future<void> _addLocation() async {
    await context.push('/search');
    // 返回后若新增了地区，跳转到新添加的那页
    final state = ref.read(locationsProvider);
    if (state.locations.isNotEmpty && mounted) {
      _jumpToPage(state.currentIndex);
      await _loadWeatherForIndex(state.currentIndex);
    }
  }

  Future<void> _removeCurrentLocation() async {
    final locations = ref.read(locationsProvider).locations;
    if (locations.length <= 1) return;
    final index = ref.read(locationsProvider).currentIndex;
    final name = locations[index].name.isEmpty ? '当前城市' : locations[index].name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.accentPink.withValues(alpha: 0.45)),
        ),
        title: const Text('删除地区',
            style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, color: AppColors.textPrimary)),
        content: Text('确定删除 $name 吗？',
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: AppColors.accentPink)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(locationsProvider.notifier);
    notifier.removeAt(index);
    final newIndex = ref.read(locationsProvider).currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationsState = ref.watch(locationsProvider);
    final locations = locationsState.locations;
    final currentIndex = locationsState.currentIndex;

    // 当前页地区与天气状态（决定背景渐变与天气特效）
    LocationData? currentLoc;
    WeatherState? currentWeatherState;
    if (locations.isNotEmpty && currentIndex < locations.length) {
      currentLoc = locations[currentIndex];
      currentWeatherState = ref.watch(
        weatherProvider(locationKey(currentLoc.latitude, currentLoc.longitude)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(currentWeatherState?.data?.current.weatherMain),
          const ParticleBackground(particleCount: 40),
          const ScanlineOverlay(),
          SafeArea(
            child: locations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.accentCyan,
                    backgroundColor: AppColors.bgSecondary,
                    child: _buildPageView(locations),
                  ),
          ),
          if (currentWeatherState?.data != null)
            WeatherEffectOverlay(
              weatherMain: currentWeatherState!.data!.current.weatherMain,
            ),
          if (locations.length > 1)
            _buildPageIndicator(locations.length, currentIndex),
          if (currentWeatherState != null &&
              currentWeatherState.isLoading &&
              currentWeatherState.data == null)
            _buildLoadingOverlay('INITIALIZING...'),
        ],
      ),
    );
  }

  Widget _buildPageView(List<LocationData> locations) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        ref.read(locationsProvider.notifier).setCurrentIndex(index);
        _loadWeatherForIndex(index);
      },
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        final ws = ref.watch(
          weatherProvider(locationKey(loc.latitude, loc.longitude)),
        );
        return _buildPageContent(loc, ws);
      },
    );
  }

  Widget _buildPageIndicator(int total, int current) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 10,
      child: IgnorePointer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final active = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: active ? AppColors.accentCyan : AppColors.textDim.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(String? weatherMain) {
    List<Color> gradientColors;
    switch (weatherMain?.toLowerCase()) {
      case 'clear': gradientColors = AppColors.sunnyGradient;
      case 'clouds': gradientColors = AppColors.cloudyGradient;
      case 'rain': case 'drizzle': gradientColors = AppColors.rainyGradient;
      case 'snow': gradientColors = AppColors.snowyGradient;
      case 'thunderstorm': gradientColors = AppColors.stormGradient;
      default: gradientColors = [AppColors.bgPrimary, AppColors.bgSecondary, AppColors.bgTertiary];
    }
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradientColors)),
    );
  }

  Widget _buildPageContent(LocationData loc, WeatherState weatherState) {
    if (weatherState.isLoading && weatherState.data == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 1.5));
    }
    if (weatherState.error != null && weatherState.data == null) {
      return _buildErrorState(weatherState.error!);
    }
    final data = weatherState.data;
    if (data == null) return _buildInitialState(loc);

    final displayName = loc.localName ?? loc.name;
    final cityName = displayName.isNotEmpty
        ? displayName
        : '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStatusBar(loc, weatherState),
          if (weatherState.error != null) ...[
            const SizedBox(height: 10),
            _buildInlineAlert(weatherState.error!),
          ],
          const SizedBox(height: 16),
          CurrentWeatherPanel(weather: data.current, cityName: cityName, isFromCache: weatherState.isFromCache),
          const SizedBox(height: 20),
          HourlyForecastBar(hourlyData: data.hourly),
          const SizedBox(height: 20),
          DetailMetricsGrid(weather: data.current),
          const SizedBox(height: 20),
          DailyForecastList(dailyData: data.daily),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusBar(LocationData loc, WeatherState weatherState) {
    final settings = ref.watch(settingsProvider);
    final canDelete = ref.watch(locationsProvider).locations.length > 1;
    final statusText = weatherState.isLoading
        ? '正在同步天气数据...'
        : ((loc.localName ?? loc.name).isNotEmpty
            ? (loc.localName ?? loc.name)
            : '未知位置');
    return Row(
      children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: weatherState.error != null ? AppColors.warning : AppColors.success,
            boxShadow: [BoxShadow(color: (weatherState.error != null ? AppColors.warning : AppColors.success).withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(statusText, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textSecondary))),
        if (weatherState.error != null && weatherState.data != null)
          Padding(padding: const EdgeInsets.only(right: 4), child: Text(weatherState.error!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8, color: AppColors.warning))),
        IconButton(
          tooltip: '添加地区',
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          onPressed: _addLocation,
          icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.accentCyan),
        ),
        IconButton(
          tooltip: '设置',
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          padding: EdgeInsets.zero,
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, size: 15, color: AppColors.textSecondary),
        ),
        if (canDelete)
          IconButton(
            tooltip: '删除当前地区',
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            onPressed: _removeCurrentLocation,
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.accentPink),
          ),
        const SizedBox(width: 4),
        Text(WeatherUtils.formatClock(DateTime.now(), use24Hour: settings.use24Hour), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppColors.textDim, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildInlineAlert(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '重新同步',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh, size: 16, color: AppColors.accentCyan),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(String label) {
    return Container(
      color: AppColors.bgPrimary.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 1.5),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: AppColors.accentCyan, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  /// 无任何地区时的引导页
  Widget _buildEmptyState() {
    final hasKey = ref.watch(apiKeyProvider)?.isNotEmpty ?? false;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.accentCyan,
      backgroundColor: AppColors.bgSecondary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.add_location_alt_outlined, size: 56, color: AppColors.accentCyanDim),
          const SizedBox(height: 20),
          const Center(
            child: Text('添加城市查看天气',
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, color: AppColors.textPrimary, letterSpacing: 1)),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('支持搜索城市，或使用当前位置',
                style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textDim)),
          ),
          const SizedBox(height: 28),
          Center(
            child: FilledButton.icon(
              onPressed: _addLocation,
              icon: const Icon(Icons.search, size: 16),
              label: const Text('搜索城市'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
                foregroundColor: AppColors.accentCyan,
                side: const BorderSide(color: AppColors.accentCyan, width: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _locateAndAdd,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('使用当前位置'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ),
          if (!hasKey) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.key, size: 16),
                label: const Text('配置 API Key'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 定位并添加到地区列表
  Future<void> _locateAndAdd() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.requestLocation();
    final locState = ref.read(locationProvider);
    final loc = locState.location;
    if (loc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locState.error ?? '获取定位失败',
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11)),
            backgroundColor: AppColors.warning.withValues(alpha: 0.9),
          ),
        );
      }
      return;
    }
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
    _jumpToPage(index);
    await _loadWeatherForIndex(index);
  }

  Widget _buildErrorState(String error) {
    final isApiKeyIssue = error.contains('API Key');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.accentPink),
            const SizedBox(height: 16),
            const Text('获取天气失败', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, color: AppColors.textPrimary, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textDim)),
            const SizedBox(height: 24),
            if (isApiKeyIssue) ...[
              FilledButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.key, size: 16),
                label: const Text('去设置 API Key'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentCyan.withValues(alpha: 0.15),
                  foregroundColor: AppColors.accentCyan,
                  side: const BorderSide(color: AppColors.accentCyan, width: 0.5),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
            ),
            TextButton.icon(
              onPressed: _addLocation,
              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
              label: const Text('添加城市'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(LocationData loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud, size: 48, color: AppColors.accentCyanDim),
          const SizedBox(height: 16),
          Text(
            loc.name.isNotEmpty ? '${loc.name} 天气加载中' : '加载天气数据',
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: TextButton.icon(
              onPressed: _onRefresh, icon: const Icon(Icons.refresh, color: AppColors.accentCyan),
              label: const Text('获取天气', style: TextStyle(color: AppColors.accentCyan)),
              style: TextButton.styleFrom(side: const BorderSide(color: AppColors.accentCyan, width: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
