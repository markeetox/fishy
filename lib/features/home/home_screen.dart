import 'package:flutter/material.dart';
import '../../core/gradient_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Home screen content
    return const GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.expand(),
      ),
    );
  }
}
