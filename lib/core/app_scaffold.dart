import 'package:flutter/material.dart';
import 'gradient_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? topBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final GradientVariant variant;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.variant = GradientVariant.blue,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      variant: variant,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: topBar != null
            ? Stack(
                children: [
                  body,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: topBar!,
                  ),
                ],
              )
            : body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}
