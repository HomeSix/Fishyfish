import 'package:flame/sprite.dart';

SpriteAnimation createColumnAnimation(
  SpriteSheet spriteSheet,
  int column,
  int frameCount,
  double stepTime,
) {
  final frames = <SpriteAnimationFrame>[];

  for (int row = 0; row < frameCount; row++) {
    final sprite = spriteSheet.getSprite(row, column);
    frames.add(SpriteAnimationFrame(sprite, stepTime));
  }

  return SpriteAnimation(frames);
}