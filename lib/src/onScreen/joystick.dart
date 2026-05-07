import 'package:flame/components.dart';
import 'package:flutter/material.dart';

JoystickComponent createJoystick() {
  return JoystickComponent(
    knob: CircleComponent(
      radius: 30,
      paint: Paint()..color = Colors.white.withOpacity(0.8),
    ),
    background: CircleComponent(
      radius: 60,
      paint: Paint()..color = Colors.grey.withOpacity(0.5),
    ),
    margin: const EdgeInsets.only(left: 130, bottom: 75),
  );
}