import 'package:flutter/material.dart';
import 'app_exception.dart';

mixin ErrorHandler {
  void handleError(Object e, {BuildContext? context}) {
    final message = e is AppException ? e.message : 'An unexpected error occurred';
    debugPrint('Error: $e');
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
