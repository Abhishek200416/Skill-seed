// lib/ui/screens/admin/admin_dashboard.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});
  @override
  ConsumerState<AdminDashboard> createState() => _AdminState();
}

class _AdminState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _adminRepo = AdminRepository();
  final _auth = AuthRepository();

  late final TabController _tabs = TabController(length: 5, vsync: this);
  Map<String, int> _kpis = {};
  bool _loading = true;

  // lists
  List<AppUser> _pending = [];
  List<AppUser> _teachers = [];
  List<AppUser> _students = [];

  // filters
  final _teacherQ = TextEditingController();
  final _teacherCat = TextEditingController();
  final _studentQ = TextEditingController();

  // notifications
  final _ntTitle = TextEditingController();
  final _ntBody = TextEditingController();
  String _ntRole = 'all';
  String? _ntCategory;
  List<Map<String, Object?>> _sent = [];

  // smooth scroll-to-composer + open control
  final _composerKey = GlobalKey();
  final ValueNotifier<bool> _composerOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _refreshAll();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _teacherQ.dispose();
    _teacherCat.dispose();
    _studentQ.dispose();
    _ntTitle.dispose();
    _ntBody.dispose();
    _composerOpen.dispose();
    super.dispose();
  }

  bool get _isNotifications => _tabs.index == 4;

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _kpis = await _adminRepo.summary();
    _pending = await _adminRepo.pendingTeachers();
    _teachers = await _adminRepo.approvedTeachers();
    _students = await _adminRepo.students();
    _sent = await _adminRepo.listNotifications();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _applyTeacherFilters() async {
    _teachers = await _adminRepo.approvedTeachers(
      q: _teacherQ.text.trim(),
      categoryOrSpec: _teacherCat.text.trim(),
    );
    setState(() {});
  }

  Future<void> _searchStudents() async {
    _students = await _adminRepo.students(q: _studentQ.text.trim());
    setState(() {});
  }

  // safe url handlers
  Future<void> _call(String? phone) async {
    final p = (phone ?? '').trim();
    if (p.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: p);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _mail(String? email) async {
    final e = (email ?? '').trim();
    if (e.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: e);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _scrollToComposer() {
    final ctx = _composerKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Local quiet theme (overlay-free) with premium gradient accents.
    final clearOverlay =
        MaterialStateProperty.resolveWith<Color?>((_) => Colors.transparent);
    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      tabBarTheme: base.tabBarTheme.copyWith(
        overlayColor: clearOverlay,
        labelColor: base.colorScheme.onSurface,
        unselectedLabelColor: base.colorScheme.onSurface.withOpacity(.72),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _accentFill(context), // gradient indicator
          border: Border.all(
            color: base.colorScheme.onSurface.withOpacity(.10),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: base.colorScheme.surface.withOpacity(.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: base.colorScheme.onSurface.withOpacity(.10)),
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
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: MaterialStatePropertyAll(Colors.transparent),
        ),
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

    return Theme(
      data: quiet,
      child: Scaffold(
        floatingActionButton: _isNotifications && isMobile
            ? FloatingActionButton.extended(
                onPressed: () {
                  _tabs.animateTo(4);
                  _composerOpen.value = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToComposer();
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Compose'),
              )
            : null,
        body: _AdminBackdrop(
          child: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (ctx, _) => [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: true,
                  title: ShaderMask(
                    shaderCallback: (r) => _gradText(context).createShader(r),
                    blendMode: BlendMode.srcIn,
                    child: const Text('Admin Dashboard'),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _refreshAll,
                      icon: const Icon(Icons.refresh),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'logout') {
                          await _auth.signOut();
                          if (mounted) context.go('/login');
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'logout', child: Text('Log out')),
                      ],
                      child: const CircleAvatar(
                        child: Icon(Icons.admin_panel_settings),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  bottom: PreferredSize(
                    preferredSize:
                        const Size.fromHeight(kTextTabBarHeight + 12 + 8),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Glass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: SizedBox(
                          height: kTextTabBarHeight,
                          child: TabBar(
                            controller: _tabs,
                            isScrollable: true,
                            tabs: const [
                              Tab(text: 'Overview'),
                              Tab(text: 'Pending'),
                              Tab(text: 'Teachers'),
                              Tab(text: 'Students'),
                              Tab(text: 'Notifications'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              body: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _OverviewTabSmall(kpis: _kpis),
                        _PendingTabCompact(
                          items: _pending,
                          onRefresh: _refreshAll,
                          onApprove: (u) async {
                            await _adminRepo.approveTeacher(u.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Approved ${u.name}')),
                            );
                            _refreshAll();
                          },
                          onViewStats: _openTeacherDetails,
                          onContactCall: (u) => _call(u.phone),
                          onContactMail: (u) => _mail(u.email),
                        ),
                        _TeachersTabCompact(
                          items: _teachers,
                          q: _teacherQ,
                          cat: _teacherCat,
                          onFilter: _applyTeacherFilters,
                          onViewStats: _openTeacherDetails,
                          onPromote: (u) async {
                            await _adminRepo.promoteToAdmin(u.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Promoted ${u.name} to Admin')),
                            );
                            _refreshAll();
                          },
                          onBlock: (u) async {
                            await _adminRepo.blockUser(u.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Blocked ${u.name}')),
                            );
                            _refreshAll();
                          },
                        ),
                        _StudentsTabCompact(
                          items: _students,
                          q: _studentQ,
                          onSearch: _searchStudents,
                        ),
                        _NotificationsTabCompact(
                          title: _ntTitle,
                          body: _ntBody,
                          onSend: () async {
                            if (_ntTitle.text.trim().isEmpty ||
                                _ntBody.text.trim().isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Title and message required')),
                              );
                              return;
                            }
                            await _adminRepo.createNotification(
                              title: _ntTitle.text.trim(),
                              message: _ntBody.text.trim(),
                              targetRole: _ntRole,
                              category: (_ntCategory?.trim().isEmpty ?? true)
                                  ? null
                                  : _ntCategory!.trim(),
                            );
                            _ntTitle.clear();
                            _ntBody.clear();
                            _sent = await _adminRepo.listNotifications();
                            setState(() {});
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Notification queued')),
                            );
                          },
                          onRoleChanged: (r) => setState(() => _ntRole = r),
                          onCategoryChanged: (c) =>
                              setState(() => _ntCategory = c),
                          sent: _sent,
                          composerKey: _composerKey,
                          currentRole: _ntRole,
                          openNotifier: _composerOpen,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTeacherDetails(AppUser u) async {
    final stats = await _adminRepo.teacherStats(u.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ListTile(
              dense: true,
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.9,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(.18),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                  const CircleAvatar(child: Icon(Icons.person)),
                ],
              ),
              title: ShaderMask(
                shaderCallback: (r) => _gradText(context).createShader(r),
                blendMode: BlendMode.srcIn,
                child: Text(u.name),
              ),
              subtitle:
                  Text('${u.email}  •  ${u.phone}\n${u.specialty ?? '-'}'),
              trailing: u.isApproved
                  ? const Chip(label: Text('Approved'))
                  : const Chip(label: Text('Pending')),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(label: 'Content', value: stats['content'] ?? 0),
                _StatChip(label: 'Live', value: stats['live'] ?? 0),
                _StatChip(label: 'Tests', value: stats['tests'] ?? 0),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Email'),
                  onPressed: () => _mail(u.email),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                  onPressed: () => _call(u.phone),
                ),
                if (!u.isApproved)
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    onPressed: () async {
                      await _adminRepo.approveTeacher(u.id);
                      if (mounted) Navigator.pop(context);
                      _refreshAll();
                    },
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.block),
                  label: const Text('Block'),
                  onPressed: () async {
                    await _adminRepo.blockUser(u.id);
                    if (mounted) Navigator.pop(context);
                    _refreshAll();
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Promote to Admin'),
                  onPressed: () async {
                    await _adminRepo.promoteToAdmin(u.id);
                    if (mounted) Navigator.pop(context);
                    _refreshAll();
                  },
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

/* ───────────────── shared bits ───────────────── */

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final grad = _accentFill(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: grad,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/* ───────── Overview: compact KPI chips (no stripes + smooth L→R) ───────── */

class _OverviewTabSmall extends StatelessWidget {
  const _OverviewTabSmall({required this.kpis});
  final Map<String, int> kpis;

  @override
  Widget build(BuildContext context) {
    final items = <_Kpi>[
      _Kpi('Teachers', Icons.co_present_outlined, kpis['teachers'] ?? 0),
      _Kpi('Pending', Icons.pending_actions, kpis['pending'] ?? 0),
      _Kpi('Students', Icons.school_outlined, kpis['students'] ?? 0),
      _Kpi('Content', Icons.video_library_outlined, kpis['content'] ?? 0),
      _Kpi('Live', Icons.link_outlined, kpis['live'] ?? 0),
      _Kpi('Tests', Icons.fact_check_outlined, kpis['tests'] ?? 0),
    ];

    return RefreshIndicator(
      onRefresh: () async =>
          Future<void>.delayed(const Duration(milliseconds: 250)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.asMap().entries.map((e) {
            final i = e.key;
            final k = e.value;

            return TweenAnimationBuilder<double>(
              key: ValueKey('kpi-$i-${k.value}'),
              duration: Duration(milliseconds: 360 + 40 * i),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 1, end: 0),
              builder: (_, t, child) => Opacity(
                opacity: 1 - 0.5 * t,
                child: Transform.translate(
                    offset: Offset(18 * t, 0), child: child),
              ),
              child: _KpiPill(title: k.title, icon: k.icon, value: k.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Kpi {
  final String title;
  final IconData icon;
  final int value;
  _Kpi(this.title, this.icon, this.value);
}

class _KpiPill extends StatelessWidget {
  const _KpiPill(
      {required this.title, required this.icon, required this.value});
  final String title;
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(title),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (r) => _gradText(context).createShader(r),
          blendMode: BlendMode.srcIn,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Text(
              '$value',
              key: ValueKey(value),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ]),
    );
  }
}

/* ───────── Collapsible card (compact, stripe-free by default) ───────── */

class _CollapseCard extends StatelessWidget {
  const _CollapseCard({
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.showAccentStripe = false, // toggle on only if desired
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showAccentStripe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Glass(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: theme.colorScheme.onSurface.withOpacity(.72),
          collapsedIconColor: theme.colorScheme.onSurface.withOpacity(.72),
          leading: leading,
          title: Text(
            title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: (subtitle == null)
              ? null
              : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
          children: [
            _ScrollArea(child: Column(children: children)),
          ],
        ),
      ),
    );

    if (!showAccentStripe) return card;

    // Optional bring-back stripe for a specific card
    return Stack(
      children: [
        Positioned.fill(
          left: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: _accentFill(context),
              ),
            ),
          ),
        ),
        card,
      ],
    );
  }
}

class _ScrollArea extends StatelessWidget {
  const _ScrollArea({required this.child, this.height = 160});
  final Widget child;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 6),
        child: child,
      ),
    );
  }
}

/* ───────── Pending (compact) ───────── */

class _PendingTabCompact extends StatelessWidget {
  const _PendingTabCompact({
    required this.items,
    required this.onApprove,
    required this.onViewStats,
    required this.onContactCall,
    required this.onContactMail,
    required this.onRefresh,
  });

  final List<AppUser> items;
  final ValueChanged<AppUser> onApprove;
  final ValueChanged<AppUser> onViewStats;
  final ValueChanged<AppUser> onContactCall;
  final ValueChanged<AppUser> onContactMail;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: items.isEmpty ? 1 : items.length,
        itemBuilder: (_, i) {
          if (items.isEmpty) {
            return const Center(child: Text('No pending teacher requests.'));
          }
          final t = items[i];
          return _CollapseCard(
            leading: const CircleAvatar(child: Icon(Icons.co_present_outlined)),
            title: t.name,
            subtitle: '${t.email} • ${t.phone}\n${t.specialty ?? '-'}',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(
                      onPressed: () => onApprove(t),
                      child: const Text('Approve')),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.insert_chart_outlined),
                    label: const Text('View stats'),
                    onPressed: () => onViewStats(t),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Email'),
                    onPressed: () => onContactMail(t),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    onPressed: () => onContactCall(t),
                  ),
                ],
              ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 8),
      ),
    );
  }
}

/* ───────── Teachers (compact) ───────── */

class _TeachersTabCompact extends StatelessWidget {
  const _TeachersTabCompact({
    required this.items,
    required this.q,
    required this.cat,
    required this.onFilter,
    required this.onViewStats,
    required this.onPromote,
    required this.onBlock,
  });

  final List<AppUser> items;
  final TextEditingController q;
  final TextEditingController cat;
  final VoidCallback onFilter;
  final ValueChanged<AppUser> onViewStats;
  final ValueChanged<AppUser> onPromote;
  final ValueChanged<AppUser> onBlock;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
              child: TextField(
                controller: q,
                decoration: const InputDecoration(
                  labelText: 'Search name/email/phone',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  filled: true,
                ),
                onSubmitted: (_) => onFilter(),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
              child: TextField(
                controller: cat,
                decoration: const InputDecoration(
                  labelText: 'Filter by specialty',
                  isDense: true,
                  filled: true,
                ),
                onSubmitted: (_) => onFilter(),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.filter_alt),
              label: const Text('Apply'),
              onPressed: onFilter,
            ),
          ],
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => onFilter(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.isEmpty ? 1 : items.length,
            itemBuilder: (_, i) {
              if (items.isEmpty) {
                return const Center(child: Text('No teachers found.'));
              }
              final t = items[i];
              return _CollapseCard(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: t.name,
                subtitle: '${t.email} • ${t.phone}\n${t.specialty ?? '-'}',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.insert_chart_outlined),
                        label: const Text('View stats'),
                        onPressed: () => onViewStats(t),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('Promote'),
                        onPressed: () => onPromote(t),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.block),
                        label: const Text('Block'),
                        onPressed: () => onBlock(t),
                      ),
                      OutlinedButton.icon(
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                          onPressed: () =>
                              launchUrl(Uri.parse('mailto:${t.email}'))),
                    ],
                  ),
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        ),
      ),
    ]);
  }
}

/* ───────── Students (compact) ───────── */

class _StudentsTabCompact extends StatelessWidget {
  const _StudentsTabCompact({
    required this.items,
    required this.q,
    required this.onSearch,
  });
  final List<AppUser> items;
  final TextEditingController q;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 520),
              child: TextField(
                controller: q,
                decoration: const InputDecoration(
                  labelText: 'Search name/email/college',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  filled: true,
                ),
                onSubmitted: (_) => onSearch(),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              onPressed: onSearch,
            ),
          ],
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => onSearch(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.isEmpty ? 1 : items.length,
            itemBuilder: (_, i) {
              if (items.isEmpty) {
                return const Center(child: Text('No students found.'));
              }
              final s = items[i];
              return _CollapseCard(
                leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                title: s.name,
                subtitle: '${s.email} • ${s.college ?? '-'}',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                          onPressed: () =>
                              launchUrl(Uri.parse('mailto:${s.email}'))),
                    ],
                  ),
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          ),
        ),
      ),
    ]);
  }
}

/* ───────── Notifications (compact composer + list) ───────── */

class _NotificationsTabCompact extends StatelessWidget {
  const _NotificationsTabCompact({
    required this.title,
    required this.body,
    required this.onSend,
    required this.onRoleChanged,
    required this.onCategoryChanged,
    required this.sent,
    required this.composerKey,
    required this.currentRole,
    required this.openNotifier,
  });

  final TextEditingController title;
  final TextEditingController body;
  final VoidCallback onSend;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String?> onCategoryChanged;
  final List<Map<String, Object?>> sent;
  final GlobalKey composerKey;
  final String currentRole;
  final ValueNotifier<bool> openNotifier;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // Controlled composer (programmatic open via FAB)
        KeyedSubtree(
          key: composerKey,
          child: _ControlledCollapsible(
            title: 'New Notification',
            subtitle:
                'Write a message to all users or filter by role/category.',
            leading: const CircleAvatar(child: Icon(Icons.edit_outlined)),
            openListenable: openNotifier,
            child: Column(
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    isDense: true,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: body,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    isDense: true,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DropdownButtonFormField<String>(
                      value: currentRole,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All users')),
                        DropdownMenuItem(
                            value: 'student', child: Text('Students')),
                        DropdownMenuItem(
                            value: 'teacher', child: Text('Teachers')),
                      ],
                      onChanged: (v) => onRoleChanged(v ?? 'all'),
                      decoration: const InputDecoration(
                        labelText: 'Target role',
                        isDense: true,
                        filled: true,
                      ),
                    ),
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: 180, maxWidth: 320),
                      child: TextFormField(
                        onChanged: (v) => onCategoryChanged(v),
                        decoration: const InputDecoration(
                          labelText: 'Category (optional)',
                          hintText: 'COMMUNICATION, …',
                          isDense: true,
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                      onPressed: onSend,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Sent feed (no stripes, gentle slide-in)
        if (sent.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No notifications yet.'),
            ),
          )
        else
          ...sent.asMap().entries.map((e) {
            final i = e.key;
            final n = e.value;
            return TweenAnimationBuilder<double>(
              key: ValueKey('sent-$i-${n['createdAt']}'),
              duration: Duration(milliseconds: 260 + 30 * i),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 1, end: 0),
              builder: (_, t, child) => Opacity(
                opacity: 1 - 0.4 * t,
                child: Transform.translate(
                    offset: Offset(14 * t, 0), child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Glass(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined),
                    title: ShaderMask(
                      shaderCallback: (r) => _gradText(context).createShader(r),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        '${n['title']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    subtitle: Text(
                      '${n['message']}'
                      '\nRole: ${n['targetRole'] ?? 'all'}'
                      '${n['category'] != null ? '  •  ${n['category']}' : ''}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      DateTime.fromMillisecondsSinceEpoch(
                              (n['createdAt'] as int))
                          .toLocal()
                          .toString()
                          .split('.')
                          .first,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

/* ───────── Premium backdrop (soft “leaf” glows drifting L↔R) ───────── */

class _AdminBackdrop extends StatefulWidget {
  const _AdminBackdrop({required this.child});
  final Widget child;
  @override
  State<_AdminBackdrop> createState() => _AdminBackdropState();
}

class _AdminBackdropState extends State<_AdminBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _drift(double phase, double amp) =>
      amp * math.sin(((_c.value + phase) * 2 * math.pi));

  @override
  Widget build(BuildContext context) {
    // Base deep hues
    const base0 = Color(0xFF0E1630); // midnight indigo
    const base1 = Color(0xFF0A2D29); // deep teal
    const base2 = Color(0xFF24142E); // plum

    // Accents — sapphire, mint, amber
    const acc0 = Color(0xFF4B6FFF);
    const acc1 = Color(0xFF00D6A1);
    const acc2 = Color(0xFFFFB14B);

    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final c0 = mix(base0, acc0, .28 + .24 * t);
        final c1 = mix(base1, acc1, .24 + .24 * (1 - t));
        final c2 = mix(base2, acc2, .22 + .26 * t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base gradient wash (no hard edges)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c0.withOpacity(.95),
                    c1.withOpacity(.92),
                    c2.withOpacity(.90)
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // Soft “leaf” glows: large, blurred, horizontal drift
            _LeafGlow(
              alignment: Alignment(-0.8 + _drift(0.05, 0.05), -0.7),
              color: acc1.withOpacity(.16),
              size: const Size(360, 220),
              tilt: -0.45,
            ),
            _LeafGlow(
              alignment: Alignment(0.85 + _drift(0.28, 0.06), -0.65),
              color: acc0.withOpacity(.14),
              size: const Size(420, 260),
              tilt: 0.32,
            ),
            _LeafGlow(
              alignment: Alignment(0.0 + _drift(0.56, 0.07), 0.9),
              color: acc2.withOpacity(.14),
              size: const Size(520, 280),
              tilt: -0.2,
            ),

            widget.child,
          ],
        );
      },
    );
  }
}

class _LeafGlow extends StatelessWidget {
  const _LeafGlow({
    required this.alignment,
    required this.color,
    required this.size,
    required this.tilt,
  });

  final Alignment alignment;
  final Color color;
  final Size size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: tilt,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, 0.0),
              radius: 0.9,
              colors: [color, Colors.transparent],
              stops: const [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

/* ───────── Controlled collapsible (stripe-free header) ───────── */

class _ControlledCollapsible extends StatefulWidget {
  const _ControlledCollapsible({
    required this.title,
    this.subtitle,
    required this.leading,
    required this.child,
    required this.openListenable,
  });

  final String title;
  final String? subtitle;
  final Widget leading;
  final Widget child;
  final ValueListenable<bool> openListenable;

  @override
  State<_ControlledCollapsible> createState() => _ControlledCollapsibleState();
}

class _ControlledCollapsibleState extends State<_ControlledCollapsible>
    with SingleTickerProviderStateMixin {
  late bool _open = widget.openListenable.value;

  @override
  void initState() {
    super.initState();
    widget.openListenable.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant _ControlledCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openListenable != widget.openListenable) {
      oldWidget.openListenable.removeListener(_sync);
      widget.openListenable.addListener(_sync);
      _open = widget.openListenable.value;
    }
  }

  @override
  void dispose() {
    widget.openListenable.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() => _open = widget.openListenable.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Glass(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  widget.leading,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (widget.subtitle != null)
                          Text(widget.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _open ? 0.5 : 0.0,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _ScrollArea(child: widget.child),
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

/* ───────── Gradient helpers ───────── */

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

LinearGradient _accentFill(BuildContext context) => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Theme.of(context).colorScheme.primary.withOpacity(.22),
        Theme.of(context).colorScheme.secondary.withOpacity(.22),
        Theme.of(context).colorScheme.tertiary.withOpacity(.22),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
