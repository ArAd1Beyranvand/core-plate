import 'package:flutter/material.dart';

import 'special_clipper.dart';

class PlateFrame extends StatelessWidget {
  const PlateFrame({
    super.key,
    required this.isCompleted,
    required this.activeColor,
    required this.inactiveColor,
    required this.backgroundColor,
    required this.borderWidth,
    required this.child,
  });

  final bool isCompleted;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;
  final double borderWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCompleted ? activeColor : inactiveColor;
    return ClipRRect(
      clipper: SpecialClipper(),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          color: borderColor,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: ClipRRect(
          clipBehavior: Clip.hardEdge,
          clipper: SpecialClipper(),
          child: Container(
            color: backgroundColor,
            child: child,
          ),
        ),
      ),
    );
  }
}
