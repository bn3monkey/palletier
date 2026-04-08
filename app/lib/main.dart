import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/clipboard_service.dart';
import 'services/gvml_clipboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clipboardService = ClipboardService();
  final gvmlClipboard = GvmlClipboard();
  await gvmlClipboard.init();

  runApp(
    ProviderScope(
      child: PalletierApp(
        clipboardService: clipboardService,
        gvmlClipboard: gvmlClipboard,
      ),
    ),
  );
}
