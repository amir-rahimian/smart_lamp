import 'dart:async';

import 'package:flutter/material.dart';

enum ToastPosition { top, bottom }

class Toast {
  static void showToast({required BuildContext context, required String message, ToastPosition position = ToastPosition.bottom}) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay != null) {
      final GlobalKey<_ToastViewState> key = GlobalKey();
      final overlayEntry = OverlayEntry(
        builder: (context) => ToastView(key: key, message: message, position: position, borderColor: Theme.of(context).colorScheme.secondary),
      );

      Overlay.of(context).insert(overlayEntry);

      Timer(const Duration(seconds: 5), () {
        overlayEntry.remove();
      });
    }
  }

  static void errorToast({required BuildContext context, required String message, ToastPosition position = ToastPosition.top}) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (overlay != null) {
      final GlobalKey<_ToastViewState> key = GlobalKey();
      final overlayEntry = OverlayEntry(
        builder: (context) => ToastView(key: key, message: message, position: position, borderColor: Theme.of(context).colorScheme.error),
      );

      Overlay.of(context).insert(overlayEntry);

      Timer(const Duration(seconds: 3), () {
        overlayEntry.remove();
      });
    }
  }
}

class ToastView extends StatefulWidget {
  final String message;
  final ToastPosition position;
  final Color borderColor;

  const ToastView({
    super.key,
    required this.message,
    required this.position,
    required this.borderColor,
  });

  @override
  _ToastViewState createState() => _ToastViewState();
}

class _ToastViewState extends State<ToastView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below the screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    Timer(const Duration(milliseconds: 3000), () {
      hideToast();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void hideToast() {
    if (mounted) {
      _animationController.reverse().whenComplete(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * (widget.position == ToastPosition.top ? 0.05 : 0.85),
      width: MediaQuery.of(context).size.width,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
