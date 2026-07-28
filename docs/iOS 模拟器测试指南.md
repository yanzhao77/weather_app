# Mac mini M4 下 Flutter iOS Simulator 开发测试技术文档

> 适用环境：Mac mini M4（Apple Silicon）、macOS 15 / macOS 26、Flutter 3.x、Xcode、iOS Simulator、CocoaPods  
> 目标：在没有 iPhone 真机的情况下，使用 Xcode iOS Simulator 完成 Flutter App 的 iOS 端开发、调试和基础验证。  
> 示例项目路径：`weather_app/`

---

## 1. 文档目标与适用边界

### 1.1 目标

本文档用于指导开发者在 Mac mini M4 上搭建并使用 iOS Simulator 测试 Flutter iOS 应用，覆盖以下内容：

- 安装与校验 Flutter、Xcode、iOS Simulator、CocoaPods。
- 在没有 iPhone 真机的情况下运行 Flutter iOS App。
- 使用 Flutter CLI 与 Xcode 两种方式启动模拟器。
- 处理 Apple Silicon 环境下常见的 CocoaPods、架构、缓存、签名和模拟器问题。
- 建立日常开发、调试、清理、回归测试流程。

### 1.2 能做什么

iOS Simulator 可以完成大部分 iOS 端开发测试：

- UI 布局、适配、深浅色模式、横竖屏测试。
- Flutter 热重载、热重启、断点调试。
- 网络请求、接口联调、基础权限弹窗验证。
- 本地存储、路由跳转、状态管理验证。
- 多设备尺寸测试，例如 iPhone SE、iPhone 15、iPhone 15 Pro Max、iPad。
- Debug / Profile 模式运行和基础性能观察。

### 1.3 不能完全替代真机的部分

没有 iPhone 真机时，需要明确 Simulator 的边界：

| 能力 | Simulator 支持情况 | 说明 |
|------|-------------------|------|
| App UI 测试 | 支持 | 最常用、最稳定 |
| 网络请求 | 支持 | 与 Mac 共享网络环境 |
| 定位 | 部分支持 | 可通过模拟器菜单设置位置 |
| 相机 | 不等价 | 不能完整模拟真实摄像头行为 |
| 推送通知 | 部分支持 | 本地通知可测，远程推送需要额外配置 |
| 蓝牙 / NFC | 不支持或极弱 | 必须真机测试 |
| 传感器 | 部分模拟 | 陀螺仪、加速度等不等价 |
| 性能 | 仅供参考 | Simulator 性能不代表真实 iPhone |
| App Store 上架前验证 | 不充分 | 上架前仍建议真机回归 |

---

## 2. 推荐目录与项目结构

假设 Flutter 项目位于：

```bash
/Users/sjw/Documents/New project/weather_app
```

典型 Flutter iOS 相关目录：

```text
weather_app/
├── lib/                         # Flutter Dart 代码
├── ios/
│   ├── Runner.xcworkspace        # CocoaPods 集成后应打开的 Xcode Workspace
│   ├── Runner.xcodeproj          # 原始 Xcode Project，不建议用于 Pods 项目运行
│   ├── Podfile                   # CocoaPods 配置
│   ├── Podfile.lock              # Pods 依赖锁定文件
│   ├── Pods/                     # CocoaPods 安装后的依赖目录
│   ├── Flutter/
│   │   ├── Debug.xcconfig
│   │   ├── Release.xcconfig
│   │   └── Generated.xcconfig    # flutter pub get 后生成
│   └── Runner/                   # iOS 原生入口、Info.plist、Assets
├── pubspec.yaml                  # Flutter 依赖配置
└── pubspec.lock                  # Flutter 依赖锁定文件
```

重要原则：

- 使用 Xcode 打开 iOS 工程时，优先打开 `ios/Runner.xcworkspace`。
- 不要直接打开 `ios/Runner.xcodeproj` 来运行带 CocoaPods 依赖的 Flutter 项目。
- 日常运行优先使用 `flutter run`，需要原生配置、签名、Pod 排障时再使用 Xcode。

---

## 3. 基础环境安装

### 3.1 安装 Xcode

从 Mac App Store 安装 Xcode，或使用 Apple Developer 官网下载。

安装完成后执行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

确认 Xcode 路径：

```bash
xcode-select -p
```

期望输出类似：

```text
/Applications/Xcode.app/Contents/Developer
```

查看 Xcode 版本：

```bash
xcodebuild -version
```

### 3.2 安装 iOS Simulator Runtime

打开 Xcode：

```text
Xcode -> Settings -> Platforms
```

安装需要的 iOS Simulator Runtime，例如：

- iOS 18.x Simulator Runtime
- iOS 19.x Simulator Runtime（如 Xcode 版本支持）

安装完成后查看可用模拟器：

```bash
xcrun simctl list devices available
```

### 3.3 安装 Flutter 3.x

确认 Flutter 已安装并位于 PATH 中：

```bash
flutter --version
```

建议使用 Stable 渠道：

```bash
flutter channel stable
flutter upgrade
```

在已有团队项目中，如果项目锁定了 Flutter 版本，优先使用团队约定版本，不要随意升级全局 Flutter。

### 3.4 安装 CocoaPods

Apple Silicon 下推荐使用 Homebrew 安装 CocoaPods：

```bash
brew install cocoapods
pod --version
```

如果项目历史上使用 RubyGems 安装 CocoaPods，也可以使用：

```bash
sudo gem install cocoapods
```

但在 Apple Silicon + 新版 macOS 下，Homebrew 方式通常更少遇到 Ruby 环境冲突。

### 3.5 安装 Rosetta 2（可选但建议）

Flutter 与现代 CocoaPods 通常可以原生运行在 arm64 下，但部分旧 Pod、旧脚本或二进制依赖可能仍需要 Rosetta。

安装命令：

```bash
softwareupdate --install-rosetta --agree-to-license
```

---

## 4. 环境健康检查

进入项目目录：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
```

执行：

```bash
flutter doctor -v
```

重点检查以下项：

| 检查项 | 期望状态 | 说明 |
|--------|----------|------|
| Flutter | `[✓]` | Flutter SDK 可用 |
| Xcode | `[✓]` | Xcode、iOS toolchain 可用 |
| CocoaPods | `[✓]` | iOS 插件依赖可安装 |
| Connected device | 有 iOS Simulator | 至少能识别一个模拟器 |

如果 `flutter doctor` 提示 Xcode license 未接受：

```bash
sudo xcodebuild -license accept
```

如果提示 CocoaPods 未安装或不可用：

```bash
brew install cocoapods
pod setup
```

---

## 5. 首次运行前准备

### 5.1 拉取 Flutter 依赖

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter pub get
```

此命令会生成或更新：

- `.dart_tool/`
- `ios/Flutter/Generated.xcconfig`
- `ios/Flutter/flutter_export_environment.sh`
- `pubspec.lock`

### 5.2 安装 iOS Pods

通常 `flutter run` 会自动触发 Pod 安装，但首次运行建议手动执行一次：

```bash
cd "/Users/sjw/Documents/New project/weather_app/ios"
pod install
```

如果项目使用 Apple Silicon，正常情况下不要强制 `arch -x86_64 pod install`。只有旧依赖明确不支持 arm64 模拟器时，才考虑 Rosetta 方案。

### 5.3 检查 Podfile 平台版本

打开 `ios/Podfile`，建议设置一个现代 iOS 最低版本，例如：

```ruby
platform :ios, '13.0'
```

如果某些 Flutter 插件要求更高版本，按插件要求调整，例如 `14.0` 或 `15.0`。

调整后重新安装 Pods：

```bash
cd ios
pod install
```

---

## 6. 启动与管理 iOS Simulator

### 6.1 查看可用设备

```bash
flutter devices
```

输出中应看到类似：

```text
iPhone 15 Pro (mobile) • XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX • ios • com.apple.CoreSimulator.SimRuntime.iOS-18-x
```

也可以使用 Xcode 工具查看：

```bash
xcrun simctl list devices available
```

### 6.2 打开 Simulator App

```bash
open -a Simulator
```

如果需要从 Xcode UI 打开：

```text
Xcode -> Open Developer Tool -> Simulator
```

### 6.3 启动指定模拟器

查看设备 ID：

```bash
xcrun simctl list devices available
```

启动指定设备：

```bash
xcrun simctl boot <device-udid>
open -a Simulator
```

如果设备已启动，`boot` 命令可能提示 already booted，这是正常情况。

### 6.4 创建新的模拟器设备

先查看设备类型与 Runtime：

```bash
xcrun simctl list devicetypes
xcrun simctl list runtimes
```

创建示例：

```bash
xcrun simctl create "iPhone 15 Test" \
  "com.apple.CoreSimulator.SimDeviceType.iPhone-15" \
  "com.apple.CoreSimulator.SimRuntime.iOS-18-0"
```

Runtime 标识需要以本机实际输出为准。

---

## 7. 使用 Flutter CLI 运行 iOS App

### 7.1 Debug 模式运行

进入项目根目录：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
```

运行到当前启动的 iOS Simulator：

```bash
flutter run
```

如果连接多个设备，指定设备：

```bash
flutter devices
flutter run -d <device-id>
```

### 7.2 常用运行参数

```bash
flutter run -d <device-id> --debug
flutter run -d <device-id> --profile
flutter run -d <device-id> --dart-define=ENV=dev
```

说明：

| 参数 | 用途 |
|------|------|
| `--debug` | 默认开发模式，支持热重载和调试 |
| `--profile` | 性能分析模式，更接近发布性能 |
| `--release` | Simulator 通常不用于 release 真机验证 |
| `--dart-define` | 注入环境变量，例如 API 地址、开关配置 |

### 7.3 热重载与热重启

Flutter CLI 运行后常用按键：

| 按键 | 功能 |
|------|------|
| `r` | Hot reload，保留大部分状态 |
| `R` | Hot restart，重启 Dart VM |
| `q` | 退出运行 |
| `h` | 查看帮助 |

建议使用习惯：

- UI 样式、小组件布局调整：优先 `r`。
- Provider 初始化、路由、全局状态、main 入口变更：使用 `R`。
- 原生 iOS 配置、Pod、Info.plist、权限配置变更：完全停止后重新 `flutter run`。

---

## 8. 使用 Xcode 运行 Flutter iOS 工程

### 8.1 打开正确的 Workspace

```bash
cd "/Users/sjw/Documents/New project/weather_app"
open ios/Runner.xcworkspace
```

打开后，在 Xcode 顶部选择：

```text
Scheme: Runner
Device: iPhone 15 / iPhone 15 Pro / 其他 Simulator
```

然后点击 Run。

### 8.2 何时使用 Xcode

以下场景建议使用 Xcode：

- 修改 `Info.plist`、Capabilities、Signing & Capabilities。
- 排查 iOS 原生编译错误。
- 检查 Pod 编译失败的详细日志。
- 调试 Swift / Objective-C 插件或原生代码。
- 查看 Xcode Organizer、Devices and Simulators 信息。

### 8.3 Xcode 签名设置

Simulator Debug 运行一般不需要真实开发者证书，但 Xcode 工程仍可能显示 Signing 配置。

推荐设置：

```text
Runner Target -> Signing & Capabilities
Team: 可选个人 Apple ID Team，或保持项目默认
Bundle Identifier: 保持唯一，例如 com.example.weatherApp
Automatically manage signing: 开启
```

如果只跑 Simulator，签名问题通常不会阻塞；如果 Xcode 仍报错，可以先用 Flutter CLI 验证：

```bash
flutter run -d <simulator-id>
```

---

## 9. 模拟器中的常用测试能力

### 9.1 切换设备尺寸

在 Simulator 中：

```text
File -> Open Simulator -> iOS -> 选择设备
```

建议至少覆盖：

| 设备 | 测试重点 |
|------|----------|
| iPhone SE | 小屏布局、按钮溢出、文本换行 |
| iPhone 15 / 16 | 主流屏幕体验 |
| iPhone 15 Pro Max / 16 Pro Max | 大屏信息密度 |
| iPad | 宽屏、分栏、横屏适配 |

### 9.2 横竖屏测试

菜单路径：

```text
Device -> Rotate Left
Device -> Rotate Right
```

快捷键通常为：

```text
Command + Left Arrow
Command + Right Arrow
```

### 9.3 深色 / 浅色模式

模拟器菜单：

```text
Features -> Toggle Appearance
```

也可在模拟器内：

```text
Settings -> Developer -> Dark Appearance
```

### 9.4 模拟定位

菜单路径：

```text
Features -> Location
```

常用选项：

- None
- Custom Location
- Apple
- City Bicycle Ride
- Freeway Drive

如果 App 使用定位插件，例如 `geolocator`，需要确认 `ios/Runner/Info.plist` 中包含对应权限描述：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要使用当前位置获取天气信息</string>
```

### 9.5 模拟内存警告

```text
Device -> Trigger Memory Warning
```

可用于观察缓存、图片、状态恢复相关逻辑。

### 9.6 截图与录屏

截图：

```text
File -> Save Screen
```

命令行截图：

```bash
xcrun simctl io booted screenshot screenshot.png
```

录屏：

```bash
xcrun simctl io booted recordVideo app-demo.mov
```

停止录屏时按 `Control + C`。

---

## 10. 日常开发推荐流程

### 10.1 每日启动流程

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter pub get
open -a Simulator
flutter devices
flutter run -d <simulator-id>
```

如果只有一个 Simulator 已启动，可以直接：

```bash
flutter run
```

### 10.2 修改 Dart UI / 业务代码

1. 修改 `lib/` 下 Dart 文件。
2. 在终端按 `r` 热重载。
3. 如状态初始化异常，按 `R` 热重启。
4. 如仍异常，停止后重新 `flutter run`。

### 10.3 修改 Flutter 依赖

修改 `pubspec.yaml` 后执行：

```bash
flutter pub get
flutter run
```

如果新增依赖包含 iOS 原生插件，建议额外执行：

```bash
cd ios
pod install
cd ..
flutter run
```

### 10.4 修改 iOS 原生配置

修改以下文件后，需要完整重启 App：

- `ios/Runner/Info.plist`
- `ios/Podfile`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/AppDelegate.swift`
- iOS 插件配置文件

推荐流程：

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

---

## 11. 测试与验证命令

### 11.1 静态分析

```bash
flutter analyze
```

用于检查 Dart 代码风格、类型问题、废弃 API 等。

### 11.2 单元测试与 Widget 测试

```bash
flutter test
```

如果只运行指定测试文件：

```bash
flutter test test/widget_test.dart
```

### 11.3 iOS Debug 构建验证

```bash
flutter build ios --simulator --debug
```

### 11.4 iOS Profile 构建验证

```bash
flutter build ios --simulator --profile
```

Profile 模式适合观察基本性能、启动速度、动画流畅度，但不能代替真机性能测试。

### 11.5 集成测试（可选）

如果项目使用 `integration_test`：

```bash
flutter test integration_test/app_test.dart -d <simulator-id>
```

或：

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d <simulator-id>
```

具体命令以项目测试结构为准。

---

## 12. CocoaPods 与 Apple Silicon 注意事项

### 12.1 推荐 Podfile 基础配置

Flutter 默认生成的 Podfile 通常已经可用。建议确认以下点：

```ruby
platform :ios, '13.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}
```

Apple Silicon 下，除非项目有旧二进制 Pod，否则不要主动排除 `arm64` 模拟器架构。

### 12.2 不建议长期使用的配置

很多旧文章会建议加入：

```ruby
config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
```

这在 Intel Mac 时代或早期 Apple Silicon 迁移期常见，但在 Mac mini M4 上可能导致不必要的问题。只有当某个旧 Pod 明确无法在 arm64 Simulator 编译时，才作为临时兼容方案使用。

### 12.3 Pod 安装失败的标准清理流程

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

如果仍失败，再尝试更新本地 specs：

```bash
cd ios
pod repo update
pod install
```

### 12.4 Podfile.lock 是否提交

Flutter App 项目建议提交：

- `pubspec.lock`
- `ios/Podfile.lock`

这样可以减少团队成员之间、CI 与本地之间的依赖版本差异。

---

## 13. 常见问题排查

### 13.1 找不到 iOS Simulator

现象：

```text
No devices found
```

处理：

```bash
open -a Simulator
flutter devices
xcrun simctl list devices available
```

如果 Xcode 没有安装 Simulator Runtime，进入：

```text
Xcode -> Settings -> Platforms
```

安装 iOS Simulator Runtime。

### 13.2 Xcode toolchain 不可用

现象：

```text
Xcode installation is incomplete
```

处理：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
flutter doctor -v
```

### 13.3 CocoaPods not installed

处理：

```bash
brew install cocoapods
pod --version
flutter doctor -v
```

如果 `pod` 命令找不到，检查 Homebrew 路径：

```bash
which brew
which pod
echo $PATH
```

Apple Silicon Homebrew 默认路径通常是：

```text
/opt/homebrew/bin
```

### 13.4 `Generated.xcconfig must exist`

现象：

```text
Generated.xcconfig must exist. If you're running pod install manually, make sure flutter pub get is executed first.
```

处理：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter pub get
cd ios
pod install
```

### 13.5 `Module not found` 或插件找不到

处理：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

同时确认 Xcode 打开的是：

```text
ios/Runner.xcworkspace
```

不是：

```text
ios/Runner.xcodeproj
```

### 13.6 `building for iOS Simulator, but linking in object file built for iOS`

这是架构或二进制依赖不匹配问题。常见原因：

- 某个 Pod 引入了只支持真机的二进制 Framework。
- 旧版本插件未适配 Apple Silicon Simulator。
- Pod 缓存或 DerivedData 中有旧构建产物。

处理顺序：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
cd ios
pod deintegrate
pod install
cd ..
rm -rf ~/Library/Developer/Xcode/DerivedData
flutter run
```

如果仍失败，定位具体报错中的 Framework 或 Pod 名称，升级对应 Flutter 插件或 Pod 版本。

### 13.7 Simulator 卡死或启动异常

优先尝试：

```bash
xcrun simctl shutdown all
open -a Simulator
```

仍异常时，重置模拟器内容：

```bash
xcrun simctl erase all
```

注意：`erase all` 会清空所有模拟器中的 App、数据、登录状态和设置。

### 13.8 App 安装后立即闪退

排查路径：

1. 使用 `flutter run -v` 查看详细日志。
2. 打开 Xcode Console 查看崩溃输出。
3. 检查 `Info.plist` 权限声明是否缺失。
4. 检查初始化代码是否依赖真机能力。
5. 检查环境变量或 API Key 是否未注入。

常用命令：

```bash
flutter run -v
```

### 13.9 网络请求失败

Simulator 默认使用 Mac 网络。如果 App 请求本机服务，需要注意地址：

| 服务位置 | App 内访问地址 |
|----------|----------------|
| Mac 本机 localhost 服务 | `http://127.0.0.1:<port>` 或 `http://localhost:<port>` |
| 局域网设备服务 | 使用局域网 IP，例如 `http://192.168.x.x:<port>` |
| HTTPS 自签名服务 | 需要处理证书信任问题 |

如果 HTTP 请求被 iOS 拦截，需要配置 App Transport Security，仅开发环境可临时放开：

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

生产环境不建议全局开启 `NSAllowsArbitraryLoads`。

---

## 14. 调试工具

### 14.1 Flutter DevTools

运行 App 后，终端通常会输出 DevTools 地址。也可以手动启动：

```bash
dart devtools
```

常用能力：

- Widget Inspector：检查 UI 树和布局。
- Performance：查看帧率、构建耗时、卡顿。
- Memory：观察内存增长和泄漏迹象。
- Network：查看 Dart 层网络请求。
- Logging：查看应用日志。

### 14.2 Xcode Console

打开：

```text
Xcode -> Window -> Devices and Simulators
```

选择当前 Simulator，可以查看系统日志、安装状态和设备信息。

### 14.3 Flutter verbose 日志

```bash
flutter run -v
```

适合排查构建失败、Xcode 编译参数、Pod 集成问题。

日志较长，建议只在排障时使用。

---

## 15. iOS 权限配置检查

如果 App 使用系统能力，需要在 `ios/Runner/Info.plist` 中声明用途说明。常见配置如下：

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要使用当前位置获取天气信息</string>

<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄或识别图片</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片</string>

<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风录制音频</string>
```

缺少权限声明时，App 可能在调用相关 API 时直接崩溃。

天气类 App 常见权限：

- 定位权限：用于获取当前位置天气。
- 网络权限：通常无需额外 Info.plist 声明，但 HTTPS / ATS 需要注意。
- 后台刷新：如需要后台更新天气，需要额外配置 Background Modes，Simulator 测试不充分。

---

## 16. 多环境配置建议

建议通过 `--dart-define` 区分开发、测试、生产环境：

```bash
flutter run -d <device-id> --dart-define=APP_ENV=dev
flutter run -d <device-id> --dart-define=API_BASE_URL=https://api.example.com
```

Dart 代码读取方式：

```dart
const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
```

建议不要把生产 API Key、私密 Token 直接写入 Git 仓库。对于天气 App，可使用：

- 本地 `.env` 文件，并加入 `.gitignore`。
- CI Secret 注入。
- 后端代理服务隐藏真实 Key。

---

## 17. 推荐回归测试清单

每次提交 iOS 相关修改前，建议至少完成以下检查：

| 检查项 | 命令 / 操作 | 通过标准 |
|--------|-------------|----------|
| 依赖完整性 | `flutter pub get` | 无错误 |
| 静态分析 | `flutter analyze` | 无 error，warning 已确认 |
| 单元 / Widget 测试 | `flutter test` | 全部通过 |
| iOS Debug 运行 | `flutter run -d <simulator-id>` | App 可启动、可交互 |
| 小屏适配 | iPhone SE | 无文字溢出、按钮不可点问题 |
| 主流设备 | iPhone 15 / 16 | 主流程正常 |
| 大屏适配 | Pro Max / iPad | 布局不松散、不重叠 |
| 深浅色模式 | Toggle Appearance | 颜色、可读性正常 |
| 横竖屏 | Rotate | 无严重布局错位 |
| 定位权限 | Features -> Location | 权限弹窗与降级逻辑正常 |
| 网络异常 | 断网或 mock 失败 | 有错误态，不崩溃 |

---

## 18. 推荐问题处理顺序

遇到 iOS Simulator 无法运行时，建议按以下顺序排查：

```text
1. flutter doctor -v
2. flutter devices
3. open -a Simulator
4. flutter pub get
5. cd ios && pod install
6. flutter clean && flutter pub get && pod install
7. 清理 DerivedData
8. xcrun simctl shutdown all / erase all
9. 使用 Xcode 打开 Runner.xcworkspace 查看原生编译错误
10. 定位具体 Flutter 插件或 Pod 版本问题
```

常用完整修复命令：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
rm -rf ~/Library/Developer/Xcode/DerivedData
open -a Simulator
flutter run
```

注意：`rm -rf ~/Library/Developer/Xcode/DerivedData` 只清理 Xcode 构建缓存，不会删除项目源码。

---

## 19. CI 与本地 Simulator 的关系

本地 Simulator 主要用于开发验证。CI 中通常建议拆分：

```bash
flutter pub get
flutter analyze
flutter test
flutter build ios --simulator --debug
```

如果 CI 机器没有图形界面或没有安装 iOS Runtime，`flutter build ios --simulator` 可能失败。此时 CI 至少应保证：

- Dart 静态分析通过。
- 单元测试通过。
- Android / Web / macOS 等可用平台构建通过。
- iOS 构建在具备 Xcode 和 Simulator Runtime 的 macOS Runner 上执行。

---

## 20. 最佳实践总结

- Mac mini M4 原生 arm64 环境下，优先使用最新版 Xcode、Flutter Stable、Homebrew CocoaPods。
- Flutter 日常开发优先 `flutter run`，原生问题再进入 Xcode。
- Xcode 必须打开 `ios/Runner.xcworkspace`，不要用 `Runner.xcodeproj` 运行带 Pods 的项目。
- 修改 Dart 代码通常热重载即可；修改 Pod、Info.plist、AppDelegate 等原生配置必须完整重启。
- 不要随意排除 arm64 Simulator 架构，除非明确遇到旧 Pod 二进制兼容问题。
- Simulator 适合完成大部分开发测试，但不能完全替代真机的性能、相机、蓝牙、推送、传感器验证。
- 建议提交 `pubspec.lock` 与 `ios/Podfile.lock`，保持依赖版本稳定。
- 遇到复杂构建问题时，先清理 Flutter 缓存、Pods、DerivedData，再定位具体插件或 Pod。

---

## 21. 快速命令索引

```bash
# 进入项目
cd "/Users/sjw/Documents/New project/weather_app"

# 环境检查
flutter doctor -v
xcodebuild -version
pod --version

# 获取依赖
flutter pub get

# 安装 Pods
cd ios
pod install
cd ..

# 打开模拟器
open -a Simulator

# 查看设备
flutter devices
xcrun simctl list devices available

# 运行 App
flutter run
flutter run -d <device-id>

# 静态分析与测试
flutter analyze
flutter test

# iOS Simulator 构建
flutter build ios --simulator --debug
flutter build ios --simulator --profile

# 清理 Flutter 构建缓存
flutter clean

# 重装 Pods
cd ios
pod deintegrate
pod install
cd ..

# 清理 Xcode DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# 重启所有模拟器
xcrun simctl shutdown all
open -a Simulator

# 清空所有模拟器数据
xcrun simctl erase all
```

---

## 22. 推荐首次验证路径

新机器或新项目首次验证时，按下面顺序执行：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter doctor -v
flutter pub get
cd ios
pod install
cd ..
open -a Simulator
flutter devices
flutter run
```

App 成功安装并进入首页后，继续验证：

1. 热重载是否生效。
2. 页面跳转是否正常。
3. 网络请求是否正常。
4. 定位权限弹窗是否正常。
5. iPhone SE 与 Pro Max 布局是否正常。
6. 深色 / 浅色模式是否可读。
7. `flutter analyze` 与 `flutter test` 是否通过。

完成以上步骤后，即可在没有 iPhone 真机的情况下，使用 iOS Simulator 进行 Flutter iOS 端的日常开发测试。
