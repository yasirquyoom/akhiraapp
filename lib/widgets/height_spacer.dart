import 'package:flutter/widgets.dart';

class HeightSpacer extends StatelessWidget {
  final double height;
  const HeightSpacer(this.height, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}
