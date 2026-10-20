import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extra tokens the Material [ColorScheme] has no slot for.
class BloomExtras extends ThemeExtension<BloomExtras> {
  const BloomExtras({
    required this.ringTrack,
    required this.shadow1,
    required this.shadow2,
    required this.shadow3,
  });

  final Color ringTrack;
  final List<BoxShadow> shadow1;
  final List<BoxShadow> shadow2;
  final List<BoxShadow> shadow3;

  static BloomExtras of(BuildContext context) =>
      Theme.of(context).extension<BloomExtras>() ?? bloomExtras(Brightness.light);

  @override
  BloomExtras copyWith({
    Color? ringTrack,
    List<BoxShadow>? shadow1,
    List<BoxShadow>? shadow2,
    List<BoxShadow>? shadow3,
  }) => BloomExtras(
    ringTrack: ringTrack ?? this.ringTrack,
    shadow1: shadow1 ?? this.shadow1,
    shadow2: shadow2 ?? this.shadow2,
    shadow3: shadow3 ?? this.shadow3,
  );

  @override
  BloomExtras lerp(ThemeExtension<BloomExtras>? other, double t) {
    if (other is! BloomExtras) return this;
    return BloomExtras(
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      shadow1: BoxShadow.lerpList(shadow1, other.shadow1, t)!,
      shadow2: BoxShadow.lerpList(shadow2, other.shadow2, t)!,
      shadow3: BoxShadow.lerpList(shadow3, other.shadow3, t)!,
    );
  }
}

BloomExtras bloomExtras(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const BloomExtras(
      ringTrack: Color(0xFF33372F),
      shadow1: [BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1))],
      shadow2: [BoxShadow(color: Color(0x73000000), blurRadius: 12, offset: Offset(0, 4))],
      shadow3: [BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, 12))],
    );
  }
  return const BloomExtras(
    ringTrack: Color(0xFFE3E8DB),
    shadow1: [
      BoxShadow(color: Color(0x141B2118), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F1B2118), blurRadius: 3, offset: Offset(0, 1)),
    ],
    shadow2: [
      BoxShadow(color: Color(0x1A1B2118), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x0F1B2118), blurRadius: 4, offset: Offset(0, 2)),
    ],
    shadow3: [BoxShadow(color: Color(0x291B2118), blurRadius: 32, offset: Offset(0, 12))],
  );
}

ColorScheme bloomScheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ColorScheme.fromSeed(
    seedColor: const Color(0xFF3A6B4E),
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFA1D4AB) : const Color(0xFF3A6B4E),
    onPrimary: dark ? const Color(0xFF07381A) : const Color(0xFFFFFFFF),
    primaryContainer: dark ? const Color(0xFF235234) : const Color(0xFFBCF0C6),
    onPrimaryContainer: dark ? const Color(0xFFBCF0C6) : const Color(0xFF00210D),
    secondary: dark ? const Color(0xFFB9CCB3) : const Color(0xFF52634F),
    onSecondary: dark ? const Color(0xFF243424) : const Color(0xFFFFFFFF),
    secondaryContainer: dark ? const Color(0xFF3A4B38) : const Color(0xFFD5E8CF),
    onSecondaryContainer: dark ? const Color(0xFFD5E8CF) : const Color(0xFF101F10),
    tertiary: dark ? const Color(0xFFA2CED3) : const Color(0xFF38656A),
    surface: dark ? const Color(0xFF11140F) : const Color(0xFFF7FAF2),
    onSurface: dark ? const Color(0xFFE2E3DC) : const Color(0xFF1B2118),
    onSurfaceVariant: dark ? const Color(0xFFC3C8BC) : const Color(0xFF43483F),
    surfaceContainerLowest: dark ? const Color(0xFF1A1E18) : const Color(0xFFFFFFFF),
    surfaceContainerLow: dark ? const Color(0xFF1E221B) : const Color(0xFFF2F5EC),
    surfaceContainer: dark ? const Color(0xFF1A1E18) : const Color(0xFFFFFFFF),
    surfaceContainerHigh: dark ? const Color(0xFF23271F) : const Color(0xFFEDF1E8),
    surfaceContainerHighest: dark ? const Color(0xFF23271F) : const Color(0xFFEDF1E8),
    outline: dark ? const Color(0xFF8D9287) : const Color(0xFFC3C8BC),
    outlineVariant: dark ? const Color(0xFF33372F) : const Color(0xFFE2E6DA),
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
    onError: dark ? const Color(0xFF690005) : const Color(0xFFFFFFFF),
    // Drives the snackbar, which is a dark bar in both themes.
    inverseSurface: dark ? const Color(0xFF3A3D36) : const Color(0xFF2F3429),
    onInverseSurface: dark ? const Color(0xFFEDF1E8) : const Color(0xFFEDF1E8),
    scrim: dark ? const Color(0x8C000000) : const Color(0x6B101810),
  );
}

ThemeData bloomTheme(Brightness brightness) {
  final scheme = bloomScheme(brightness);
  final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    extensions: [bloomExtras(brightness)],
    splashFactory: InkRipple.splashFactory,
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: GoogleFonts.dmSans(color: scheme.onInverseSurface, fontSize: 13),
      actionTextColor: scheme.primaryContainer,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

/// First character of a user-supplied name, used by the avatar.
String initialOf(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// Typography helpers mirroring the CSS `--font-display` / `--font-body` split.
abstract final class BloomText {  /// Manrope — headings and numbers.
  static TextStyle display(
    double size,
    FontWeight weight, {
    double? letterSpacing,
    double? height,
    Color? color,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );

  /// DM Sans — everything else.
  static TextStyle body(
    double size,
    FontWeight weight, {
    double? letterSpacing,
    double? height,
    Color? color,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color,
  );
}
