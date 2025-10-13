import 'package:flutter/material.dart';

/// Biểu đồ cột với animation
class AnimatedBarChart extends StatefulWidget {
  final List<ChartData> data;
  final double maxValue;
  final Color barColor;
  final Duration duration;
  final String? unit;

  const AnimatedBarChart({
    Key? key,
    required this.data,
    required this.maxValue,
    this.barColor = Colors.blue,
    this.duration = const Duration(milliseconds: 800),
    this.unit,
  }) : super(key: key);

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
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
        return CustomPaint(
          painter: _BarChartPainter(
            data: widget.data,
            maxValue: widget.maxValue,
            barColor: widget.barColor,
            progress: _animation.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<ChartData> data;
  final double maxValue;
  final Color barColor;
  final double progress;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / data.length * 0.7;
    final spacing = size.width / data.length * 0.3;

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth + spacing) + spacing / 2;
      final barHeight = (data[i].value / maxValue) * size.height * progress;
      final y = size.height - barHeight;

      // Vẽ cột
      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, paint);

      // Vẽ label
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height + 5),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}
