import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weather_utils.dart';
import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/scanline_overlay.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeather();
    });
  }

  Future<void> _loadWeather() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.requestLocation();

    final locationState = ref.read(locationProvider);
    if (locationState.error != null) {
      await _showLocationIssueDialog(locationState);
      return;
    }

    final loc = locationState.location;
    if (loc != null) {
      await ref.read(weatherProvider.notifier).fetchWeather(loc.latitude, loc.longitude);

      if (ref.read(weatherProvider).data != null) {
        try {
          final repo = ref.read(weatherRepositoryProvider);
          final namedLoc = await repo.reverseGeocode(loc.latitude, loc.longitude);
          locationNotifier.setLocation(namedLoc);
        } catch (_) {}
      }
    } else {
      await _showLocationIssueDialog(
        const LocationState(error: '未获取到手机定位，请确认定位开关与应用权限已开启'),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherProvider);
    final locationState = ref.watch(locationProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(weatherState.data?.current.weatherMain),
          const ParticleBackground(particleCount: 40),
          const ScanlineOverlay(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.accentCyan,
              backgroundColor: AppColors.bgSecondary,
              child: _buildContent(weatherState, locationState),
            ),
          ),
          if ((weatherState.isLoading || locationState.isLoading) && weatherState.data == null)
            _buildLoadingOverlay(locationState.isLoading ? 'LOCATING...' : 'INITIALIZING...'),
        ],
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

  Widget _buildContent(WeatherState weatherState, LocationState locationState) {
    if (weatherState.isLoading && weatherState.data == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 1.5));
    }
    if (locationState.error != null && locationState.location == null && weatherState.data == null) {
      return _buildLocationErrorState(locationState);
    }
    if (weatherState.error != null && weatherState.data == null) {
      return _buildErrorState(weatherState.error!);
    }
    final data = weatherState.data;
    if (data == null) return _buildInitialState();

    final loc = locationState.location;
    final cityName = (loc != null && loc.name.isNotEmpty)
        ? loc.name
        : (loc != null ? '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}' : '未知');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildStatusBar(locationState, weatherState),
          if (locationState.error != null || weatherState.error != null) ...[
            const SizedBox(height: 10),
            _buildInlineAlert(locationState, weatherState),
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

  Widget _buildStatusBar(LocationState locationState, WeatherState weatherState) {
    final loc = locationState.location;
    final statusText = locationState.isLoading
        ? '正在获取手机定位...'
        : (weatherState.isLoading
            ? '正在同步天气数据...'
            : (locationState.error ?? ((loc != null && loc.name.isNotEmpty) ? loc.name : '定位完成')));
    return Row(
      children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (locationState.error != null || weatherState.error != null) ? AppColors.warning : AppColors.success,
            boxShadow: [BoxShadow(color: ((locationState.error != null || weatherState.error != null) ? AppColors.warning : AppColors.success).withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(statusText, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textSecondary))),
        if (weatherState.error != null && weatherState.data != null)
          Padding(padding: const EdgeInsets.only(right: 4), child: Text(weatherState.error!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8, color: AppColors.warning))),
        Text(WeatherUtils.formatTime(DateTime.now()), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppColors.textDim, letterSpacing: 1)),
      ],
    );
  }

  Future<void> _showLocationIssueDialog(LocationState locationState) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.warning.withValues(alpha: 0.45)),
        ),
        title: const Text(
          '需要获取位置信息',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, color: AppColors.textPrimary),
        ),
        content: Text(
          locationState.error ?? '请允许定位权限，并确认手机定位服务已开启。',
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (locationState.permissionDenied) {
                await Geolocator.openAppSettings();
              } else {
                await Geolocator.openLocationSettings();
              }
            },
            child: const Text('去开启'),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineAlert(LocationState locationState, WeatherState weatherState) {
    final message = locationState.error ?? weatherState.error ?? '';
    final isLocationIssue = locationState.error != null;
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
          Icon(isLocationIssue ? Icons.location_off : Icons.cloud_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isLocationIssue ? '定位设置' : '重新同步',
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            onPressed: isLocationIssue
                ? () async {
                    if (locationState.permissionDenied) {
                      await Geolocator.openAppSettings();
                    } else {
                      await Geolocator.openLocationSettings();
                    }
                  }
                : _onRefresh,
            icon: Icon(isLocationIssue ? Icons.settings : Icons.refresh, size: 16, color: AppColors.accentCyan),
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

  Widget _buildLocationErrorState(LocationState locationState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            const Text('需要定位权限', style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, color: AppColors.textPrimary, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(
              locationState.error ?? '请允许定位权限后重新获取天气数据',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.textDim),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('重新请求定位'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan),
            ),
            TextButton.icon(
              onPressed: () async {
                if (locationState.permissionDenied) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
              },
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('打开定位设置'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
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
            TextButton.icon(onPressed: _onRefresh, icon: const Icon(Icons.refresh, size: 16), label: const Text('重试'), style: TextButton.styleFrom(foregroundColor: AppColors.accentCyan)),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud, size: 48, color: AppColors.accentCyanDim),
          const SizedBox(height: 16),
          const Text('点击按钮获取天气数据', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.textSecondary)),
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
