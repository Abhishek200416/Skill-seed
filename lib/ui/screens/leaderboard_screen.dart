import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/styles.dart'; // Glass + AnimatedPageGradient
import '../../../data/models/test_models.dart';
import '../../../data/repositories/test_repository.dart';

/// Sorting options for leaderboard list.
enum _SortBy { best, recent }

/// Result scope: show Top 50 or All.
enum _Scope { top50, all }

class LeaderboardScreen extends StatefulWidget {
  final String category;
  const LeaderboardScreen({super.key, required this.category});

  @override
  State<LeaderboardScreen> createState() => _LbState();
}

class _LbState extends State<LeaderboardScreen> {
  final _repo = TestRepository();

  List<Attempt> _attempts = [];
  bool _loading = true;
  bool _error = false;

  _SortBy _sortBy = _SortBy.best;
  _Scope _scope = _Scope.top50;

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await _repo.leaderboard(widget.category);
      _attempts = List<Attempt>.from(data);
      _applySort();
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- helpers ----------
  int _asInt(Object? v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  void _applySort() {
    if (_sortBy == _SortBy.best) {
      _attempts.sort((a, b) => _asInt(b.score).compareTo(_asInt(a.score)));
    } else {
      _attempts.sort(
          (a, b) => _asInt(b.attemptedAt).compareTo(_asInt(a.attemptedAt)));
    }
  }

  List<Attempt> get _scoped {
    if (_scope == _Scope.top50) return _attempts.take(50).toList();
    return _attempts;
  }

  Future<bool> _handleSystemBack() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/student');
    }
    return false;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final t = base.textTheme;

    // Quiet, overlay-free local theme. Gradients deliver the “premium” accent.
    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
          color: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: base.colorScheme.onSurface.withOpacity(.18),
        cursorColor: base.colorScheme.onSurface,
        selectionHandleColor: base.colorScheme.onSurface,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        isDense: true,
        fillColor: base.colorScheme.surface.withOpacity(.70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: base.colorScheme.onSurface.withOpacity(.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: base.colorScheme.onSurface.withOpacity(.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: base.colorScheme.primary.withOpacity(.45),
            width: 1.2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: t.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.80),
          letterSpacing: .2,
        ),
      ),
    );

    return Theme(
      data: quiet,
      child: WillPopScope(
        onWillPop: _handleSystemBack,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedPageGradient(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    leading: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _handleSystemBack,
                    ),
                    title: ShaderMask(
                      // Gradient “SkillSeed” accent on title for subtle premium feel
                      shaderCallback: (rect) =>
                          _gradText(context).createShader(rect),
                      blendMode: BlendMode.srcIn,
                      child: Text('Leaderboard • ${widget.category}'),
                    ),
                    actions: [
                      // Copy top 5
                      IconButton(
                        tooltip: 'Copy top 5',
                        icon: const Icon(Icons.share_outlined),
                        onPressed: _attempts.isEmpty
                            ? null
                            : () {
                                final top = _attempts.take(5).toList();
                                final lines = <String>[
                                  'Leaderboard — ${widget.category}',
                                  ...List.generate(top.length, (i) {
                                    final sc = _asInt(top[i].score);
                                    final id = top[i].userId;
                                    final short = id.length >= 6
                                        ? id.substring(0, 6)
                                        : id;
                                    return '${i + 1}. User $short — $sc';
                                  }),
                                ];
                                Clipboard.setData(
                                    ClipboardData(text: lines.join('\n')));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Copied to clipboard')),
                                );
                              },
                      ),
                      // Sort
                      PopupMenuButton<_SortBy>(
                        tooltip: 'Sort',
                        initialValue: _sortBy,
                        onSelected: (v) => setState(() {
                          _sortBy = v;
                          _applySort();
                        }),
                        itemBuilder: (ctx) => const [
                          PopupMenuItem(
                            value: _SortBy.best,
                            child: ListTile(
                              leading: Icon(Icons.star_outline),
                              title: Text('Best score'),
                            ),
                          ),
                          PopupMenuItem(
                            value: _SortBy.recent,
                            child: ListTile(
                              leading: Icon(Icons.schedule_outlined),
                              title: Text('Most recent'),
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.sort),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(56),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Glass(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_outlined, size: 18),
                              const SizedBox(width: 8),
                              SegmentedButton<_Scope>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment<_Scope>(
                                      value: _Scope.top50,
                                      label: Text('Top 50')),
                                  ButtonSegment<_Scope>(
                                      value: _Scope.all, label: Text('All')),
                                ],
                                selected: {_scope},
                                onSelectionChanged: (s) =>
                                    setState(() => _scope = s.first),
                              ),
                              const Spacer(),
                              _Legend(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Context card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Stack(
                        children: [
                          // Gradient accent stripe (left)
                          Positioned.fill(
                            left: 0,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 3,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: _accentStripe(context),
                                ),
                              ),
                            ),
                          ),
                          Glass(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                    child: Icon(Icons.emoji_events_outlined)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (r) =>
                                            _gradText(context).createShader(r),
                                        blendMode: BlendMode.srcIn,
                                        child: const Text('Top performers'),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _sortBy == _SortBy.best
                                            ? 'Sorted by best score — pull to refresh'
                                            : 'Sorted by most recent attempts — pull to refresh',
                                        style: t.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(.72),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _TinyStat(
                                    label: 'Total', value: _attempts.length),
                                const SizedBox(width: 6),
                                _TinyStat(
                                    label: 'Scope', value: _scoped.length),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Podium (top 3)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                      child: _PodiumRow(attempts: _attempts, asInt: _asInt),
                    ),
                  ),

                  // List
                  SliverFillRemaining(
                    child: _loading
                        ? const _SkeletonList()
                        : _error
                            ? _ErrorView(onRetry: _load)
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: _scoped.isEmpty
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: const [
                                          SizedBox(height: 140),
                                          Center(
                                              child: Text('No attempts yet')),
                                        ],
                                      )
                                    : ListView.separated(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 6, 12, 16),
                                        itemCount: _scoped.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (_, i) {
                                          final a = _scoped[i];
                                          final place = i + 1;
                                          final color = _rankColor(
                                              place, Theme.of(context));
                                          final score =
                                              _asInt(a.score).clamp(0, 100);
                                          final id = a.userId;
                                          final short = id.length >= 6
                                              ? id.substring(0, 6)
                                              : id;

                                          return Stack(
                                            children: [
                                              // Thin gradient bar at left
                                              Positioned.fill(
                                                left: 0,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    width: 3,
                                                    height: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                      gradient: _accentStripe(
                                                          context),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Glass(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                child: Row(
                                                  children: [
                                                    _RankBadge(
                                                        place: place,
                                                        color: color),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'User $short…',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: t.titleSmall
                                                                ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 6),
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            child:
                                                                LinearProgressIndicator(
                                                              minHeight: 6,
                                                              value:
                                                                  score / 100.0,
                                                              color: color,
                                                              backgroundColor:
                                                                  color
                                                                      .withOpacity(
                                                                          .15),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Gradient-tinted score
                                                    ShaderMask(
                                                      shaderCallback: (r) =>
                                                          _gradText(context)
                                                              .createShader(r),
                                                      blendMode:
                                                          BlendMode.srcIn,
                                                      child: Text(
                                                        '$score',
                                                        style: t.titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Gradient used for text accents.
  LinearGradient _gradText(BuildContext context) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.tertiary,
        ].map((c) => c.withOpacity(.95)).toList(),
        stops: const [0.0, 0.5, 1.0],
      );

  // Vertical stripe gradient accent (matches premium look across screens).
  LinearGradient _accentStripe(BuildContext context) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(.85),
          Theme.of(context).colorScheme.secondary.withOpacity(.85),
          Theme.of(context).colorScheme.tertiary.withOpacity(.85),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
}

/* ───────────────────────── small pieces ───────────────────────── */

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface.withOpacity(.70);
    Widget dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle));
    return Row(
      children: [
        dot(const Color(0xFFFFD54F)),
        const SizedBox(width: 4),
        Text('1st', style: TextStyle(color: fg)),
        const SizedBox(width: 10),
        dot(const Color(0xFFB0BEC5)),
        const SizedBox(width: 4),
        Text('2nd', style: TextStyle(color: fg)),
        const SizedBox(width: 10),
        dot(const Color(0xFFBCAAA4)),
        const SizedBox(width: 4),
        Text('3rd', style: TextStyle(color: fg)),
      ],
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: on.withOpacity(.06),
        border: Border.all(color: on.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final card = Stack(
      children: [
        Positioned.fill(
          left: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 3,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(.30),
                    Theme.of(context).colorScheme.secondary.withOpacity(.30),
                    Theme.of(context).colorScheme.tertiary.withOpacity(.30),
                  ],
                ),
              ),
            ),
          ),
        ),
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 30,
                height: 16,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
        ),
      ],
    );

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemBuilder: (_, __) => card,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: 6,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 160),
        Center(
          child: Column(
            children: [
              const Icon(Icons.wifi_off_outlined, size: 44),
              const SizedBox(height: 8),
              const Text('Couldn’t load leaderboard'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.place, required this.color});
  final int place;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (place <= 3) {
      return SizedBox(
          width: 36, height: 36, child: Icon(Icons.emoji_events, color: color));
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: color.withOpacity(.10),
      child: Text('$place', style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

Color _rankColor(int place, ThemeData theme) {
  if (place == 1) return const Color(0xFFFFD54F); // gold
  if (place == 2) return const Color(0xFFB0BEC5); // silver
  if (place == 3) return const Color(0xFFBCAAA4); // bronze
  return theme.colorScheme.primary;
}

/// Visual podium for top 3 with emphasized center tile and gradient halo.
class _PodiumRow extends StatelessWidget {
  const _PodiumRow({required this.attempts, required this.asInt});
  final List<Attempt> attempts;
  final int Function(Object? v, {int fallback}) asInt;

  @override
  Widget build(BuildContext context) {
    if (attempts.length < 3) return const SizedBox.shrink();

    final podium = attempts.take(3).toList();
    final tiles = [
      _PodiumTile(
          place: 2, name: podium[1].userId, score: asInt(podium[1].score)),
      _PodiumTile(
          place: 1,
          name: podium[0].userId,
          score: asInt(podium[0].score),
          big: true),
      _PodiumTile(
          place: 3, name: podium[2].userId, score: asInt(podium[2].score)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(tiles.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: tiles[i],
          ),
        );
      }),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  const _PodiumTile({
    required this.place,
    required this.name,
    required this.score,
    this.big = false,
  });
  final int place;
  final String name;
  final int score;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(place, Theme.of(context));
    final t = Theme.of(context).textTheme;
    final short = name.length >= 6 ? name.substring(0, 6) : name;

    return Stack(
      children: [
        // soft radial halo for the podium tile (gradient tint)
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: big ? 1.0 : 0.8,
                  colors: [
                    color.withOpacity(.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        Glass(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: color, size: big ? 30 : 24),
              const SizedBox(height: 6),
              Text(
                'User $short…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    Theme.of(context).colorScheme.primary,
                  ],
                ).createShader(r),
                blendMode: BlendMode.srcIn,
                child: Text(
                  '$score',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (score.clamp(0, 100)) / 100.0,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withOpacity(.15),
                ),
              ),
              if (big) const SizedBox(height: 2),
            ],
          ),
        ),
      ],
    );
  }
}
