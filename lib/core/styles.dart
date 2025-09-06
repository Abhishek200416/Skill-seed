// lib/core/styles.dart
import 'package:flutter/material.dart';

@immutable
class AppShadows {
  final List<BoxShadow> xl;
  final List<BoxShadow> lg;
  final List<BoxShadow> md;
  const AppShadows._({
    required this.xl,
    required this.lg,
    required this.md,
  });

  factory AppShadows.dark() => const AppShadows._(
        xl: [
          BoxShadow(
              color: Colors.black54, blurRadius: 32, offset: Offset(0, 24))
        ],
        lg: [
          BoxShadow(
              color: Colors.black45, blurRadius: 22, offset: Offset(0, 12))
        ],
        md: [
          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8))
        ],
      );
}

@immutable
class AppRadii {
  final BorderRadius card;
  final BorderRadius chip;
  const AppRadii({required this.card, required this.chip});
  factory AppRadii.defaults() => AppRadii(
        card: BorderRadius.circular(20),
        chip: BorderRadius.circular(12),
      );
}

@immutable
class AppGradients {
  final Gradient page;
  final Gradient brand;
  final Gradient button;
  const AppGradients._(
      {required this.page, required this.brand, required this.button});

  factory AppGradients.indigo() => const AppGradients._(
        page: LinearGradient(
            colors: [Color(0xFF0C1337), Color(0xFF121C4C), Color(0xFF1B2A6B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        brand: LinearGradient(
            colors: [Color(0xFF6C89FF), Color(0xFF9EA7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        button: LinearGradient(
            colors: [Color(0xFF6C89FF), Color(0xFF53E3FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      );
}

class AppStyles extends ThemeExtension<AppStyles> {
  final AppShadows shadows;
  final AppRadii radii;
  final AppGradients gradients;

  const AppStyles(
      {required this.shadows, required this.radii, required this.gradients});

  factory AppStyles.defaults() => AppStyles(
        shadows: AppShadows.dark(),
        radii: AppRadii.defaults(),
        gradients: AppGradients.indigo(),
      );

  @override
  AppStyles copyWith(
      {AppShadows? shadows, AppRadii? radii, AppGradients? gradients}) {
    return AppStyles(
      shadows: shadows ?? this.shadows,
      radii: radii ?? this.radii,
      gradients: gradients ?? this.gradients,
    );
  }

  @override
  AppStyles lerp(ThemeExtension<AppStyles>? other, double t) {
    // Simple: do not interpolate complex objects; just switch.
    return t < 0.5 ? this : (other as AppStyles);
  }
}

extension AppTheme on BuildContext {
  AppStyles get s =>
      Theme.of(this).extension<AppStyles>() ?? AppStyles.defaults();
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Glass(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.s;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(.72),
        borderRadius: s.radii.card,
        border:
            Border.all(color: scheme.onSurface.withOpacity(.08), width: 1.2),
        boxShadow: s.shadows.lg,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class AnimatedPageGradient extends StatelessWidget {
  const AnimatedPageGradient({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final g = context.s.gradients.page;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(gradient: g),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loading = false,
  });
  final VoidCallback? onPressed;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          padding:
              const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: s.radii.chip),
          ),
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          foregroundColor:
              WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
          overlayColor: const WidgetStatePropertyAll(Colors.white12),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: s.gradients.button,
            borderRadius: s.radii.chip,
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 48),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('spinner'),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(key: const ValueKey('label'), label),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple password strength meter (length-only baseline; extend with entropy later)
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.value});
  final double value; // 0..1
  @override
  Widget build(BuildContext context) {
    final clr = Theme.of(context).colorScheme;
    Color color;
    if (value < .34)
      color = Colors.redAccent;
    else if (value < .67)
      color = Colors.amber;
    else
      color = Colors.lightGreenAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        minHeight: 6,
        backgroundColor: clr.onSurface.withOpacity(.12),
        valueColor: AlwaysStoppedAnimation(color),
        value: value.clamp(0, 1),
      ),
    );
  }
}
