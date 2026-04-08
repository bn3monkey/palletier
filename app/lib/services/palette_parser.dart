import 'dart:convert';

import '../models/color_palette.dart';

class PaletteParser {
  static final _jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)```');

  /// Parse AI response text and extract ColorPalette from JSON code block.
  ColorPalette? parse(String response) {
    final match = _jsonBlockRegex.firstMatch(response);
    if (match == null) return null;

    try {
      final jsonStr = match.group(1)!.trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ColorPalette.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
