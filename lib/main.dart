import 'package:flame/events.dart';
import 'dart:math' as math;
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

void main() {
  runApp(GameWidget(game: FishyFish()));
}

class FishyFish extends FlameGame {
  late SpriteAnimation downAnimation;
  late SpriteAnimation leftAnimation;
  late SpriteAnimation rightAnimation;
  late SpriteAnimation upAnimation;
  late SpriteAnimation idleAnimation;

  late SpriteAnimationComponent apin;
  late JoystickComponent joystick;

  // Movement speed
  final double speed = 200;
  final double characterSize = 100;
  final double characterSpeed = 0.15;

  // idle = 0, 1=left, 2=right, 3=down, 4=up
  int direction = 0;

  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSheet = SpriteSheet(
      image: await images.load('Apin.png'),
      srcSize: Vector2(32, 32),
    );

    // Column 0: Down, Column 1: Left, Column 2: Up, Column 3: Right
    downAnimation = _createColumnAnimation(
      spriteSheet,
      column: 0,
      frameCount: 8,
    );
    leftAnimation = _createColumnAnimation(
      spriteSheet,
      column: 1,
      frameCount: 8,
    );
    upAnimation = _createColumnAnimation(spriteSheet, column: 2, frameCount: 8);
    rightAnimation = _createColumnAnimation(
      spriteSheet,
      column: 3,
      frameCount: 8,
    );
    idleAnimation = _createColumnAnimation(
      spriteSheet,
      column: 0,
      frameCount: 1,
    );

    apin = SpriteAnimationComponent()
      ..animation = idleAnimation
      ..position = Vector2(100, 200)
      ..size = Vector2.all(characterSize)
      ..anchor = Anchor.center;

    add(apin);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 30,
        paint: Paint()..color = Colors.white.withOpacity(0.8),
      ),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = Colors.grey.withOpacity(0.5),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (joystick.direction != JoystickDirection.idle) {
      final delta = joystick.delta;

      if (delta.length > 0) {
        final movement = delta.normalized() * speed * dt;
        apin.position += movement;

        // FIXED: Use atan2 for correct angle calculation
        // In Flame: +Y is down, so we need to flip Y for standard math
        final angle = math.atan2(-delta.y, delta.x);
        final degrees = angle * 180 / math.pi;

        // Right: -45 to 45, Up: 45 to 135, Left: 135 to -135, Down: -135 to -45
        if (degrees >= -45 && degrees < 45) {
          apin.animation = rightAnimation;
          direction = 2;
        } else if (degrees >= 45 && degrees < 135) {
          apin.animation = upAnimation;
          direction = 4;
        } else if (degrees >= 135 || degrees < -135) {
          apin.animation = leftAnimation;
          direction = 1;
        } else {
          apin.animation = downAnimation;
          direction = 3;
        }
      }
    } else {
      apin.animation = idleAnimation;
      direction = 0;
    }

    // Keep apin within screen bounds
    apin.position.clamp(
      Vector2.zero() + Vector2.all(apin.size.x / 2),
      size - Vector2.all(apin.size.x / 2),
    );
  }

  @override
  void onTapUp(TapUpInfo info) {
    print('change animation');
  }

  SpriteAnimation _createColumnAnimation(
    SpriteSheet spriteSheet, {
    required int column,
    required int frameCount,
    double? stepTime, // <-- Changed to nullable, no default
  }) {
    final frames = <SpriteAnimationFrame>[];

    for (int row = 0; row < frameCount; row++) {
      final sprite = spriteSheet.getSprite(row, column);
      // Use characterSpeed if stepTime not provided
      frames.add(SpriteAnimationFrame(sprite, stepTime ?? characterSpeed));
    }

    return SpriteAnimation(frames);
  }
}
