# NEXUS WEATHER

> Futuristic HUD Weather App built with Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-2F80ED?style=flat-square)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-21C55D?style=flat-square)](#平台验证)

NEXUS WEATHER 是一款面向移动端的科幻风天气应用。它把实时天气、逐小时预报、未来多日趋势和定位状态组织成一套高密度 HUD 信息面板，用暗色背景、粒子层、扫描线、霓虹边框和动态渐变来呈现天气数据。

项目已经完成 Android 真机与 iOS 模拟器测试，当前版本聚焦手机竖屏体验。

## 预览

<table>
  <tr>
    <td align="center"><strong>Redmi K90 Pro Max</strong></td>
    <td align="center"><strong>iPhone 17 Simulator</strong></td>
  </tr>
  <tr>
    <td><img src="docs/%E7%BA%A2%E7%B1%B3k90%20pro%20max.jpg" alt="NEXUS WEATHER on Redmi K90 Pro Max" width="360"></td>
    <td><img src="docs/Simulator%20Screenshot%20-%20iPhone%2017%20-%202026-07-28%20at%2011.06.25.png" alt="NEXUS WEATHER on iPhone 17 Simulator" width="360"></td>
  </tr>
</table>

## 核心能力

- 当前位置天气：启动后请求定位权限，自动获取经纬度并反查城市名称。
- 实时天气面板：展示温度、体感温度、天气状态、湿度、风速、气压、能见度、日出日落等关键指标。
- 逐小时预报：横向信息条展示未来多个时间点的温度和天气趋势。
- 多日预报：聚合 OpenWeatherMap 5 day forecast 数据，生成日维度高低温和降水概率。
- 城市搜索：支持按城市名搜索，选择后立即切换天气数据源。
- 本地缓存：通过 Hive 保存最近一次天气结果，网络失败时继续显示缓存快照。
- 设置面板：提供温度单位、风速单位、时间格式和通知开关等偏好入口。
- 科幻 HUD 视觉：粒子背景、扫描线覆盖层、发光面板、自绘天气图标和天气态背景渐变。

## 技术栈

| 模块 | 技术 | 说明 |
| --- | --- | --- |
| App Framework | Flutter 3.x | 跨平台移动端 UI |
| Language | Dart 3 | 空安全与现代 Dart 语法 |
| State Management | Riverpod 2 | ProviderScope、StateNotifier、依赖注入 |
| Routing | go_router | 首页、搜索页、设置页路由与转场 |
| Network | Dio | OpenWeatherMap API 请求封装 |
| Location | geolocator, geocoding | 定位权限、当前位置、逆地理编码 |
| Local Storage | Hive | 天气缓存与用户设置持久化 |
| Charts / Visual | fl_chart, CustomPainter | HUD 数据视觉与天气图形组件 |
| Config | flutter_dotenv | 本地环境变量加载 |

## 项目结构

```text
lib/
├── app_router.dart                         # go_router 路由配置
├── main.dart                               # 应用入口、Hive、环境变量和本地化初始化
├── core/
│   ├── constants/                          # 颜色、常量、API endpoint
│   ├── error/                              # 网络异常统一处理
│   ├── network/                            # Dio client 与天气 API service
│   ├── theme/                              # 暗色 HUD 主题
│   └── utils/                              # 天气格式化与展示工具
├── features/
│   ├── home/                               # 当前天气、小时预报、多日预报
│   ├── search/                             # 城市搜索
│   └── settings/                           # 用户偏好设置
└── shared/widgets/                         # 粒子背景、扫描线、HUD 面板、天气图标
```

## 数据流

```text
HomeScreen / SearchScreen
        |
        v
Riverpod Notifier / Provider
        |
        v
WeatherRepository
        |
        +-- WeatherApiService -> OpenWeatherMap /weather, /forecast, /geo
        |
        +-- WeatherLocalDataSource -> Hive cache
```

应用优先请求远端天气数据，请求成功后写入 Hive。网络请求失败时，如果本地存在缓存，界面会保留缓存数据并提示同步失败；如果没有缓存，则展示错误状态和重试入口。

## 快速开始

### 1. 准备环境

- Flutter 3.x
- Dart 3.x
- Android Studio 或 Xcode
- OpenWeatherMap API Key

检查 Flutter 环境：

```bash
flutter doctor
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置环境变量

项目会尝试读取 `.env/.env`。复制示例文件，并填入你的 OpenWeatherMap key：

```bash
cp .env/.env.example .env/.env
```

### 4. 运行应用

```bash
flutter run
```

指定设备运行：

```bash
flutter devices
flutter run -d <device-id>
```

## 平台验证

当前截图验证设备：

| 平台 | 设备 | 状态 |
| --- | --- | --- |
| Android | Redmi K90 Pro Max | 已通过真机测试 |
| iOS | iPhone 17 Simulator | 已通过模拟器测试 |

更多测试记录见：

- [Android 数据线联调测试指南](docs/%E5%B0%8F%E7%B1%B315%20ADB%20%E6%95%B0%E6%8D%AE%E7%BA%BF%E8%81%94%E8%B0%83%E6%B5%8B%E8%AF%95%E6%8C%87%E5%8D%97.md)
- [iOS 模拟器测试指南](docs/iOS%20%E6%A8%A1%E6%8B%9F%E5%99%A8%E6%B5%8B%E8%AF%95%E6%8C%87%E5%8D%97.md)
- [技术开发文档](docs/%E6%8A%80%E6%9C%AF%E5%BC%80%E5%8F%91%E6%96%87%E6%A1%A3.md)

## 开发命令

```bash
# 获取依赖
flutter pub get

# 静态检查
flutter analyze

# 运行测试
flutter test

# Android debug 包
flutter build apk --debug

# iOS 构建检查
flutter build ios --debug --no-codesign
```

## 设计关键词

- Dark interface
- Futuristic HUD
- Neon cyan accent
- Particle background
- Scanline overlay
- Data-dense weather cards
- Mobile-first portrait layout

## License

This project is currently private / personal. Add a license before public distribution.
