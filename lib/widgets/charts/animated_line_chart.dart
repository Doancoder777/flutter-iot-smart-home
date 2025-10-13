import 'package:flutter/material.dart';

/// Biểu đồ đường với animation
class AnimatedLineChart extends StatefulWidget {
  final List<double> dataPoints;
  final List<String> labels;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Duration duration;
  final String? unit;

  const AnimatedLineChart({
    Key? key,
    required this.dataPoints,
    required this.labels,
    required this.minValue,
    required this.maxValue,
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
    this.duration = const Duration(milliseconds: 1000),
    this.unit,
  }) : super(key: key);

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
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
        return CustomPaint(
          painter: _LineChartPainter(
            dataPoints: widget.dataPoints,
            labels: widget.labels,
            minValue: widget.minValue,
            maxValue: widget.maxValue,
            lineColor: widget.lineColor,
            fillColor: widget.fillColor.withOpacity(0.2),
            progress: _animation.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final double progress;

  _LineChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final spacing = size.width / (dataPoints.length - 1);

    // Tính toán điểm
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue =
          (dataPoints[i] - minValue) / (maxValue - minValue);
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Chỉ vẽ phần đã progress
        final progressPoints = (dataPoints.length * progress).floor();
        if (i <= progressPoints) {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }

      // Vẽ điểm
      if (i <= (dataPoints.length * progress).floor()) {
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
      }
    }

    // Đóng fill path
    final lastProgressPoint = (dataPoints.length * progress).floor();
    if (lastProgressPoint > 0) {
      final lastX = lastProgressPoint * spacing;
      fillPath.lineTo(lastX, size.height);
      fillPath.close();
    }

    // Vẽ fill trước, line sau
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Vẽ labels
    for (int i = 0; i < labels.length; i++) {
      final x = i * spacing;
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.dataPoints != dataPoints;
  }
}
