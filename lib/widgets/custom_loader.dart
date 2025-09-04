import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;
  const CustomLoader({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
