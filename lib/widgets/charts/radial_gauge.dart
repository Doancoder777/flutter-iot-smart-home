import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Đồng hồ đo dạng radial (hình cung)
class RadialGauge extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String? unit;
  final Color gaugeColor;
  final Color backgroundColor;
  final double size;
  final Duration duration;

  const RadialGauge({
    Key? key,
    required this.value,
    this.minValue = 0,
    this.maxValue = 100,
    this.unit,
    this.gaugeColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.size = 200,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<RadialGauge> createState() => _RadialGaugeState();
}

class _RadialGaugeState extends State<RadialGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _updateAnimation();
    _controller.forward();
  }

  void _updateAnimation() {
    _animation = Tween<double>(
      begin: widget.minValue,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(RadialGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _updateAnimation();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RadialGaugePainter(
                  value: _animation.value,
                  minValue: widget.minValue,
                  maxValue: widget.maxValue,
                  gaugeColor: widget.gaugeColor,
                  backgroundColor: widget.backgroundColor.withOpacity(0.2),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _animation.value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.unit != null)
                    Text(
                      widget.unit!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color gaugeColor;
  final Color backgroundColor;

  _RadialGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.gaugeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const strokeWidth = 15.0;

    // Vẽ background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75; // 135 độ
    const sweepAngle = math.pi * 1.5; // 270 độ

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Vẽ value arc
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    final valueSweepAngle = sweepAngle * normalizedValue.clamp(0.0, 1.0);

    final valuePaint = Paint()
      ..color = gaugeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      valueSweepAngle,
      false,
      valuePaint,
    );

    // Vẽ các tick marks
    _drawTickMarks(canvas, center, radius, strokeWidth);
  }

  void _drawTickMarks(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
  ) {
    const numberOfTicks = 5;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final tickPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2;

    for (int i = 0; i <= numberOfTicks; i++) {
      final angle = startAngle + (sweepAngle * i / numberOfTicks);
      final innerRadius = radius - strokeWidth / 2 - 5;
      final outerRadius = radius - strokeWidth / 2 + 5;

      final startX = center.dx + innerRadius * math.cos(angle);
      final startY = center.dy + innerRadius * math.sin(angle);
      final endX = center.dx + outerRadius * math.cos(angle);
      final endY = center.dy + outerRadius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }
  }

  @override
  bool shouldRepaint(_RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
