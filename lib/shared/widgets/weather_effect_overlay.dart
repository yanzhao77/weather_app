import 'dart:math';

import 'package:flutter/material.dart';

enum WeatherEffectType { none, rain, snow, storm, fog }

WeatherEffectType weatherEffectTypeFromMain(String? main) {
  switch (main?.toLowerCase()) {
    case 'thunderstorm':
      return WeatherEffectType.storm;
    case 'rain':
    case 'drizzle':
      return WeatherEffectType.rain;
    case 'snow':
      return WeatherEffectType.snow;
    case 'mist':
    case 'fog':
    case 'haze':
      return WeatherEffectType.fog;
    default:
      return WeatherEffectType.none;
  }
}

/// 全屏天气特效层：下雨 / 下雪 / 雷暴 / 雾
/// 挂在 Stack 最上层并 IgnorePointer，不影响触摸操作。
/// 动画由 AnimationController 驱动 painter 重绘（repaint listenable），
/// 不重建 widget 树。
class WeatherEffectOverlay extends StatefulWidget {
  final String? weatherMain;
  final bool enabled;

  const WeatherEffectOverlay({
    super.key,
    required this.weatherMain,
    this.enabled = true,
  });

  @override
  State<WeatherEffectOverlay> createState() => _WeatherEffectOverlayState();
}

class _WeatherEffectOverlayState extends State<WeatherEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_RainDrop> _rain;
  late final List<_SnowFlake> _snow;
  late final List<_FogPuff> _fog;
  final Random _random = Random();

  WeatherEffectType get _type =>
      widget.enabled ? weatherEffectTypeFromMain(widget.weatherMain) : WeatherEffectType.none;

  @override
  void initState() {
    super.initState();
    _rain = List.generate(200, (_) => _RainDrop.random(_random));
    _snow = List.generate(110, (_) => _SnowFlake.random(_random));
    _fog = List.generate(7, (_) => _FogPuff.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (_type != WeatherEffectType.none) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WeatherEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldType = weatherEffectTypeFromMain(oldWidget.weatherMain);
    if (_type != oldType) {
      if (_type == WeatherEffectType.none) {
        _controller.stop();
      } else if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_type == WeatherEffectType.none) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _WeatherEffectPainter(
            type: _type,
            rain: _rain,
            snow: _snow,
            fog: _fog,
            controller: _controller,
          ),
        ),
      ),
    );
  }
}

class _RainDrop {
  double x, y; // 0..1 相对坐标
  final double speed; // 屏幕高度每秒的倍数
  final double drift; // 水平漂移（相对速度）
  final double length;
  final double alpha;

  _RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.drift,
    required this.length,
    required this.alpha,
  });

  factory _RainDrop.random(Random r) {
    return _RainDrop(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 1.1 + r.nextDouble() * 0.7,
      drift: 0.08 + r.nextDouble() * 0.12,
      length: 9 + r.nextDouble() * 8,
      alpha: 0.35 + r.nextDouble() * 0.35,
    );
  }

  void reset(Random r) {
    x = r.nextDouble();
    y = -0.05;
    // 重新随机速度，保持自然
  }
}

class _SnowFlake {
  double x, y;
  final double speed;
  final double sway; // 摆动幅度
  double phase; // 摆动相位
  final double size;
  final double alpha;

  _SnowFlake({
    required this.x,
    required this.y,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.size,
    required this.alpha,
  });

  factory _SnowFlake.random(Random r) {
    return _SnowFlake(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.08 + r.nextDouble() * 0.12,
      sway: 0.02 + r.nextDouble() * 0.03,
      phase: r.nextDouble() * pi * 2,
      size: 1.5 + r.nextDouble() * 2.5,
      alpha: 0.5 + r.nextDouble() * 0.4,
    );
  }
}

class _FogPuff {
  double x;
  final double y;
  final double radius;
  final double speed;
  final double alpha;

  _FogPuff({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
  });

  factory _FogPuff.random(Random r) {
    return _FogPuff(
      x: r.nextDouble(),
      y: 0.1 + r.nextDouble() * 0.8,
      radius: 0.25 + r.nextDouble() * 0.3,
      speed: 0.02 + r.nextDouble() * 0.03,
      alpha: 0.05 + r.nextDouble() * 0.08,
    );
  }
}

class _WeatherEffectPainter extends CustomPainter {
  final WeatherEffectType type;
  final List<_RainDrop> rain;
  final List<_SnowFlake> snow;
  final List<_FogPuff> fog;
  final AnimationController controller;
  final Random _random = Random();
  final double _durationSeconds = 60;
  double? _lastValue;
  double _lightningIn = 3 + Random().nextDouble() * 5;
  double _flash = 0;

  _WeatherEffectPainter({
    required this.type,
    required this.rain,
    required this.snow,
    required this.fog,
    required this.controller,
  }) : super(repaint: controller);

  /// 根据 controller.value（0..1 循环）推算上一帧到本帧的秒数
  double _dt(double value) {
    final last = _lastValue;
    _lastValue = value;
    if (last == null) return 0;
    double dt = (value - last) * _durationSeconds;
    if (value < last) {
      dt = (1 - last + value) * _durationSeconds;
    }
    return dt.clamp(0.0, 0.1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final dt = _dt(controller.value);
    final w = size.width;
    final h = size.height;

    switch (type) {
      case WeatherEffectType.storm:
        _paintLightning(canvas, size, dt);
        _paintRain(canvas, w, h, dt, bright: true);
      case WeatherEffectType.rain:
        _paintRain(canvas, w, h, dt, bright: false);
      case WeatherEffectType.snow:
        _paintSnow(canvas, w, h, dt);
      case WeatherEffectType.fog:
        _paintFog(canvas, w, h, dt);
      case WeatherEffectType.none:
        break;
    }
  }

  void _paintRain(Canvas canvas, double w, double h, double dt, {required bool bright}) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    final baseColor = bright ? const Color(0xCCDFF2FF) : const Color(0xAA9FC8F0);
    for (final drop in rain) {
      drop.y += drop.speed * dt;
      drop.x += drop.drift * dt * 0.4;
      if (drop.y > 1.1) {
        drop.reset(_random);
        drop.y = -0.05 - _random.nextDouble() * 0.05;
      }
      if (drop.x > 1.15) drop.x = -0.1;
      if (drop.x < -0.15) drop.x = 1.1;
      paint.color = baseColor.withValues(alpha: drop.alpha);
      final x0 = drop.x * w;
      final y0 = drop.y * h;
      canvas.drawLine(
        Offset(x0 - drop.drift * drop.length * 2, y0 - drop.length),
        Offset(x0, y0),
        paint,
      );
    }
  }

  void _paintSnow(Canvas canvas, double w, double h, double dt) {
    final paint = Paint()..color = const Color(0xDDFFFFFF);
    for (final flake in snow) {
      flake.phase += dt * 2.2;
      flake.y += flake.speed * dt;
      flake.x += sin(flake.phase) * flake.sway * dt;
      if (flake.y > 1.1) {
        flake.y = -0.05 - _random.nextDouble() * 0.05;
        flake.x = _random.nextDouble();
      }
      if (flake.x > 1.1) flake.x = -0.05;
      if (flake.x < -0.1) flake.x = 1.05;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: flake.alpha);
      canvas.drawCircle(
        Offset(flake.x * w, flake.y * h),
        flake.size,
        paint,
      );
    }
  }

  void _paintFog(Canvas canvas, double w, double h, double dt) {
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    for (final puff in fog) {
      puff.x += puff.speed * dt;
      if (puff.x > 1.3) puff.x = -0.3;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: puff.alpha);
      canvas.drawCircle(
        Offset(puff.x * w, puff.y * h),
        puff.radius * w,
        paint,
      );
    }
  }

  void _paintLightning(Canvas canvas, Size size, double dt) {
    _lightningIn -= dt;
    if (_lightningIn <= 0) {
      _flash = 0.06 + _random.nextDouble() * 0.06;
      _lightningIn = 2.5 + _random.nextDouble() * 6;
    }
    if (_flash > 0) {
      _flash -= dt;
      final flashAlpha = (_flash / 0.06).clamp(0.0, 1.0);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Color.fromARGB(
            (0.22 * flashAlpha * 255).round(), 255, 255, 255),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
