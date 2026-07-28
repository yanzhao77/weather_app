# 小米 15 数据线连接 ADB 联调测试技术文档

> 适用设备：小米 15 / 小米 15 Pro / 小米 15 Ultra（HyperOS / Android）  
> 适用电脑：Mac mini M4（Apple Silicon）、macOS 15 / macOS 26  
> 适用项目：Flutter 3.x、Android Studio、Android SDK Platform Tools、ADB、Gradle  
> 目标：通过 USB 数据线连接小米 15，在没有 Android 模拟器或需要真实设备能力时，完成 Flutter App 的 Android 真机联调、日志排查和基础测试。  
> 示例项目路径：`/Users/sjw/Documents/New project/weather_app`  
> 当前项目 Android 包名：`com.nexus.weather.nexus_weather`

---

## 1. 文档目标与适用边界

### 1.1 目标

本文档用于指导开发者使用 USB 数据线连接小米 15，通过 ADB（Android Debug Bridge）完成 Flutter Android App 的真机调试，覆盖：

- Mac mini M4 上安装和校验 Android SDK Platform Tools。
- 小米 15 开启开发者选项、USB 调试、USB 安装等关键开关。
- 通过 `adb devices` 建立电脑与手机的授权连接。
- 使用 Flutter CLI、Android Studio 两种方式运行 App。
- 使用 `adb logcat`、`flutter logs`、DevTools 排查问题。
- 验证网络、定位、权限、安装、热重载、真机性能等开发测试场景。
- 处理小米 / HyperOS 常见连接和安装失败问题。

### 1.2 为什么要用真机联调

Android 模拟器适合基础开发，但真机可以验证更多真实行为：

| 场景 | 真机价值 |
|------|----------|
| GPS 定位 | 使用真实定位芯片和系统权限行为 |
| 网络环境 | 验证 Wi-Fi、蜂窝网络、弱网、代理、DNS |
| 性能 | 观察真实 CPU、GPU、内存、刷新率表现 |
| 屏幕适配 | 验证小米 15 实际分辨率、状态栏、安全区域 |
| 权限弹窗 | 验证 HyperOS 权限管理、后台限制、通知权限 |
| 安装流程 | 验证 USB 安装、覆盖安装、卸载重装 |
| 摄像头 / 相册 / 传感器 | 使用真实硬件能力 |

### 1.3 ADB 与 Flutter 的关系

ADB 是 Android 官方调试桥，Flutter 在运行 Android 真机时也会调用 ADB。

常见关系：

```text
USB 数据线
   ↓
小米 15 开启 USB 调试
   ↓
adb devices 识别设备
   ↓
flutter devices 识别 Android device
   ↓
flutter run 安装并启动 App
```

只要 `adb devices` 识别正常，`flutter devices` 通常也能识别到手机。

---

## 2. 当前 Flutter 项目 Android 信息

本文档以当前项目为例：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
```

Android 关键配置：

| 配置项 | 当前值 |
|--------|--------|
| Android 包名 | `com.nexus.weather.nexus_weather` |
| Android namespace | `com.nexus.weather.nexus_weather` |
| compileSdk | `36` |
| targetSdk | `36` |
| Java 版本 | `17` |
| Gradle 配置格式 | Kotlin DSL (`build.gradle.kts`) |
| 主 Manifest | `android/app/src/main/AndroidManifest.xml` |

当前 Manifest 已声明：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

因此天气 App 的网络请求和定位测试具备基础权限声明。运行到 Android 12+ / Android 13+ / Android 14+ / Android 15+ 真机时，仍需要用户在系统弹窗中授权定位权限。

---

## 3. Mac 侧环境准备

### 3.1 安装 Android Studio

推荐安装 Android Studio，原因是它会统一管理：

- Android SDK
- Android SDK Platform Tools
- Android SDK Build Tools
- Android Emulator（可选）
- Gradle / JDK 配置
- Logcat、Device Explorer、Profiler

安装后打开：

```text
Android Studio -> Settings -> Languages & Frameworks -> Android SDK
```

建议至少安装：

- Android SDK Platform 36（与项目 `compileSdk = 36` 对齐）
- Android SDK Build-Tools
- Android SDK Platform-Tools
- Android SDK Command-line Tools

### 3.2 安装 Android SDK Platform Tools

ADB 位于 Platform Tools 中。通过 Android Studio 安装后，一般路径为：

```text
~/Library/Android/sdk/platform-tools/adb
```

校验：

```bash
~/Library/Android/sdk/platform-tools/adb version
```

如果命令可用，输出类似：

```text
Android Debug Bridge version 1.0.41
Version xx.x.x-xxxxxxx
```

### 3.3 配置 PATH

为了直接使用 `adb` 命令，建议把 Platform Tools 加入 shell PATH。

如果使用 zsh，编辑：

```bash
open ~/.zshrc
```

加入：

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

保存后执行：

```bash
source ~/.zshrc
adb version
```

如果不想配置 PATH，也可以一直使用完整路径：

```bash
~/Library/Android/sdk/platform-tools/adb devices
```

### 3.4 Flutter 环境检查

进入项目目录：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
```

执行：

```bash
flutter doctor -v
```

重点关注：

| 检查项 | 期望状态 |
|--------|----------|
| Flutter | `[✓]` |
| Android toolchain | `[✓]` |
| Android Studio | `[✓]` 或可用 |
| Connected device | 插入手机后能看到 Android device |

如果 Android toolchain 异常，优先检查 Android Studio SDK 路径和许可证：

```bash
flutter doctor --android-licenses
```

按提示输入 `y` 接受许可证。

---

## 4. USB 数据线与连接要求

### 4.1 数据线要求

请使用支持数据传输的 USB-C 数据线。部分充电线只能充电，不能传输数据，会导致 ADB 无法识别。

建议：

- 优先使用小米原装线或可靠的 USB-C 数据线。
- 尽量直连 Mac mini M4，不要先经过扩展坞。
- 如果必须使用扩展坞，优先使用支持 USB 数据传输的接口。
- 插入后手机状态栏应出现 USB 连接提示。

### 4.2 USB 连接模式

手机插入 Mac 后，下拉通知栏，找到 USB 连接选项，常见模式有：

- 仅充电
- 文件传输 / Android Auto
- 传输照片
- MIDI

通常 ADB 调试不一定依赖文件传输模式，但如果识别不稳定，建议切换到：

```text
文件传输 / Android Auto
```

---

## 5. 小米 15 开启开发者选项

### 5.1 开启开发者选项

在小米 15 上操作：

```text
设置 -> 我的设备 -> 全部参数与信息 -> 连续点击 “OS 版本” 或 “MIUI / HyperOS 版本” 7 次
```

看到提示：

```text
您已处于开发者模式
```

或：

```text
无需进行此操作，您已处于开发者模式
```

### 5.2 进入开发者选项

路径通常为：

```text
设置 -> 更多设置 -> 开发者选项
```

不同 HyperOS 版本入口名称可能略有不同，可以在设置顶部搜索：

```text
开发者选项
```

---

## 6. 小米 / HyperOS 必开调试开关

进入：

```text
设置 -> 更多设置 -> 开发者选项
```

建议开启以下选项：

| 开关 | 建议状态 | 用途 |
|------|----------|------|
| 开发者选项 | 开启 | 总开关 |
| USB 调试 | 开启 | 允许 ADB 连接 |
| USB 安装 | 开启 | 允许通过 USB 安装 App |
| USB 调试（安全设置） | 开启 | 允许通过 USB 授予权限、模拟点击等高级调试能力 |
| 停用 adb 授权超时 | 可选开启 | 减少频繁重新授权 |
| 默认 USB 配置 | 文件传输 | 提高连接稳定性 |
| 显示点按操作 | 可选开启 | 录屏或演示时方便观察 |
| 指针位置 | 可选关闭 | 仅特殊触控排查时开启 |

小米系统可能要求登录小米账号、插入 SIM 卡、联网，才能开启 `USB 安装` 或 `USB 调试（安全设置）`。这是系统安全策略，不是 Flutter 问题。

如果暂时无法开启 `USB 调试（安全设置）`，通常仍可以进行基础 Flutter 安装和运行；但部分 ADB 授权、自动化、权限授予命令可能不可用。

---

## 7. 首次 ADB 授权连接

### 7.1 连接步骤

1. 用 USB-C 数据线连接 Mac mini M4 和小米 15。
2. 手机解锁并保持亮屏。
3. 确认开发者选项中 `USB 调试` 已开启。
4. Mac 终端执行：

```bash
adb devices
```

首次连接时，手机会弹出授权窗口：

```text
是否允许 USB 调试？
```

建议勾选：

```text
一律允许使用这台计算机进行调试
```

然后点击允许。

### 7.2 正常识别状态

再次执行：

```bash
adb devices
```

期望输出类似：

```text
List of devices attached
xxxxxxxx        device
```

其中 `device` 表示已授权、可调试。

### 7.3 常见异常状态

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| `unauthorized` | 手机未确认 USB 调试授权 | 解锁手机，点击允许 |
| `offline` | ADB 连接异常 | 重插数据线、重启 ADB |
| 无任何设备 | 未识别 USB 设备 | 换线、换接口、检查 USB 模式 |
| 多个设备 | 同时连接了模拟器或其他手机 | 使用 `-s <serial>` 指定设备 |

重启 ADB：

```bash
adb kill-server
adb start-server
adb devices
```

---

## 8. 使用 Flutter CLI 真机运行

### 8.1 获取依赖

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter pub get
```

### 8.2 查看设备

```bash
flutter devices
```

正常情况下应看到类似：

```text
Xiaomi 15 (mobile) • xxxxxxxx • android-arm64 • Android xx
```

如果 `adb devices` 有设备，但 `flutter devices` 没有，执行：

```bash
flutter doctor -v
adb kill-server
adb start-server
flutter devices
```

### 8.3 Debug 模式运行

如果只连接了一台手机：

```bash
flutter run
```

如果有多个设备，指定小米 15：

```bash
flutter run -d <device-id>
```

查看设备 ID：

```bash
flutter devices
adb devices
```

### 8.4 常用运行参数

```bash
flutter run -d <device-id> --debug
flutter run -d <device-id> --profile
flutter run -d <device-id> --release
flutter run -d <device-id> --dart-define=APP_ENV=dev
flutter run -d <device-id> --dart-define=API_BASE_URL=https://api.example.com
```

说明：

| 参数 | 用途 |
|------|------|
| `--debug` | 默认开发模式，支持热重载、断点和调试日志 |
| `--profile` | 性能分析模式，更接近真实性能 |
| `--release` | 发布模式验证，不支持热重载 |
| `--dart-define` | 注入运行环境变量 |

### 8.5 热重载与热重启

`flutter run` 后常用按键：

| 按键 | 功能 |
|------|------|
| `r` | Hot reload，保留大部分状态 |
| `R` | Hot restart，重启 Dart VM |
| `q` | 退出运行 |
| `h` | 查看帮助 |

建议：

- 修改 UI、颜色、布局、普通 Dart 逻辑：按 `r`。
- 修改 Provider 初始化、路由表、全局状态、入口逻辑：按 `R`。
- 修改 Android 原生配置、Manifest、Gradle、权限、插件：停止后重新 `flutter run`。

---

## 9. 使用 Android Studio 真机运行

### 9.1 打开项目

使用 Android Studio 打开 Flutter 项目根目录：

```text
/Users/sjw/Documents/New project/weather_app
```

不要只打开 `android/` 子目录，除非只想调试原生 Android 工程。

### 9.2 选择设备

顶部设备选择器中应看到小米 15，例如：

```text
Xiaomi 15
```

如果没有显示：

1. 确认 `adb devices` 显示 `device`。
2. 重新插拔数据线。
3. 重启 Android Studio。
4. 执行 `adb kill-server && adb start-server` 后再看。

### 9.3 运行与调试

常用入口：

- 点击 Run：安装并启动 App。
- 点击 Debug：启动调试模式，可断点调试 Dart 代码。
- 打开 Logcat：查看 Android 系统和应用日志。
- 打开 Flutter Inspector：检查 Widget 树。
- 打开 Profiler：查看 CPU、内存、网络等。

### 9.4 Android Studio 中的 Logcat 过滤

推荐过滤条件：

```text
package:mine
```

或按包名过滤：

```text
package:com.nexus.weather.nexus_weather
```

也可以搜索关键词：

```text
flutter
FATAL EXCEPTION
AndroidRuntime
Permission
Geolocator
Dio
```

---

## 10. ADB 常用命令

### 10.1 设备连接

```bash
adb devices
adb kill-server
adb start-server
adb reconnect
adb get-state
```

查看设备详细信息：

```bash
adb shell getprop ro.product.model
adb shell getprop ro.product.brand
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
```

### 10.2 安装与卸载 App

Debug APK 常见路径：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

构建 Debug APK：

```bash
flutter build apk --debug
```

安装 APK：

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

卸载当前项目 App：

```bash
adb uninstall com.nexus.weather.nexus_weather
```

清空 App 数据但保留安装：

```bash
adb shell pm clear com.nexus.weather.nexus_weather
```

### 10.3 启动和停止 App

启动 App 主入口：

```bash
adb shell monkey -p com.nexus.weather.nexus_weather -c android.intent.category.LAUNCHER 1
```

强制停止：

```bash
adb shell am force-stop com.nexus.weather.nexus_weather
```

### 10.4 截图和录屏

截图到手机：

```bash
adb shell screencap -p /sdcard/nexus_weather.png
```

拉取到 Mac：

```bash
adb pull /sdcard/nexus_weather.png ./nexus_weather.png
```

录屏：

```bash
adb shell screenrecord /sdcard/nexus_weather_demo.mp4
```

停止录屏时按 `Control + C`，再拉取：

```bash
adb pull /sdcard/nexus_weather_demo.mp4 ./nexus_weather_demo.mp4
```

### 10.5 查看当前前台 Activity

```bash
adb shell dumpsys window | grep mCurrentFocus
```

如果 `grep` 没输出，可使用：

```bash
adb shell dumpsys activity activities | grep ResumedActivity
```

---

## 11. 日志与崩溃排查

### 11.1 Flutter 日志

```bash
flutter logs -d <device-id>
```

如果只有一台设备：

```bash
flutter logs
```

适合查看 Dart 层 `print`、Flutter framework 日志、插件输出。

### 11.2 ADB Logcat

查看全部日志：

```bash
adb logcat
```

只看崩溃相关：

```bash
adb logcat *:E
```

按关键词过滤：

```bash
adb logcat | grep -i flutter
adb logcat | grep -i AndroidRuntime
adb logcat | grep -i FATAL
```

保存日志到文件：

```bash
adb logcat -d > android-logcat.txt
```

清空旧日志后复现问题：

```bash
adb logcat -c
flutter run
adb logcat -d > android-repro-log.txt
```

### 11.3 崩溃排查顺序

App 启动后闪退时，建议按以下顺序：

1. 运行 `flutter run -v` 查看 Flutter 构建与启动日志。
2. 运行 `adb logcat *:E` 查看 Android 崩溃栈。
3. 搜索 `FATAL EXCEPTION`、`AndroidRuntime`、`Caused by`。
4. 检查是否缺少 Android 权限声明或运行时授权。
5. 检查插件初始化是否依赖 Google Play 服务、定位服务、网络或系统设置。
6. 清空 App 数据后重试：`adb shell pm clear com.nexus.weather.nexus_weather`。

---

## 12. 权限联调

### 12.1 当前项目权限

当前项目已声明：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

定位权限在 Android 6.0 以后需要运行时申请。用户可以选择：

- 精确位置
- 大致位置
- 仅本次允许
- 使用期间允许
- 拒绝

### 12.2 手动查看 App 权限

手机端路径：

```text
设置 -> 应用设置 -> 应用管理 -> nexus_weather -> 权限管理
```

小米 / HyperOS 上也可以通过：

```text
设置 -> 隐私保护 -> 权限管理 -> 位置信息
```

### 12.3 ADB 授予和撤销权限

授予精确定位：

```bash
adb shell pm grant com.nexus.weather.nexus_weather android.permission.ACCESS_FINE_LOCATION
```

授予粗略定位：

```bash
adb shell pm grant com.nexus.weather.nexus_weather android.permission.ACCESS_COARSE_LOCATION
```

撤销定位：

```bash
adb shell pm revoke com.nexus.weather.nexus_weather android.permission.ACCESS_FINE_LOCATION
adb shell pm revoke com.nexus.weather.nexus_weather android.permission.ACCESS_COARSE_LOCATION
```

注意：如果小米系统未开启 `USB 调试（安全设置）`，部分 `pm grant` / `pm revoke` 命令可能被限制。

### 12.4 权限测试建议

建议覆盖：

| 场景 | 预期 |
|------|------|
| 首次启动申请定位 | 弹出系统权限框 |
| 允许精确定位 | 天气数据按当前位置加载 |
| 只允许大致位置 | App 有合理降级 |
| 拒绝定位 | App 显示手动搜索或错误提示 |
| 永久拒绝 | App 引导到系统设置 |
| 关闭系统定位服务 | App 提示开启定位服务 |

---

## 13. 网络联调

### 13.1 真机访问公网 API

小米 15 使用自己的网络环境，不共享 Mac 的 localhost。请确认：

- 手机已连接 Wi-Fi 或蜂窝网络。
- App API 域名可从手机访问。
- 如果使用公司代理、抓包工具或自签名证书，需要在手机侧配置。

### 13.2 真机访问 Mac 本机服务

如果后端服务跑在 Mac 上，例如：

```text
http://localhost:3000
```

手机不能直接用 `localhost` 访问 Mac，因为手机上的 `localhost` 指的是手机自己。

正确方式：

1. 查看 Mac 局域网 IP：

```bash
ipconfig getifaddr en0
```

2. 假设输出：

```text
192.168.1.20
```

3. App 中使用：

```text
http://192.168.1.20:3000
```

确保 Mac 和小米 15 在同一个 Wi-Fi 网络。

### 13.3 使用 adb reverse 转发本机端口

ADB 可以把手机访问的本地端口转发到 Mac：

```bash
adb reverse tcp:3000 tcp:3000
```

然后 App 中可以访问：

```text
http://127.0.0.1:3000
```

注意：`adb reverse` 只在 USB 调试连接存在时有效，断开连接后需要重新设置。

查看转发列表：

```bash
adb reverse --list
```

移除所有 reverse：

```bash
adb reverse --remove-all
```

### 13.4 Android 明文 HTTP 限制

Android 9+ 默认限制明文 HTTP。开发环境访问 `http://` 可能失败。

如果需要临时允许明文请求，可在 `android/app/src/main/AndroidManifest.xml` 的 `<application>` 上增加：

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

生产环境建议使用 HTTPS，不建议长期全局开启明文流量。

---

## 14. 定位联调

### 14.1 手机侧定位设置

确认：

```text
设置 -> 位置信息 -> 开启
```

并在 App 权限中允许定位。

### 14.2 Flutter geolocator 常见检查

当前项目依赖中包含：

```yaml
geolocator: ^12.0.0
geocoding: ^3.0.0
```

Android 侧需要：

- Manifest 声明定位权限。
- 运行时申请权限。
- 手机系统定位服务开启。
- 小米系统未限制 App 后台或定位权限。

### 14.3 模拟定位

真机上如果需要模拟位置，可以使用 Android 开发者选项中的：

```text
选择模拟位置信息应用
```

流程：

1. 安装可信的 Mock Location App。
2. 在开发者选项中选择该应用。
3. 在 Mock Location App 中设置位置。
4. 重新打开 Flutter App 验证定位结果。

注意：部分地图、天气或安全策略可能识别模拟定位，与真实 GPS 结果不完全一致。

---

## 15. 构建、安装与包体检查

### 15.1 Debug 构建

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter build apk --debug
```

输出：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### 15.2 Profile 构建

```bash
flutter build apk --profile
```

Profile 包适合真机性能观察。

### 15.3 Release 构建

```bash
flutter build apk --release
```

当前项目 release 使用 debug 签名配置：

```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")
}
```

这适合本地测试，不适合正式发布。正式发布需要配置独立 release keystore。

### 15.4 安装指定 APK

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

如果版本降级安装失败：

```bash
adb install -r -d build/app/outputs/flutter-apk/app-debug.apk
```

如果签名不一致，先卸载：

```bash
adb uninstall com.nexus.weather.nexus_weather
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 16. 小米 / HyperOS 常见问题

### 16.1 `adb devices` 无设备

排查：

1. 换一根支持数据传输的数据线。
2. 换 Mac mini M4 的 USB-C 接口。
3. 手机下拉通知栏，把 USB 模式改为 `文件传输 / Android Auto`。
4. 确认 `USB 调试` 已开启。
5. 重启 ADB：

```bash
adb kill-server
adb start-server
adb devices
```

6. 重启手机和 Mac 后再试。

### 16.2 显示 `unauthorized`

处理：

1. 解锁手机并保持亮屏。
2. 查看是否有 `是否允许 USB 调试` 弹窗。
3. 点击允许，并勾选 `一律允许使用这台计算机进行调试`。
4. 如果没有弹窗，在开发者选项中点击 `撤销 USB 调试授权`，然后重新插线。

命令：

```bash
adb kill-server
adb start-server
adb devices
```

### 16.3 安装失败：`INSTALL_FAILED_USER_RESTRICTED`

这是小米系统常见限制，通常是 `USB 安装` 未开启或系统安全限制。

处理：

```text
设置 -> 更多设置 -> 开发者选项 -> USB 安装 -> 开启
设置 -> 更多设置 -> 开发者选项 -> USB 调试（安全设置） -> 开启
```

如果系统要求登录小米账号、插入 SIM 卡或联网，需要按系统提示完成。

### 16.4 安装失败：签名不一致

现象可能包含：

```text
INSTALL_FAILED_UPDATE_INCOMPATIBLE
```

处理：

```bash
adb uninstall com.nexus.weather.nexus_weather
flutter run
```

注意：卸载会清除 App 本地数据。

### 16.5 App 启动后白屏

排查：

```bash
flutter run -v
adb logcat *:E
flutter logs
```

常见原因：

- Dart 初始化异常。
- `.env` 或资源文件未加载。
- 网络请求阻塞首屏。
- 插件权限未授权。
- Android 原生启动主题或资源异常。

### 16.6 App 无法联网

检查：

1. 手机浏览器能否访问目标 API 域名。
2. App 是否声明 `INTERNET` 权限，当前项目已声明。
3. 是否访问了 Mac 的 `localhost`，真机需要用局域网 IP 或 `adb reverse`。
4. 是否使用 HTTP 明文请求，被 Android 限制。
5. 是否被代理、VPN、证书、公司网络拦截。

### 16.7 定位一直失败

检查：

1. 手机系统定位服务是否开启。
2. App 是否获得定位权限。
3. 是否选择了精确定位。
4. 是否在室内或信号较差环境。
5. HyperOS 是否限制了 App 权限。
6. `geolocator` 是否正确处理权限拒绝和服务关闭场景。

---

## 17. 清理与重置流程

### 17.1 Flutter 清理

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
flutter pub get
flutter run
```

### 17.2 Gradle 清理

```bash
cd "/Users/sjw/Documents/New project/weather_app/android"
./gradlew clean
cd ..
flutter run
```

### 17.3 清空 App 数据

```bash
adb shell pm clear com.nexus.weather.nexus_weather
```

适合验证首次启动、权限弹窗、登录态、本地缓存初始化。

### 17.4 卸载重装

```bash
adb uninstall com.nexus.weather.nexus_weather
flutter run
```

### 17.5 重置 ADB 授权

手机端：

```text
设置 -> 更多设置 -> 开发者选项 -> 撤销 USB 调试授权
```

Mac 端：

```bash
adb kill-server
adb start-server
adb devices
```

重新插线并在手机上授权。

---

## 18. 真机测试清单

每次 Android 真机联调建议覆盖：

| 测试项 | 操作 | 通过标准 |
|--------|------|----------|
| 设备识别 | `adb devices` | 状态为 `device` |
| Flutter 识别 | `flutter devices` | 显示小米 15 |
| Debug 运行 | `flutter run` | App 成功安装并启动 |
| 热重载 | 终端按 `r` | UI 更新生效 |
| 热重启 | 终端按 `R` | App 状态重建正常 |
| 网络请求 | 进入天气数据页面 | 数据加载或错误态正常 |
| 定位权限 | 首次请求定位 | 弹窗和授权结果正常 |
| 拒绝权限 | 系统权限选择拒绝 | App 不崩溃，有降级提示 |
| 清空数据 | `adb shell pm clear ...` | 首次启动流程正常 |
| 横竖屏 | 旋转手机 | 布局无重叠 |
| 深浅色 | 系统切换主题 | 文本可读、颜色正常 |
| 后台返回 | Home 后再打开 | 状态恢复正常 |
| 弱网 | 切换网络或限速 | 加载态、失败态合理 |
| 崩溃日志 | `adb logcat *:E` | 无关键异常 |

---

## 19. 推荐日常联调流程

### 19.1 每日首次连接

```bash
cd "/Users/sjw/Documents/New project/weather_app"
adb devices
flutter doctor -v
flutter pub get
flutter devices
flutter run
```

### 19.2 修改 Dart 代码

```text
修改 lib/ 下代码 -> 终端按 r -> 观察小米 15 真机表现
```

### 19.3 修改依赖或 Android 配置

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter clean
flutter pub get
flutter run
```

如果涉及 Android Gradle 配置：

```bash
cd android
./gradlew clean
cd ..
flutter run
```

### 19.4 复现 Bug 并导出日志

```bash
adb logcat -c
flutter run
```

复现问题后：

```bash
adb logcat -d > xiaomi15-repro-log.txt
```

同时记录：

- 手机系统版本。
- App 构建模式：Debug / Profile / Release。
- Flutter 版本：`flutter --version`。
- 复现步骤。
- 是否使用 Wi-Fi、蜂窝网络、代理或 VPN。

---

## 20. 性能调试建议

### 20.1 Profile 模式运行

```bash
flutter run --profile -d <device-id>
```

Profile 模式更适合观察：

- 首屏加载时间。
- 页面切换流畅度。
- 动画掉帧。
- 内存增长。
- 网络请求耗时。

### 20.2 Flutter DevTools

`flutter run` 后终端会输出 DevTools 链接。常用页面：

- Flutter Inspector：检查 Widget 布局。
- Performance：查看帧耗时和卡顿。
- Memory：观察内存和对象增长。
- Network：查看 Dart HTTP 请求。
- Logging：查看应用日志。

### 20.3 Android Studio Profiler

Android Studio 中选择小米 15 后打开 Profiler，可以观察：

- CPU 使用率。
- Memory 分配。
- Energy。
- Network。

Profile / Release 模式下的数据更有参考价值。

---

## 21. 安全与数据注意事项

- USB 调试会给予电脑较高调试权限，只信任自己的电脑。
- 公共电脑不要勾选 `一律允许使用这台计算机进行调试`。
- 测试完成后可以关闭 `USB 调试` 或撤销 USB 调试授权。
- 日志文件可能包含接口地址、Token、用户信息，分享前需要脱敏。
- 不要把生产 API Key、账号密码写入 Git 仓库。
- 使用 `adb shell pm clear` 和 `adb uninstall` 会删除本地数据，执行前确认是否需要保留。

---

## 22. 快速命令索引

```bash
# 进入项目
cd "/Users/sjw/Documents/New project/weather_app"

# Flutter 环境检查
flutter doctor -v
flutter --version

# Android 许可证
flutter doctor --android-licenses

# ADB 版本与设备
adb version
adb devices
adb kill-server
adb start-server

# 查看手机信息
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk

# Flutter 设备与运行
flutter devices
flutter pub get
flutter run
flutter run -d <device-id>
flutter run --profile -d <device-id>

# 日志
flutter logs
adb logcat
adb logcat *:E
adb logcat -c
adb logcat -d > android-logcat.txt

# 构建 APK
flutter build apk --debug
flutter build apk --profile
flutter build apk --release

# 安装 / 卸载 / 清数据
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb uninstall com.nexus.weather.nexus_weather
adb shell pm clear com.nexus.weather.nexus_weather

# 启动 / 停止 App
adb shell monkey -p com.nexus.weather.nexus_weather -c android.intent.category.LAUNCHER 1
adb shell am force-stop com.nexus.weather.nexus_weather

# 截图 / 录屏
adb shell screencap -p /sdcard/nexus_weather.png
adb pull /sdcard/nexus_weather.png ./nexus_weather.png
adb shell screenrecord /sdcard/nexus_weather_demo.mp4
adb pull /sdcard/nexus_weather_demo.mp4 ./nexus_weather_demo.mp4

# 本地服务端口转发
adb reverse tcp:3000 tcp:3000
adb reverse --list
adb reverse --remove-all

# 清理
flutter clean
cd android
./gradlew clean
cd ..
```

---

## 23. 推荐首次验证路径

新手机或新电脑首次联调时，建议严格按下面顺序执行：

1. Mac 安装 Android Studio 与 Android SDK Platform Tools。
2. 小米 15 开启开发者选项。
3. 开启 `USB 调试`、`USB 安装`、`USB 调试（安全设置）`。
4. 使用支持数据传输的 USB-C 线连接 Mac mini M4。
5. 手机解锁，确认 USB 调试授权弹窗。
6. Mac 执行：

```bash
adb devices
```

确认状态为：

```text
device
```

7. 进入项目并运行：

```bash
cd "/Users/sjw/Documents/New project/weather_app"
flutter doctor -v
flutter pub get
flutter devices
flutter run
```

8. App 启动后验证：

- 首页是否正常显示。
- 热重载是否生效。
- 网络请求是否成功。
- 定位权限弹窗是否正常。
- 拒绝定位时是否有降级处理。
- 横竖屏是否正常。
- `flutter logs` 和 `adb logcat *:E` 是否无关键异常。

完成以上步骤后，即可使用小米 15 作为 Flutter Android 真机测试设备进行日常联调。
