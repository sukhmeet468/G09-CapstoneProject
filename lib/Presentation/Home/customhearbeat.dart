import 'package:flutter/material.dart';

class HeartbeatLine extends StatefulWidget {
  final bool isLoading;

  const HeartbeatLine({required this.isLoading});

  @override
  State<HeartbeatLine> createState() => _HeartbeatLineState();
}

class _HeartbeatLineState extends State<HeartbeatLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          if (widget.isLoading) {
            _controller.forward();
          }
        } else if (status == AnimationStatus.dismissed) {
          if (widget.isLoading) {
            _controller.forward();
          }
        }
      });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    if (widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant HeartbeatLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displaying only Wi-Fi status icon
            Icon(
              widget.isLoading ? Icons.wifi : Icons.wifi_off,
              color: widget.isLoading ? Colors.green : Colors.red,
              size: 30,
            ),
            const SizedBox(height: 8), // Space between icon and animation
            // If connected, show heartbeat animation below the Wi-Fi icon
            if (widget.isLoading)
              CustomPaint(
                size: const Size(20, 5), // Adjust the width of the heartbeat line
                painter: HeartbeatLinePainter(progress: _animation.value),
              ),
          ],
        );
      },
    );
  }
}

class HeartbeatLinePainter extends CustomPainter {
  final double progress;

  HeartbeatLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.green // Use green for online status
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    const double startX = 20;
    final double endX = size.width * progress;

    canvas.drawLine(
      Offset(startX, size.height / 2),
      Offset(endX, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}