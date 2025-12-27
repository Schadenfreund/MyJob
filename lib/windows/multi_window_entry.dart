import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'pdf_preview_window.dart';

/// Entry point for multi-window support
/// This is called when a new window is created
/// Args format: ['multi_window', windowId, argumentsJson]
void main(List<String> args) {
  if (args.length < 2) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Invalid window arguments')),
      ),
    ));
    return;
  }

  // Args: [0] = 'multi_window', [1] = windowId as string, [2] = arguments JSON
  final windowId = int.parse(args[1]);
  final windowController = WindowController.fromWindowId(windowId);

  // Parse arguments from the main window
  final argsJson = args.length > 2 ? args[2] : '{}';

  Map<String, dynamic> arguments;
  try {
    arguments = jsonDecode(argsJson) as Map<String, dynamic>;
  } catch (e) {
    arguments = {};
    debugPrint('Error parsing window arguments: $e');
  }

  runApp(PdfPreviewWindow(
    windowController: windowController,
    args: arguments,
  ));
}
