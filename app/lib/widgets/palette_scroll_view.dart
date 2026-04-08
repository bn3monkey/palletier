import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/color_palette.dart';
import '../providers/palette_provider.dart';
import '../services/clipboard_service.dart';
import '../services/gvml_clipboard.dart';
import 'color_box.dart';

class PaletteScrollView extends ConsumerStatefulWidget {
  final ClipboardService clipboardService;
  final GvmlClipboard gvmlClipboard;

  const PaletteScrollView({
    super.key,
    required this.clipboardService,
    required this.gvmlClipboard,
  });

  @override
  ConsumerState<PaletteScrollView> createState() => _PaletteScrollViewState();
}

class _PaletteScrollViewState extends ConsumerState<PaletteScrollView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palettes = ref.watch(paletteProvider);

    ref.listen(paletteProvider, (_, _) => _scrollToBottom());

    if (palettes.isEmpty) {
      return const Center(
        child: Text(
          'AI에게 원하는 색상 느낌을 알려주세요',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: palettes.length,
      itemBuilder: (context, index) {
        return _PaletteRow(
          palette: palettes[index],
          clipboardService: widget.clipboardService,
          gvmlClipboard: widget.gvmlClipboard,
        );
      },
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final ColorPalette palette;
  final ClipboardService clipboardService;
  final GvmlClipboard gvmlClipboard;

  const _PaletteRow({
    required this.palette,
    required this.clipboardService,
    required this.gvmlClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 4),
          child: Text(
            palette.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: palette.colors.length,
            itemBuilder: (context, index) {
              return ColorBoxWidget(
                paletteColor: palette.colors[index],
                clipboardService: clipboardService,
                gvmlClipboard: gvmlClipboard,
              );
            },
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
