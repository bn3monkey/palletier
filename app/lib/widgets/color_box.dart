import 'package:flutter/material.dart';

import '../models/color_palette.dart';
import '../services/clipboard_service.dart';
import '../services/gvml_clipboard.dart';

class ColorBoxWidget extends StatelessWidget {
  final PaletteColor paletteColor;
  final ClipboardService clipboardService;
  final GvmlClipboard gvmlClipboard;

  const ColorBoxWidget({
    super.key,
    required this.paletteColor,
    required this.clipboardService,
    required this.gvmlClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Color area (80%)
          Expanded(
            flex: 8,
            child: Container(
              decoration: BoxDecoration(
                color: paletteColor.color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(8),
              child: Text(
                paletteColor.name,
                style: TextStyle(
                  color: _contrastColor(paletteColor.color),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          // Buttons area (20%)
          SizedBox(
            height: 36,
            child: Row(
              children: [
                _ActionButton(
                  icon: Icons.content_copy,
                  tooltip: 'Copy ${paletteColor.hex}',
                  onTap: () async {
                    await clipboardService.copyText(paletteColor.hex);
                  },
                ),
                _ActionButton(
                  icon: Icons.square,
                  tooltip: 'Copy PPT rect (long-press: test original)',
                  onTap: () async {
                    try {
                      await gvmlClipboard.copyRectangle(paletteColor.hexRaw);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rectangle copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                _ActionButton(
                  icon: Icons.circle,
                  tooltip: 'Copy PPT circle',
                  onTap: () async {
                    try {
                      await gvmlClipboard.copyEllipse(paletteColor.hexRaw);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Circle copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  void _handleTap() async {
    setState(() => _pressed = true);
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _pressed ? Colors.grey[300] : Colors.transparent,
            child: Center(
              child: Icon(
                widget.icon,
                size: 16,
                color: _pressed ? Colors.grey[900] : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
