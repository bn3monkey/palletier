import 'dart:ui';

class PaletteColor {
  final String name;
  final String hex;
  final int r;
  final int g;
  final int b;
  final String description;

  const PaletteColor({
    required this.name,
    required this.hex,
    required this.r,
    required this.g,
    required this.b,
    required this.description,
  });

  Color get color => Color.fromARGB(255, r, g, b);

  /// HEX without '#' prefix, for GVML XML
  String get hexRaw => hex.replaceFirst('#', '');

  String get rgbString => 'rgb($r, $g, $b)';

  factory PaletteColor.fromJson(Map<String, dynamic> json) {
    return PaletteColor(
      name: json['name'] as String,
      hex: json['hex'] as String,
      r: json['r'] as int,
      g: json['g'] as int,
      b: json['b'] as int,
      description: json['description'] as String,
    );
  }
}

class ColorPalette {
  final String description;
  final List<PaletteColor> colors;

  const ColorPalette({
    required this.description,
    required this.colors,
  });

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      description: json['description'] as String,
      colors: (json['colors'] as List)
          .map((c) => PaletteColor.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
