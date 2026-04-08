import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/clipboard_service.dart';
import '../services/gvml_clipboard.dart';
import '../widgets/cli_connection_panel.dart';
import '../widgets/chat_panel.dart';
import '../widgets/palette_scroll_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ClipboardService clipboardService;
  final GvmlClipboard gvmlClipboard;

  const HomeScreen({
    super.key,
    required this.clipboardService,
    required this.gvmlClipboard,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _panelWidthRatio = 0.2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = constraints.maxWidth * _panelWidthRatio;

          return Row(
            children: [
              // Left: Palette area
              Expanded(
                child: PaletteScrollView(
                  clipboardService: widget.clipboardService,
                  gvmlClipboard: widget.gvmlClipboard,
                ),
              ),

              // Drag handle
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _panelWidthRatio -=
                        details.delta.dx / constraints.maxWidth;
                    _panelWidthRatio = _panelWidthRatio.clamp(0.15, 0.5);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 6,
                    color: Colors.grey[300],
                  ),
                ),
              ),

              // Right: Chat side panel
              SizedBox(
                width: panelWidth,
                child: const Column(
                  children: [
                    CliConnectionPanel(),
                    Expanded(child: ChatPanel()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
