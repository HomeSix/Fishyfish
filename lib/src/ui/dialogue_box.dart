import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Route;

class DialogueBox extends PositionComponent with TapCallbacks {
  final void Function()? onDismissCallback;
  String name = '';
  String text = '';
  bool _isVisible = false;

  DialogueBox({this.onDismissCallback}) : super(anchor: Anchor.bottomCenter);

  bool get isVisible => _isVisible;

  void show(String npcName, String dialogue) {
    name = npcName;
    text = dialogue;
    _isVisible = true;
  }

  void dismiss() {
    _isVisible = false;
    try {
      onDismissCallback?.call();
    } catch (_) {
      // ignore callback errors
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return _isVisible && super.containsLocalPoint(point);
  }

  @override
  void render(Canvas canvas) {
    if (!_isVisible) return;

    final boxWidth = size.x;
    final boxHeight = size.y;
    final rect = Rect.fromLTWH(0, 0, boxWidth, boxHeight);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawRRect(
      rRect.shift(const Offset(1, 1)),
      Paint()..color = Colors.black45,
    );

    canvas.drawRRect(
      rRect,
      Paint()..color = const Color(0xDD1A1A2E),
    );

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.save();
    canvas.clipRRect(rRect);

      final displayName = name == 'System' ? 'Sistem' : name;
      final nameTp = TextPainter(
        text: TextSpan(
          text: displayName,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    nameTp.layout();
    nameTp.paint(canvas, const Offset(20, 14));

    final textTp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    );
    textTp.layout(maxWidth: boxWidth - 40);
    textTp.paint(canvas, const Offset(20, 44));

    final continueTp = TextPainter(
      text: const TextSpan(
        text: 'Tekan untuk tutup',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    continueTp.layout();
    continueTp.paint(
      canvas,
      Offset(boxWidth - continueTp.width - 16, boxHeight - 24),
    );

    canvas.restore();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_isVisible) {
      dismiss();
    }
  }
}
