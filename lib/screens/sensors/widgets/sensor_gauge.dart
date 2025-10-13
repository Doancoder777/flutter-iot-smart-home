import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget đồng hồ đo cho cảm biến
class SensorGauge extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final String label;
  final String unit;
  final Color color;
  final double size;
  final List<GaugeRange>? ranges;

  const SensorGauge({
    Key? key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.label,
    required this.unit,
    this.color = Colors.blue,
    this.size = 150,
    this.ranges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GaugePainter(
              value: value,
              minValue: minValue,
              maxValue: maxValue,
              color: color,
              ranges: ranges,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final Color color;
  final List<GaugeRange>? ranges;

  _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.color,
    this.ranges,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const strokeWidth = 12.0;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Vẽ background
    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Vẽ ranges nếu có
    if (ranges != null) {
      for (var range in ranges!) {
        final rangeStart = (range.start - minValue) / (maxValue - minValue);
        final rangeEnd = (range.end - minValue) / (maxValue - minValue);
        final rangeStartAngle = startAngle + sweepAngle * rangeStart;
        final rangeSweepAngle = sweepAngle * (rangeEnd - rangeStart);

        final rangePaint = Paint()
          ..color = range.color.withOpacity(0.3)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          rangeStartAngle,
          rangeSweepAngle,
          false,
          rangePaint,
        );
      }
    }

    // Vẽ giá trị hiện tại
    final normalizedValue = ((value - minValue) / (maxValue - minValue)).clamp(
      0.0,
      1.0,
    );
    final valueSweepAngle = sweepAngle * normalizedValue;

    final valuePaint = Paint()
      ..color = color
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

    // Vẽ kim chỉ
    final needleAngle = startAngle + valueSweepAngle;
    final needleLength = radius - strokeWidth / 2;

    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    // Vẽ tâm
    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class GaugeRange {
  final double start;
  final double end;
  final Color color;

  GaugeRange({required this.start, required this.end, required this.color});
}
