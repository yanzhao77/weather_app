import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';
import 'features/home/data/datasources/weather_local_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgSecondary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Orientation lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  await initializeDateFormatting('zh_CN');

  // Initialize local data source (opens boxes)
  final localDS = WeatherLocalDataSource();
  await localDS.init();

  // Load environment variables (optional)
  try {
    await dotenv.load(fileName: '.env/.env');
  } catch (_) {
    // .env file may not exist, continue with defaults
  }

  runApp(
    const ProviderScope(
      child: NexusWeatherApp(),
    ),
  );
}

class NexusWeatherApp extends StatelessWidget {
  const NexusWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nexus Weather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
