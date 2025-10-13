import 'package:flutter/material.dart';

/// Widget hiệu ứng slide (trượt vào)
class SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final Offset endOffset;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.beginOffset = const Offset(0, 1), // Từ dưới lên
    this.endOffset = Offset.zero,
  }) : super(key: key);

  /// Slide từ trái sang
  const SlideAnimation.fromLeft({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) : this(
         key: key,
         child: child,
         duration: duration,
         delay: delay,
         curve: curve,
         beginOffset: const Offset(-1, 0),
       );

  /// Slide từ phải sang
  const SlideAnimation.fromRight({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) : this(
         key: key,
         child: child,
         duration: duration,
         delay: delay,
         curve: curve,
         beginOffset: const Offset(1, 0),
       );

  /// Slide từ trên xuống
  const SlideAnimation.fromTop({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) : this(
         key: key,
         child: child,
         duration: duration,
         delay: delay,
         curve: curve,
         beginOffset: const Offset(0, -1),
       );

  /// Slide từ dưới lên
  const SlideAnimation.fromBottom({
    Key? key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
  }) : this(
         key: key,
         child: child,
         duration: duration,
         delay: delay,
         curve: curve,
         beginOffset: const Offset(0, 1),
       );

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child);
  }
}
