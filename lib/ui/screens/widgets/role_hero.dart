import 'package:flutter/material.dart';

enum RoleKind { login, student, teacher, admin }

enum GenderKind { neutral, male, female }

/// Premium, flexible hero art for auth & role screens.
/// - Gapless image swaps & sized caching
/// - Clean fallbacks: poster → neutral → icon
/// - Background mode: neutral veil for readability (fixes color mixing)
class RoleHeroImage extends StatelessWidget {
  final RoleKind role;
  final GenderKind gender;
  final double height;
  final bool asBackground;

  /// Optional corner rounding for background usage.
  final BorderRadius? backgroundRadius;

  /// Veil strength for background gradient (0.0 → 1.0).
  final double veilOpacity;

  /// Veil base color (defaults to black to avoid tinted “color mixing”).
  final Color veilColor;

  /// Content alignment in background mode.
  final Alignment backgroundAlignment;

  /// BoxFit for background image.
  final BoxFit backgroundFit;

  const RoleHeroImage({
    super.key,
    required this.role,
    this.gender = GenderKind.neutral,
    this.height = 160,
    this.asBackground = false,
    this.backgroundRadius,
    this.veilOpacity = 0.22,
    this.veilColor = Colors.black, // neutral scrim by default
    this.backgroundAlignment = Alignment.center,
    this.backgroundFit = BoxFit.cover,
  }) : assert(height > 0);

  String get _assetPath {
    if (role == RoleKind.admin) return 'assets/images/admin_hero.png';
    final base = switch (role) {
      RoleKind.login => 'login_hero',
      RoleKind.student => 'student_hero',
      RoleKind.teacher => 'teacher_hero',
      RoleKind.admin => 'admin_hero',
    };
    final suffix = switch (gender) {
      GenderKind.male => 'male',
      GenderKind.female => 'female',
      GenderKind.neutral => 'neutral',
    };
    return 'assets/images/${base}_${suffix}.png';
  }

  String get _posterFallback => 'assets/images/skillseed_poster.jpg';

  String get _semanticLabel => switch (role) {
        RoleKind.login => 'Welcome illustration',
        RoleKind.student => 'Student illustration',
        RoleKind.teacher => 'Teacher illustration',
        RoleKind.admin => 'Admin illustration',
      };

  @override
  Widget build(BuildContext context) {
    final img = _assetPath;

    if (asBackground) {
      final radius = backgroundRadius;
      final veil = _buildVeil(opacity: veilOpacity.clamp(0, 1));

      final content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius ?? BorderRadius.zero,
          image: DecorationImage(
            image: AssetImage(img),
            fit: backgroundFit,
            alignment: backgroundAlignment,
            filterQuality: FilterQuality.medium,
            onError: (_, __) {}, // silent; veil still renders
          ),
        ),
        child: veil,
      );

      return radius == null
          ? content
          : ClipRRect(borderRadius: radius, child: content);
    }

    // Foreground (inline) usage with memory-friendly caching
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (height * dpr).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        image: true,
        label: _semanticLabel,
        child: _InlineAsset(
          path: img,
          posterFallback: _posterFallback,
          height: height,
          cacheWidth: cacheWidth,
        ),
      ),
    );
  }

  /// Neutral veil (uses [veilColor]) to keep foreground text readable.
  Widget _buildVeil({required double opacity}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            veilColor.withOpacity(opacity + 0.10),
            veilColor.withOpacity(opacity * 0.45),
            veilColor.withOpacity(0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

/// Internal: robust inline asset with poster → icon fallback and gapless swap.
class _InlineAsset extends StatelessWidget {
  const _InlineAsset({
    required this.path,
    required this.posterFallback,
    required this.height,
    required this.cacheWidth,
  });

  final String path;
  final String posterFallback;
  final double height;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          posterFallback,
          height: height,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_not_supported_outlined,
            size: height,
            color: Colors.white24,
          ),
        );
      },
    );
  }
}
