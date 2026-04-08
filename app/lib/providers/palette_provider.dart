import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/color_palette.dart';

/// Stores history of all palettes (newest last).
final paletteProvider =
    NotifierProvider<PaletteNotifier, List<ColorPalette>>(PaletteNotifier.new);

class PaletteNotifier extends Notifier<List<ColorPalette>> {
  @override
  List<ColorPalette> build() => [];

  void addPalette(ColorPalette palette) {
    state = [...state, palette];
  }

  void clear() {
    state = [];
  }
}
