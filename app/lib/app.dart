import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/clipboard_service.dart';
import 'services/gvml_clipboard.dart';

class PalletierApp extends StatelessWidget {
  final ClipboardService clipboardService;
  final GvmlClipboard gvmlClipboard;

  const PalletierApp({
    super.key,
    required this.clipboardService,
    required this.gvmlClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palletier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(
        clipboardService: clipboardService,
        gvmlClipboard: gvmlClipboard,
      ),
    );
  }
}
