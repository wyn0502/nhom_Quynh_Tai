import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';

class RolePalette extends StatelessWidget {
  final Widget child;

  const RolePalette({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;
    final base = Theme.of(context);
    final dark = base.brightness == Brightness.dark;
    final color = auth.isAdmin
        ? const Color(0xFF2563EB)
        : auth.isBuildingManager
            ? const Color(0xFF0F766E)
            : const Color(0xFF4F46E5);

    final scheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: base.brightness,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor:
            dark ? const Color(0xFF101820) : scheme.surfaceContainerLowest,
        cardColor: dark
            ? const Color(0xFF182431)
            : scheme.surfaceContainerLow,
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: scheme.surface,
          enabledBorder: border,
          border: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primaryContainer,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: 11,
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          selectedColor: scheme.primaryContainer,
          backgroundColor: scheme.surface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        dividerColor: scheme.outlineVariant,
      ),
      child: child,
    );
  }
}