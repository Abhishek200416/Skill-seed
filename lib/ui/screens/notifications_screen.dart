import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../core/styles.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/models/live_session.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotifState();
}

class _NotifState extends State<NotificationsScreen> {
  final _fmt = DateFormat('EEE, d MMM • h:mm a');

  List<LiveSession> _upcoming = [];
  bool _loading = true;
  bool _next7 = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ClassRepository().upcoming('COMMUNICATION');
    _upcoming = List<LiveSession>.from(data);
    if (mounted) setState(() => _loading = false);
  }

  List<LiveSession> _filtered() {
    if (!_next7) return _upcoming;
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return _upcoming
        .where((s) => s.startAt.isAfter(now) && s.startAt.isBefore(end))
        .toList(growable: false);
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

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Clean, overlay-free local theme. Gradients provide the accent.
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
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: base.colorScheme.onSurface.withOpacity(.18),
        cursorColor: base.colorScheme.onSurface,
        selectionHandleColor: base.colorScheme.onSurface,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
          color: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
    );

    final list = _filtered();

    return Theme(
      data: quiet,
      child: WillPopScope(
        onWillPop: _handleSystemBack,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedPageGradient(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    leading: IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _handleSystemBack,
                    ),
                    title: const Text('Notifications'),
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh),
                        onPressed: () async {
                          setState(() => _loading = true);
                          await _load();
                        },
                      ),
                      const SizedBox(width: 6),
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
                              FilterChip(
                                label: const Text('Next 7 days'),
                                selected: _next7,
                                onSelected: (v) => setState(() => _next7 = v),
                              ),
                              const SizedBox(width: 8),
                              _GradBadge(
                                // soft premium gradient pill
                                label: '${list.length} upcoming',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Body
                  SliverFillRemaining(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: list.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 120),
                                      Center(
                                          child: Text('No alerts right now')),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 12, 12, 16),
                                    itemCount: list.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) {
                                      final s = list[i];
                                      final hasUrl = (s.zoomUrl ?? '')
                                          .trim()
                                          .startsWith('http');
                                      final validUrl = hasUrl &&
                                          Uri.tryParse(s.zoomUrl!.trim()) !=
                                              null;
                                      final host = validUrl
                                          ? Uri.parse(s.zoomUrl!.trim())
                                              .host
                                              .replaceFirst('www.', '')
                                          : '—';
                                      final when = _fmt.format(s.startAt);
                                      final rel =
                                          _relativeTime(context, s.startAt);

                                      return Stack(
                                        children: [
                                          // thin gradient stripe at left for a premium accent
                                          Positioned.fill(
                                            left: 0,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                width: 3,
                                                height: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  gradient: _stripeGradient(
                                                      Theme.of(context)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Glass(
                                            padding: const EdgeInsets.fromLTRB(
                                                14, 12, 12, 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .notifications_active_outlined,
                                                      size: 22,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        s.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: base.textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    _StatusChip(
                                                        validUrl: validUrl,
                                                        hasUrl: hasUrl),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.schedule_outlined,
                                                        size: 16),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '$when  •  $rel',
                                                        style: base
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          color: base
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(.80),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.link_outlined,
                                                        size: 16),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: ShaderMask(
                                                        shaderCallback: (rect) =>
                                                            _textGradient(
                                                                    Theme.of(
                                                                        context))
                                                                .createShader(
                                                                    rect),
                                                        blendMode:
                                                            BlendMode.srcIn,
                                                        child: Text(
                                                          host,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: base.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: hasUrl
                                                          ? () async {
                                                              HapticFeedback
                                                                  .selectionClick();
                                                              await Clipboard.setData(
                                                                  ClipboardData(
                                                                      text: s
                                                                          .zoomUrl!));
                                                              if (context
                                                                  .mounted) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'Link copied')),
                                                                );
                                                              }
                                                            }
                                                          : null,
                                                      icon: const Icon(
                                                          Icons.copy),
                                                      label: const Text('Copy'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Keep primary button simple & reliable,
                                                    // gradients are expressed via accents above.
                                                    FilledButton.icon(
                                                      onPressed: validUrl
                                                          ? () async {
                                                              final u =
                                                                  Uri.parse(s
                                                                      .zoomUrl!
                                                                      .trim());
                                                              if (await canLaunchUrl(
                                                                  u)) {
                                                                await launchUrl(
                                                                  u,
                                                                  mode: LaunchMode
                                                                      .externalApplication,
                                                                );
                                                              } else {
                                                                if (context
                                                                    .mounted) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                          'Could not launch link'),
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            }
                                                          : null,
                                                      icon: const Icon(
                                                          Icons.open_in_new),
                                                      label: const Text('Join'),
                                                    ),
                                                  ],
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

  // Nicely phrased relative time like “in 2h 10m” or “2h ago”.
  String _relativeTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    final isFuture = diff.inSeconds >= 0;
    final d = diff.abs();
    if (d.inDays >= 1) {
      final days = d.inDays;
      return isFuture ? 'in ${days}d' : '${days}d ago';
    } else if (d.inHours >= 1) {
      final h = d.inHours;
      final m = (d.inMinutes % 60);
      final tail = m > 0 ? ' ${m}m' : '';
      return isFuture ? 'in ${h}h$tail' : '${h}h$tail ago';
    } else if (d.inMinutes >= 1) {
      final m = d.inMinutes;
      return isFuture ? 'in ${m}m' : '${m}m ago';
    } else {
      return isFuture ? 'soon' : 'just now';
    }
  }

  // Soft, premium gradient used for stripes/pills/text.
  LinearGradient _textGradient(ThemeData t) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          t.colorScheme.primary,
          t.colorScheme.secondary,
          t.colorScheme.tertiary,
        ].map((c) => c.withOpacity(.95)).toList(),
        stops: const [0.0, 0.5, 1.0],
      );

  LinearGradient _stripeGradient(ThemeData t) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          t.colorScheme.primary.withOpacity(.85),
          t.colorScheme.secondary.withOpacity(.85),
          t.colorScheme.tertiary.withOpacity(.85),
        ],
        stops: const [0.0, 0.5, 1.0],
      );
}

/* ───────── Gradient badge/pill ───────── */

class _GradBadge extends StatelessWidget {
  const _GradBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final fg = t.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            t.colorScheme.primary.withOpacity(.18),
            t.colorScheme.secondary.withOpacity(.18),
            t.colorScheme.tertiary.withOpacity(.18),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.06), width: 1),
      ),
      child: Text(
        label,
        style: t.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/* ───────── Status chip with color logic (Ready/Invalid/Pending) ───────── */

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.validUrl, required this.hasUrl});
  final bool validUrl;
  final bool hasUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String text;
    Color color;
    if (validUrl) {
      text = 'Ready';
      color = Colors.greenAccent;
    } else if (hasUrl) {
      text = 'Invalid';
      color = Colors.amber;
    } else {
      text = 'Pending';
      color = theme.colorScheme.onSurface.withOpacity(.6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(.22),
            theme.colorScheme.primary.withOpacity(.12),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(.06)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
