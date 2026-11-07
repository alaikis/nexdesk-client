import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/window_title_bar.dart';

class NexScaffold extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;

  const NexScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WindowTitleBar(),
        Expanded(
          child: Scaffold(
            body: body,
            backgroundColor: backgroundColor,
            appBar: appBar,
            drawer: drawer,
            endDrawer: endDrawer,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            bottomNavigationBar: bottomNavigationBar,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          ),
        ),
      ],
    );
  }
}