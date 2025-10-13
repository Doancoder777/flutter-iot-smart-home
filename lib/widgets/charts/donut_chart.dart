import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Biểu đồ hình tròn donut
class DonutChart extends StatefulWidget {
  final List<ChartSegment> segments;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final Widget? centerWidget;

  const DonutChart({
    Key? key,
    required this.segments,
    this.size = 200,
    this.strokeWidth = 30,
    this.duration = const Duration(milliseconds: 1000),
    this.centerWidget,
  }) : super(key: key);

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DonutChartPainter(
                  segments: widget.segments,
                  strokeWidth: widget.strokeWidth,
                  progress: _animation.value,
                ),
              ),
              if (widget.centerWidget != null) widget.centerWidget!,
            ],
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double strokeWidth;
  final double progress;

  _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    double startAngle = -math.pi / 2; // Bắt đầu từ 12 giờ
    double totalValue = segments.fold(0, (sum, segment) => sum + segment.value);

    for (var segment in segments) {
      final sweepAngle = (segment.value / totalValue) * 2 * math.pi * progress;

      final paint = Paint()
        ..color = segment.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ChartSegment {
  final String label;
  final double value;
  final Color color;

  ChartSegment({required this.label, required this.value, required this.color});
}
