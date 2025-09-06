import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/styles.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  _ResumeHint? _resume; // null => brand-new users see no "Resume"
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    // TODO: wire to persistence if needed.
    setState(() => _resume = null);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() async =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final base = Theme.of(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    // Local "quiet" theme — removes splashes/overlays and keeps surfaces calm.
    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: MaterialStatePropertyAll(Colors.transparent),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: base.colorScheme.onSurface.withOpacity(.18),
        cursorColor: base.colorScheme.onSurface,
        selectionHandleColor: base.colorScheme.onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: Colors.transparent, // glass-wrapped below
        indicatorColor: base.colorScheme.primary.withOpacity(.10),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: MaterialStatePropertyAll(
          base.textTheme.labelSmall?.copyWith(
            letterSpacing: .2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return Theme(
      data: quiet,
      child: Scaffold(
        extendBody: true, // lets content flow under frosted nav
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,

        // ░░ Aurora gradient backdrop (fade-in + no overscroll glow) ░░
        body: _AuroraBackdrop(
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onPanDown: (_) => FocusScope.of(context).unfocus(),
              onTap: () => FocusScope.of(context).unfocus(),
              child: ScrollConfiguration(
                behavior: const _NoGlowScrollBehavior(),
                child: RefreshIndicator.adaptive(
                  onRefresh: _refresh,
                  color: base.colorScheme.onSurface,
                  backgroundColor: base.colorScheme.surface.withOpacity(.90),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      // ── AppBar (crisp, no animated color flashes)
                      SliverAppBar(
                        pinned: true,
                        floating: true,
                        snap: true,
                        surfaceTintColor: Colors.transparent,
                        backgroundColor:
                            base.colorScheme.surface.withOpacity(.78),
                        titleTextStyle: base.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                        title: const Text('Student'),
                        actions: [
                          // Use push() so this screen stays in stack without re-creating.
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => context.push('/notifications'),
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          IconButton(
                            tooltip: 'Profile',
                            onPressed: () => context.push('/profile'),
                            icon: const Icon(Icons.person_outline),
                          ),
                        ],
                      ),

                      // ── Welcome
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                        sliver: SliverToBoxAdapter(
                          child: Glass(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  child: Icon(Icons.psychology_alt_outlined),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Build your soft-skills',
                                        style: base.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pick a category to get started',
                                        style:
                                            base.textTheme.bodyMedium?.copyWith(
                                          color: base.colorScheme.onSurface
                                              .withOpacity(.80),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => context.push(
                                      '/leaderboard?category=COMMUNICATION'),
                                  icon: const Icon(Icons.leaderboard),
                                  label: const Text('Leaderboard'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Pinned search
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchHeader(
                          child: _SearchBar(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: (v) => setState(() => _query = v.trim()),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                              HapticFeedback.selectionClick();
                            },
                            hasText: _query.isNotEmpty,
                          ),
                        ),
                      ),

                      // ── Quick actions
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        sliver: SliverToBoxAdapter(
                          child: Glass(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _QuickPill(
                                    icon: Icons.history,
                                    label: 'Continue',
                                    onTap: () => context.push(
                                        '/student/category?name=COMMUNICATION'),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickPill(
                                    icon: Icons.play_circle_outline,
                                    label: 'Upcoming live',
                                    onTap: () => context.push(
                                        '/student/category?name=TEAMWORK'),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickPill(
                                    icon: Icons.fact_check_outlined,
                                    label: 'Practice & tests',
                                    onTap: () => context.push(
                                        '/student/category?name=PROBLEM SOLVING'),
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickPill(
                                    icon: Icons.notifications_active_outlined,
                                    label: 'Alerts',
                                    onTap: () => context.push('/notifications'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Conditional "Resume"
                      if (_resume != null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          sliver: SliverToBoxAdapter(
                            child: Glass(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                      child: Icon(Icons.play_arrow)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _resume!.title,
                                          style: base.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: .2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Resume where you left last time',
                                          style: base.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: base.colorScheme.onSurface
                                                .withOpacity(.80),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        context.push(_resume!.route),
                                    child: const Text('Resume'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ── Category grid
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        sliver: SliverToBoxAdapter(
                          child: RepaintBoundary(
                            child: _CategoryGrid(
                              key: const PageStorageKey('category-grid'),
                              query: _query,
                            ),
                          ),
                        ),
                      ),

                      // Spacer so last row never hides beneath frosted nav
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height:
                              bottomSafe + _FrostedNavigationBar.kHeight + 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Frosted bottom nav (blurred, translucent)
        bottomNavigationBar: _FrostedNavigationBar(
          index: _navIndex,
          onChanged: (i) {
            // Keep this dashboard instance alive: push routes instead of go.
            setState(() => _navIndex = i);
            if (i == 0) return;
            if (i == 1) {
              context.push('/leaderboard?category=COMMUNICATION');
            } else if (i == 2) {
              context.push('/notifications');
            } else if (i == 3) {
              context.push('/profile');
            }
          },
        ),
      ),
    );
  }
}

/* ───────── models/helpers ───────── */

class _ResumeHint {
  final String title;
  final String route;
  _ResumeHint(this.title, this.route);
}

/* ───────── pinned header with fixed height ───────── */

class _SearchHeader extends SliverPersistentHeaderDelegate {
  _SearchHeader({required this.child});
  final Widget child;

  static const double _height = 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }

  @override
  double get maxExtent => _height;
  @override
  double get minExtent => _height;
  @override
  bool shouldRebuild(covariant _SearchHeader oldDelegate) => false;
}

/* ───────── overlay-free search bar ───────── */

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final override = theme.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );

    return Theme(
      data: override,
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => HapticFeedback.selectionClick(),
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  hintText: 'Search categories…',
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
            ),
            if (hasText)
              IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}

/* ───────── quick pill ───────── */

class _QuickPill extends StatelessWidget {
  const _QuickPill(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = theme.colorScheme.surface.withOpacity(.65);
    final stroke = theme.colorScheme.onSurface.withOpacity(.08);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: stroke),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── grid & card tiles ───────── */

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({super.key, this.query = ''});
  final String query;

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? Categories.all
        : Categories.all
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;
        final cross = w >= 1100 ? 4 : (w >= 820 ? 3 : 2);

        return GridView.builder(
          key: const PageStorageKey('grid'), // keep scroll position
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final name = filtered[i];
            return _CategoryCard(
              label: name,
              icon: _iconFor(name),
              onTap: () => GoRouter.of(context)
                  .push('/student/category?name=$name'), // push, not go
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'COMMUNICATION':
        return Icons.record_voice_over_outlined;
      case 'TEAMWORK':
        return Icons.groups_2_outlined;
      case 'CREATIVITY':
        return Icons.auto_awesome_outlined;
      case 'TIME MANAGEMENT':
        return Icons.schedule_outlined;
      case 'LEADERSHIP':
        return Icons.workspace_premium_outlined;
      case 'PROBLEM SOLVING':
        return Icons.psychology_alt_outlined;
      case 'SELF-REFLECTION':
        return Icons.self_improvement_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard(
      {required this.label, required this.onTap, required this.icon});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _down ? 0.98 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: s.radii.card,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(.78),
                borderRadius: s.radii.card,
                border:
                    Border.all(color: onSurface.withOpacity(.12), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.22),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 30),
                    const SizedBox(height: 12),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────── Frosted nav (blurred, translucent) ───────── */

class _FrostedNavigationBar extends StatelessWidget {
  const _FrostedNavigationBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const double kHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface.withOpacity(.60);
    final border = theme.colorScheme.onSurface.withOpacity(.08);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: border, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.22),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: NavigationBar(
            height: kHeight,
            backgroundColor: Colors.transparent,
            selectedIndex: index,
            onDestinationSelected: onChanged,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.military_tech_outlined),
                  label: 'Leaderboard'),
              NavigationDestination(
                  icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── Aurora / premium gradient backdrop ─────────
   Fixes:
   - No sudden blue "glow": fade-in the gradient on first frame.
   - Keep animation lightweight and ultra-low opacity overlays.
   - When this route is left via push, it stays below; no rebuild flicker. */
class _AuroraBackdrop extends StatefulWidget {
  const _AuroraBackdrop({required this.child});
  final Widget child;

  @override
  State<_AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<_AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  bool _ready = false; // fade-in guard to avoid flash on first compose

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Palette A (deep nightfall)
    const a0 = Color(0xFF151A2E); // deep indigo
    const a1 = Color(0xFF0D2E2A); // deep teal
    const a2 = Color(0xFF2B1F34); // plum base

    // Palette B (aurora accent)
    const b0 = Color(0xFF4B6FFF); // sapphire
    const b1 = Color(0xFF00D6A1); // mint teal
    const b2 = Color(0xFFFFB14B); // amber glow

    Color mix(Color base, Color tint, double t) => Color.lerp(base, tint, t)!;

    final baseLayer = DecoratedBox(
      position: DecorationPosition.background,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a0, a1, a2],
          stops: [0.05, 0.55, 0.98],
        ),
      ),
    );

    final animatedLayer = AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final angle = 0.6 + _c.value * 0.8;

        final c0 = mix(a0, b0, .25 + .20 * t);
        final c1 = mix(a1, b1, .22 + .22 * (1 - t));
        final c2 = mix(a2, b2, .20 + .24 * t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Slow blend linear
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c0.withOpacity(.50),
                    c1.withOpacity(.45),
                    c2.withOpacity(.45)
                  ],
                  stops: const [0.05, 0.55, 0.98],
                ),
              ),
            ),
            // Subtle radial bloom
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.65, -0.75),
                  radius: 1.2,
                  colors: [c2.withOpacity(.20), Colors.transparent],
                ),
              ),
            ),
            // Feather-light sweep
            Transform.rotate(
              angle: angle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const SweepGradient(
                    center: Alignment(0.0, 0.2),
                    colors: [
                      Colors.white10,
                      Colors.white12,
                      Colors.white10,
                      Colors.white10,
                    ],
                    stops: [0.0, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return AnimatedOpacity(
      opacity: _ready ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: Stack(
        fit: StackFit.expand,
        children: [
          baseLayer,
          animatedLayer,
          widget.child,
        ],
      ),
    );
  }
}

/* ───────── No glow overscroll (modern API) ───────── */
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Removes the blue glow/edge effect entirely.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();
}
