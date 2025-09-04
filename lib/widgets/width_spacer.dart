import 'package:flutter/widgets.dart';

class WidthSpacer extends StatelessWidget {
  final double width;
  const WidthSpacer(this.width, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
