import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Route;

class InteractButton extends PositionComponent with TapCallbacks {
  bool _isPressed = false;
  final VoidCallback? onTap;

  InteractButton({this.onTap})
      : super(
          size: Vector2(120, 120),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      cx,
      Paint()..color = _isPressed ? Colors.blueGrey.shade700 : Colors.blueGrey.shade500,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      cx,
      Paint()
        ..color = Colors.white60
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Interact',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        (size.x - tp.width) / 2,
        (size.y - tp.height) / 2 - (size.x / 12),
      ),
    );

    final arrowTp = TextPainter(
      text: const TextSpan(
        text: 'Tap',
        style: TextStyle(color: Colors.white70, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    arrowTp.layout();
    arrowTp.paint(
      canvas,
      Offset(
        (size.x - arrowTp.width) / 2,
        (size.y - arrowTp.height) / 2 + (size.x / 8),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isPressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isPressed = false;
    onTap?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isPressed = false;
  }
}
