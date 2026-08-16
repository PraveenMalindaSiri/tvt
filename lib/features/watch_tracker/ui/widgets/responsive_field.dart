import 'package:flutter/material.dart';

class ResponsiveField extends StatelessWidget {
  const ResponsiveField({required this.child, this.flex = 1, super.key});

  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) => child;
}
