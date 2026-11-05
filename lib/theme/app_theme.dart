import 'package:flutter/material.dart';

/// Soft pastel "spring flowers + hearts + alarm clock" palette.
class AccentPalette {
  final String name;
  final String emoji;
  final Color color;
  const AccentPalette(this.name, this.emoji, this.color);
}

const accentPalettes = [
  AccentPalette('Rose', '🌸', Color(0xFFE0618A)),
  AccentPalette('Mint', '🌿', Color(0xFF3DAE8C)),
  AccentPalette('Lavender', '💜', Color(0xFF8E6BD0)),
  AccentPalette('Sky', '🦋', Color(0xFF4A9AD6)),
  AccentPalette('Peach', '🍑', Color(0xFFEE8A5B)),
];

/// Soft clay-like card colours: [pastel] fill and a deeper [deep] accent.
class CardTone {
  final Color pastel;
  final Color deep;
  const CardTone(this.pastel, this.deep);
}

const _cardTones = [
  CardTone(Color(0xFFFFD3E2), Color(0xFFE0618A)), // blush pink
  CardTone(Color(0xFFC8F1E1), Color(0xFF3DAE8C)), // mint
  CardTone(Color(0xFFCCE6FB), Color(0xFF4A9AD6)), // sky blue
  CardTone(Color(0xFFE4D8F8), Color(0xFF8E6BD0)), // lavender
  CardTone(Color(0xFFFFDEC6), Color(0xFFEE8A5B)), // peach
  CardTone(Color(0xFFFFF2BE), Color(0xFFD99A00)), // butter yellow
];

CardTone cardToneFor(int? id) => _cardTones[(id ?? 0) % _cardTones.length];

const ink = Color(0xFF4A2740); // warm plum text
const inkDark = Color(0xFFF6EAF1);

Color inkOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? inkDark : ink;

List<Color> headerGradient(Color accent, bool dark) {
  final hsl = HSLColor.fromColor(accent);
  final shifted = hsl.withHue((hsl.hue + 25) % 360).toColor();
  if (dark) {
    return [
      Color.lerp(accent, Colors.black, 0.45)!,
      Color.lerp(shifted, Colors.black, 0.55)!,
    ];
  }
  return [
    Color.lerp(accent, Colors.white, 0.55)!,
    Color.lerp(shifted, Colors.white, 0.72)!,
  ];
}

Color surfaceCard(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2B2030)
        : Colors.white;

List<BoxShadow> softShadow(Color c) => [
      BoxShadow(
        color: c.withValues(alpha: 0.2),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];

InputDecoration softDecoration(BuildContext context, String label,
    {IconData? icon, String? hint}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: dark ? const Color(0xFF382B40) : const Color(0xFFFFEEF2),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
  );
}

ThemeData buildTheme(Color accent, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
      .copyWith(
    primary: accent,
    onPrimary: Colors.white,
    onSurface: dark ? inkDark : ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF1E1620) : const Color(0xFFFFF4F1),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: dark ? const Color(0xFF261C2B) : Colors.white,
      indicatorColor: accent.withValues(alpha: 0.22),
      labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
    ),
  );
}
