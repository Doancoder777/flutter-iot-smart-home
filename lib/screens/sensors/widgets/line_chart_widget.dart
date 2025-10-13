import 'package:flutter/material.dart';

/// Widget biểu đồ đường đơn giản
class LineChartWidget extends StatelessWidget {
  final List<double> dataPoints;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final double height;
  final bool showDots;

  const LineChartWidget({
    Key? key,
    required this.dataPoints,
    required this.minValue,
    required this.maxValue,
    this.lineColor = Colors.blue,
    this.fillColor = Colors.blue,
    this.height = 150,
    this.showDots = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          dataPoints: dataPoints,
          minValue: minValue,
          maxValue: maxValue,
          lineColor: lineColor,
          fillColor: fillColor.withOpacity(0.2),
          showDots: showDots,
        ),
        child: Container(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final bool showDots;

  _LineChartPainter({
    required this.dataPoints,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final spacing = size.width / (dataPoints.length - 1);

    // Tạo path
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
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Đóng fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Vẽ fill trước
    canvas.drawPath(fillPath, fillPaint);

    // Vẽ line
    canvas.drawPath(path, paint);

    // Vẽ dots nếu cần
    if (showDots) {
      for (int i = 0; i < dataPoints.length; i++) {
        final x = i * spacing;
        final normalizedValue =
            (dataPoints[i] - minValue) / (maxValue - minValue);
        final y = size.height - (normalizedValue * size.height);

        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill,
        );

        // Viền trắng cho dot
        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}
