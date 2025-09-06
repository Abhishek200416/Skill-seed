// lib/ui/screens/student/category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles.dart';
import '../../../data/models/content_item.dart';
import '../../../data/models/live_session.dart';
import '../../../data/models/test_models.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/test_repository.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CatState();
}

class _CatState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _fmt = DateFormat('EEE, d MMM • h:mm a');

  List<LiveSession> upcoming = [], previous = [];
  List<ContentItem> content = [];
  List<TestPaper> papers = [];
  bool loading = true;

  // Content filters / search
  final _contentSearch = TextEditingController();
  String _contentQ = '';
  String _contentType = 'all'; // all | video | note | link

  // Tests sort
  bool _sortShortFirst = true;

  // Keys
  final _pageKey = const PageStorageKey<String>('category_detail_scroll');
  final _tabViewKey = const PageStorageKey<String>('category_detail_tabs');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) setState(() {});
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _contentSearch.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = ClassRepository();
    final t = TestRepository();
    upcoming = await c.upcoming(widget.category);
    previous = await c.previous(widget.category);
    content = await c.contentByCategory(widget.category);
    papers = await t.papersForCategory(widget.category);
    if (mounted) setState(() => loading = false);
  }

  List<ContentItem> get _filteredContent {
    Iterable<ContentItem> list = content;
    if (_contentType != 'all') {
      if (_contentType == 'link') {
        // before: (e.urlOrPath ?? '').startsWith('http')
        list = list.where((e) => e.urlOrPath?.startsWith('http') ?? false);
      } else {
        // before: (e.type ?? '').toLowerCase() == _contentType
        list = list.where((e) => (e.type ?? '').toLowerCase() == _contentType);
      }
    }
    if (_contentQ.isNotEmpty) {
      final q = _contentQ.toLowerCase();
      list = list.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.description.toLowerCase().contains(q));
    }
    return list.toList(growable: false);
  }

  List<TestPaper> get _sortedPapers {
    final copy = [...papers];
    copy.sort((a, b) => _sortShortFirst
        ? a.durationMinutes.compareTo(b.durationMinutes)
        : b.durationMinutes.compareTo(a.durationMinutes));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isPhone = MediaQuery.of(context).size.width < 700; // FIX: MediaQuery
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final base = Theme.of(context);
    final clearOverlay = MaterialStateProperty.resolveWith<Color?>(
      (_) => Colors.transparent,
    );

    final quietTheme = base.copyWith(
      brightness: Brightness.dark,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      appBarTheme: base.appBarTheme.copyWith(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: const Color(0xFF0F151A).withOpacity(.90),
        elevation: 0,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: const Color(0xFF0F151A).withOpacity(.86),
        elevation: 0,
        height: 54,
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: base.colorScheme.onSurface.withOpacity(.10)),
        labelStyle: base.textTheme.labelSmall,
        padding: EdgeInsets.zero,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        overlayColor: clearOverlay,
        labelColor: base.colorScheme.onSurface,
        unselectedLabelColor: base.colorScheme.onSurface.withOpacity(.72),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: base.colorScheme.onSurface.withOpacity(.12),
            width: 1,
          ),
          color: const Color(0xFF1A2230).withOpacity(.55),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      ),
    );

    return Theme(
      data: quietTheme,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: _AuroraBackdrop(
          child: SafeArea(
            bottom: false,
            child: NestedScrollView(
              key: _pageKey,
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (_, __) => [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: const Color(0xFF0F151A).withOpacity(.90),
                  leading: IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go('/student');
                      }
                    },
                  ),
                  title: Text(
                    widget.category.toUpperCase(),
                    style: base.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Profile',
                      onPressed: () => context.go('/profile'),
                      icon: const Icon(Icons.person_outline),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize:
                        const Size.fromHeight(kTextTabBarHeight + 12 + 8),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Glass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: SizedBox(
                          height: kTextTabBarHeight,
                          child: TabBar(
                            controller: _tabs,
                            isScrollable: true,
                            tabs: [
                              Tab(text: 'Live • ${upcoming.length}'),
                              Tab(text: 'Previous • ${previous.length}'),
                              Tab(text: 'Content • ${content.length}'),
                              Tab(text: 'Practice & Tests • ${papers.length}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
// ─── inside NestedScrollView > headerSliverBuilder ───
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyControlsFixed(
                    height: _stickyHeightFor(context),
                    // 🔥 no outer Padding anymore
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: (_tabs.index == 2)
                          ? _contentHeader(context)
                          : (_tabs.index == 3)
                              ? _testsHeader(context)
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      key: _tabViewKey,
                      controller: _tabs,
                      children: [
                        _LiveList(
                          items: upcoming,
                          emptyText: 'No upcoming live sessions',
                          fmt: _fmt,
                          upcoming: true,
                          bottomInset: bottomSafe + (isPhone ? 54 : 0) + 24,
                          onRefresh: _load,
                        ),
                        _LiveList(
                          items: previous,
                          emptyText: 'No previous live sessions',
                          fmt: _fmt,
                          past: true,
                          bottomInset: bottomSafe + (isPhone ? 54 : 0) + 24,
                          onRefresh: _load,
                        ),
                        _ContentList(
                          items: _filteredContent,
                          bottomInset: bottomSafe + (isPhone ? 54 : 0) + 24,
                          onRefresh: _load,
                        ),
                        _TestsTab(
                          category: widget.category,
                          papers: _sortedPapers,
                          bottomInset: bottomSafe + (isPhone ? 54 : 0) + 24,
                          onRefresh: _load,
                          onSeed: () async {
                            if (papers.isNotEmpty) return;
                            final t = TestRepository();
                            final paper = await t.createPaper(
                              category: widget.category,
                              title: 'Basics Quiz',
                            );
                            await t.addQuestion(
                              paperId: paper.id,
                              text: 'Communication is mainly about?',
                              options: ['Talking', 'Listening', 'Both', 'None'],
                              correctIndex: 2,
                            );
                            await t.addQuestion(
                              paperId: paper.id,
                              text: 'Body language accounts for?',
                              options: ['7%', '38%', '55%', '100%'],
                              correctIndex: 2,
                            );
                            papers = await t.papersForCategory(widget.category);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
            ),
          ),
        ),
        bottomNavigationBar: isPhone ? const _MiniHintBar() : null,
      ),
    );
  }

  double _stickyHeightFor(BuildContext context) {
    final idx = _tabs.index;
    if (idx == 2) {
      final textScale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);
      final searchRow = 48.0 * textScale;
      final chipsRow = 34.0 * textScale;
      const gap = 8.0;
      const glassPadding = 16.0;
      const safety = 6.0;
      final computed = searchRow + chipsRow + gap + glassPadding + safety;
      return computed < 116.0 ? 116.0 : computed.ceilToDouble();
    }
    if (idx == 3) return 56.0;
    return 0.0;
  }

  /* ───────── controls ───────── */
  Widget _contentHeader(BuildContext context) {
    return Padding(
      // NEW wrapper
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.search),
                ),
                Expanded(
                  child: TextField(
                    controller: _contentSearch,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Search content…',
                    ),
                    onSubmitted: (_) => HapticFeedback.selectionClick(),
                    onChanged: (v) => setState(() => _contentQ = v.trim()),
                  ),
                ),
                if (_contentQ.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _contentSearch.clear();
                      setState(() => _contentQ = '');
                      HapticFeedback.selectionClick();
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _pill('all', 'All'),
                  _pill('video', 'Videos'),
                  _pill('note', 'Notes'),
                  _pill('link', 'Links'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String value, String label) {
    final selected = _contentType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        onSelected: (_) => setState(() => _contentType = value),
      ),
    );
  }

  Widget _testsHeader(BuildContext context) {
    return Padding(
      // NEW wrapper
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              const Icon(Icons.sort),
              const SizedBox(width: 8),
              const Text('Sort by duration'),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: true, label: Text('Short → Long')),
                  ButtonSegment<bool>(
                      value: false, label: Text('Long → Short')),
                ],
                selected: {_sortShortFirst},
                onSelectionChanged: (s) =>
                    setState(() => _sortShortFirst = s.first),
                showSelectedIcon: false,
              ),
              const SizedBox(width: 12),
              if (papers.isNotEmpty)
                const Chip(
                  avatar: Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(''),
                ),
              if (papers.isNotEmpty) Text('${papers.length} paper(s)'),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────── Sticky header ───────── */

class _StickyControlsFixed extends SliverPersistentHeaderDelegate {
  const _StickyControlsFixed({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyControlsFixed old) {
    return height != old.height || child != old.child;
  }
}

/* ───────── Live list ───────── */

class _LiveList extends StatelessWidget {
  const _LiveList({
    required this.items,
    required this.emptyText,
    required this.fmt,
    required this.onRefresh,
    required this.bottomInset,
    this.past = false,
    this.upcoming = false,
  });

  final List<LiveSession> items;
  final String emptyText;
  final DateFormat fmt;
  final Future<void> Function() onRefresh;
  final double bottomInset;
  final bool past;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final Widget list = (items.isEmpty)
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomInset),
            children: [
              const SizedBox(height: 120),
              Center(child: Text(emptyText)),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final s = items[i];
              final when = fmt.format(s.startAt);
              final hasUrl = (s.zoomUrl ?? '').trim().isNotEmpty;
              return Glass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(past
                        ? Icons.history
                        : (upcoming ? Icons.live_tv : Icons.tv_outlined)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(s.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label:
                            past ? 'Completed' : (hasUrl ? 'Ready' : 'Pending'),
                        color: past
                            ? Colors.grey
                            : (hasUrl ? Colors.greenAccent : Colors.amber),
                      ),
                    ],
                  ),
                  subtitle: Text(when),
                  trailing: past
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasUrl)
                              IconButton(
                                tooltip: 'Copy link',
                                icon: const Icon(Icons.copy),
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: s.zoomUrl!));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Link copied')),
                                    );
                                  }
                                },
                              ),
                            FilledButton(
                              onPressed: hasUrl
                                  ? () async {
                                      final url = Uri.parse(s.zoomUrl!);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url,
                                            mode:
                                                LaunchMode.externalApplication);
                                      }
                                    }
                                  : null,
                              child: const Text('Join'),
                            ),
                          ],
                        ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          );

    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: list);
  }
}

/* ───────── Content list ───────── */

class _ContentList extends StatelessWidget {
  const _ContentList({
    required this.items,
    required this.onRefresh,
    required this.bottomInset,
  });

  final List<ContentItem> items;
  final Future<void> Function() onRefresh;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final Widget list = (items.isEmpty)
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomInset),
            children: const [
              SizedBox(height: 120),
              Center(child: Text('No content yet')),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              final isLink = (c.urlOrPath ?? '').startsWith('http');
              final typeText =
                  (c.type ?? (isLink ? 'link' : 'note')).toUpperCase();
              return Glass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(
                      typeText == 'VIDEO'
                          ? Icons.play_circle_outline
                          : (typeText == 'NOTE'
                              ? Icons.description_outlined
                              : Icons.link_outlined),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: typeText, color: Colors.blueAccent),
                    ],
                  ),
                  subtitle: Text(
                    c.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: isLink ? 'Open' : 'Download',
                    icon: Icon(
                        isLink ? Icons.open_in_new : Icons.download_outlined),
                    onPressed: () async {
                      final u = c.urlOrPath;
                      if (u == null || u.trim().isEmpty) return;
                      final uri = Uri.parse(u);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
          );

    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: list);
  }
}

/* ───────── Tests tab ───────── */

class _TestsTab extends StatelessWidget {
  const _TestsTab({
    required this.category,
    required this.papers,
    required this.onSeed,
    required this.onRefresh,
    required this.bottomInset,
  });

  final String category;
  final List<TestPaper> papers;
  final VoidCallback onSeed;
  final Future<void> Function() onRefresh;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final child = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset),
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: onSeed,
              icon: const Icon(Icons.add),
              label: const Text('Seed Demo Quiz (dev)'),
            ),
            const SizedBox(width: 8),
            if (papers.isEmpty)
              const Text('No tests yet',
                  style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        const SizedBox(height: 12),
        ...papers.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Glass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      child: Icon(Icons.assignment_outlined)),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(p.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: '${p.durationMinutes} min',
                        color: Colors.purpleAccent,
                      ),
                    ],
                  ),
                  subtitle: Text(category),
                  trailing: FilledButton(
                    onPressed: () =>
                        GoRouter.of(context).go('/test/runner?paperId=${p.id}'),
                    child: const Text('Start'),
                  ),
                ),
              ),
            )),
      ],
    );

    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: child);
  }
}

/* ───────── UI helpers ───────── */

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bg = color.withOpacity(.18);
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withOpacity(.06),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
      ),
    );
  }
}

/* ───────── bottom hint ───────── */

class _MiniHintBar extends StatelessWidget {
  const _MiniHintBar();
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.80),
      height: 54,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.swipe), label: 'Swipe tabs'),
        NavigationDestination(
            icon: Icon(Icons.refresh), label: 'Pull to refresh'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
    );
  }
}

/* ───────── Aurora backdrop ───────── */

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

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const a = [Color(0xFF151A2E), Color(0xFF0D2E2A), Color(0xFF2B1F34)];
    const b = [Color(0xFF4B6FFF), Color(0xFF00D6A1), Color(0xFFFFB14B)];
    Color mix(Color x, Color y, double t) => Color.lerp(x, y, t)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final angle = 0.5 + _c.value * 0.9;
        final c0 = mix(a[0], b[0], .35 + .25 * t);
        final c1 = mix(a[1], b[1], .30 + .30 * (1 - t));
        final c2 = mix(a[2], b[2], .28 + .32 * t);

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              position: DecorationPosition.background,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    c0.withOpacity(.95),
                    c1.withOpacity(.90),
                    c2.withOpacity(.90)
                  ],
                  stops: const [0.06, 0.55, 0.98],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.60, -0.70),
                  radius: 1.25,
                  colors: [c2.withOpacity(.34), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            Transform.rotate(
              angle: angle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: const Alignment(0.0, 0.2),
                    startAngle: 0,
                    endAngle: 6.28318,
                    colors: [
                      c0.withOpacity(.06),
                      c2.withOpacity(.03),
                      c1.withOpacity(.05),
                      c0.withOpacity(.06),
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
