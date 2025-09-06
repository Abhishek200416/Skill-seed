// lib/ui/screens/teacher/teacher_dashboard.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../core/styles.dart';
import '../../../data/models/live_session.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../services/notification_service.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;

/// Teacher Dashboard
/// - Schedule live classes (with default category + neat form)
/// - Manage upcoming & previous sessions (by category, with search)
/// - Attach Zoom links later
/// - Quick actions (duplicate, open/copy Zoom, attendance)
/// - Smooth, overlay-free UI with premium gradient background
/// - Separate Profile screen (route)
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherState();
}

class _TeacherState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // ── Form + flow state
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _zoom = TextEditingController();
  final _category = ValueNotifier<String>('COMMUNICATION');

  DateTime? _startAt;
  final _sessionId = ValueNotifier<String?>(null);
  bool _saving = false;

  // ── History + filters
  final _q = TextEditingController();
  final _historyCategory = ValueNotifier<String>('COMMUNICATION');
  List<LiveSession> _upcoming = [];
  List<LiveSession> _previous = [];
  bool _loading = true;
  String? _error;
  String? _indexUrl;

  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _fmt = DateFormat('EEE, d MMM • h:mm a');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
    _refreshHistory();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _zoom.dispose();
    _q.dispose();
    _category.dispose();
    _historyCategory.dispose();
    _sessionId.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Data
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _refreshHistory() async {
    setState(() {
      _loading = true;
      _error = null;
      _indexUrl = null;
    });

    try {
      final repo = ClassRepository();
      final cat = _historyCategory.value;

      // Optionally scope by teacher later:
      // final teacherId = FirebaseAuth.instance.currentUser?.uid;
      // final up = await repo.upcoming(cat, teacherId: teacherId);
      // final prev = await repo.previous(cat, teacherId: teacherId);

      final up = await repo.upcoming(cat);
      final prev = await repo.previous(cat);

      if (!mounted) return;
      setState(() {
        _upcoming = up;
        _previous = prev;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _indexUrl = _extractIndexLink(e);
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String? _extractIndexLink(Object e) {
    final msg = (e is FirebaseException) ? (e.message ?? '') : e.toString();
    final m = RegExp(r'https:\/\/console\.firebase\.google\.com[^\s)]+')
        .firstMatch(msg);
    return m?.group(0);
  }

  List<LiveSession> _filter(List<LiveSession> list) {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            (_fmt.format(s.startAt)).toLowerCase().contains(q))
        .toList(growable: false);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final base = Theme.of(context);

    // Quiet local theme – no splash/overlay, crisp inputs, premium feel
    final clearOverlay =
        MaterialStateProperty.resolveWith<Color?>((_) => Colors.transparent);
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
      tabBarTheme: base.tabBarTheme.copyWith(
        overlayColor: clearOverlay,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: base.colorScheme.surface.withOpacity(.40),
          border: Border.all(
            color: base.colorScheme.onSurface.withOpacity(.10),
            width: 1,
          ),
        ),
        labelColor: base.colorScheme.onSurface,
        unselectedLabelColor: base.colorScheme.onSurface.withOpacity(.72),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: base.colorScheme.surface.withOpacity(.78),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: base.textTheme.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.80),
          letterSpacing: .2,
        ),
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

    return Theme(
      data: quiet,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
          ),
          title: const Text('Teacher Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
            IconButton(
              tooltip: 'Upload content',
              onPressed: () => context.go('/teacher/upload'),
              icon: const Icon(Icons.upload_file_outlined),
            ),
            IconButton(
              tooltip: 'Preferences',
              onPressed: _openPreferences,
              icon: const Icon(Icons.tune),
            ),
            IconButton(
              tooltip: 'Profile',
              onPressed: _openProfile,
              icon: const Icon(Icons.account_circle_outlined),
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu',
              onSelected: (v) async {
                switch (v) {
                  case 'profile':
                    _openProfile();
                    break;
                  case 'logout':
                    await _logout();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.person_outline),
                    title: Text('Open profile'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight + 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Glass(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: SizedBox(
                  height: kTextTabBarHeight,
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Schedule'),
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Previous'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: AnimatedPageGradient(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _StickyFilters(
                  visible: _tabs.index != 0,
                  category: _historyCategory,
                  query: _q,
                  onFilter: _refreshHistory,
                ),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (_loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_error != null) {
                        return _ErrorState(
                          message: 'Could not load sessions.\n$_error',
                          onRetry: _refreshHistory,
                          indexUrl: _indexUrl,
                        );
                      }
                      return TabBarView(
                        controller: _tabs,
                        children: [
                          _ScheduleForm(
                            formKey: _form,
                            title: _title,
                            zoom: _zoom,
                            category: _category,
                            startAt: _startAt,
                            fmt: _fmt,
                            saving: _saving,
                            onPickStart: _pickStartAt,
                            onSubmit: _schedule,
                            sessionIdListenable: _sessionId,
                            onAttachZoom: _attachZoom,
                          ),
                          _SessionsList(
                            title: 'Upcoming',
                            items: _filter(_upcoming),
                            fmt: _fmt,
                            onRefresh: _refreshHistory,
                            onDuplicate: _duplicateFrom,
                            onAttachZoom: _attachZoomFor,
                            onOpenZoom: _openZoomFor,
                            onCopyZoom: _copyZoomFor,
                            onViewAttendance: (s) =>
                                _openAttendanceCollector(context, s),
                          ),
                          _SessionsList(
                            title: 'Previous',
                            items: _filter(_previous),
                            fmt: _fmt,
                            onRefresh: _refreshHistory,
                            onDuplicate: _duplicateFrom,
                            onAttachZoom: _attachZoomFor,
                            onOpenZoom: _openZoomFor,
                            onCopyZoom: _copyZoomFor,
                            onViewAttendance: (s) =>
                                _openAttendanceCollector(context, s),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _pickStartAt() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _startAt ?? now,
    );
    if (date == null) return;

    final initial = _startAt ?? now.add(const Duration(minutes: 30));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final chosen =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (chosen.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a future time')),
      );
      return;
    }
    setState(() => _startAt = chosen);
  }

  Future<void> _schedule() async {
    if (!_form.currentState!.validate() || _startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the form (pick date & time)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ClassRepository();
      final session = await repo.scheduleLive(
        category: _category.value,
        teacherId: FirebaseAuth.instance.currentUser?.uid ?? 'tbd-teacher',
        title: _title.text.trim(),
        startAt: _startAt!,
      );
      _sessionId.value = session.id;

      // Local reminder for learners (your NotificationService handles channels)
      await NotificationService.instance.fiveMinBefore(
        session.startAt,
        title: 'Live starts soon',
        body: session.title,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled. Add Zoom link 5 min before.')),
      );

      _title.clear(); // keep category/time for quick scheduling
      unawaited(_refreshHistory());
      _tabs.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _indexUrl = _extractIndexLink(e));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _attachZoom() async {
    final id = _sessionId.value;
    if (id == null || _zoom.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule first and paste link')),
      );
      return;
    }
    final url = _zoom.text.trim();
    if (_validateUrlOrEmpty(url) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Zoom URL')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await ClassRepository().attachZoom(id, url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zoom link attached')),
      );
      unawaited(_refreshHistory());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not attach link: $e')),
      );
    }
  }

  Future<void> _attachZoomFor(LiveSession s) async {
    final controller = TextEditingController(text: s.zoomUrl ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(ctx).padding.bottom,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.link_outlined),
              title:
                  Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(_fmt.format(s.startAt)),
            ),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Zoom Link',
                hintText: 'https://…',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final link = controller.text.trim();
    if (_validateUrlOrEmpty(link) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Zoom URL')),
      );
      return;
    }
    try {
      await ClassRepository().attachZoom(s.id, link);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zoom link updated')),
      );
      unawaited(_refreshHistory());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update link: $e')),
      );
    }
  }

  Future<void> _openZoomFor(LiveSession s) async {
    final link = s.zoomUrl;
    if (link == null || _validateUrlOrEmpty(link) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid Zoom link to open')),
      );
      return;
    }
    final ok =
        await launchUrlString(link, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _copyZoomFor(LiveSession s) async {
    final link = s.zoomUrl;
    if (link == null || _validateUrlOrEmpty(link) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid Zoom link to copy')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied')),
      );
    }
  }

  void _duplicateFrom(LiveSession s) {
    _category.value = s.category;
    _title.text = s.title;
    _startAt = s.startAt.add(const Duration(days: 7));
    _tabs.animateTo(0);
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details copied to Schedule form')),
    );
  }

  void _openPreferences() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 12 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              dense: true,
              leading: Icon(Icons.settings_outlined),
              title: Text('Preferences'),
              subtitle: Text('Defaults & personalization'),
            ),
            ValueListenableBuilder<String>(
              valueListenable: _category,
              builder: (_, v, __) => DropdownButtonFormField<String>(
                value: v,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'COMMUNICATION', child: Text('Communication')),
                  DropdownMenuItem(value: 'TEAMWORK', child: Text('Teamwork')),
                  DropdownMenuItem(
                      value: 'CREATIVITY', child: Text('Creativity')),
                  DropdownMenuItem(
                      value: 'TIME MANAGEMENT', child: Text('Time Management')),
                  DropdownMenuItem(
                      value: 'LEADERSHIP', child: Text('Leadership')),
                  DropdownMenuItem(
                      value: 'PROBLEM SOLVING', child: Text('Problem Solving')),
                  DropdownMenuItem(
                      value: 'SELF-REFLECTION', child: Text('Self-Reflection')),
                ],
                onChanged: (nv) => nv != null ? _category.value = nv : null,
                decoration: const InputDecoration(
                  labelText: 'Default category for new classes',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset form'),
                    onPressed: () {
                      _title.clear();
                      _zoom.clear();
                      _startAt = null;
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: const Text('Done'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttendanceCollector(
      BuildContext context, LiveSession s) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AttendanceSheet(session: s, fmt: _fmt),
    );
  }

  // Now navigates to a separate screen
  void _openProfile() => context.go('/teacher/profile');

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) context.go('/login');
    }
  }

  String? _validateUrlOrEmpty(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final ok = s.startsWith('http://') || s.startsWith('https://');
    return ok ? null : 'Enter a valid URL';
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sticky filters
// ────────────────────────────────────────────────────────────────────────────

class _StickyFilters extends StatelessWidget {
  const _StickyFilters({
    required this.visible,
    required this.category,
    required this.query,
    required this.onFilter,
  });

  final bool visible;
  final ValueNotifier<String> category;
  final TextEditingController query;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Glass(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: query,
                      decoration: const InputDecoration(
                        hintText: 'Search by title or date…',
                        isDense: true,
                        filled: true,
                      ),
                      onSubmitted: (_) => onFilter(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Apply',
                    onPressed: onFilter,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<String>(
                  valueListenable: category,
                  builder: (_, v, __) => ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 220, maxWidth: 420),
                    child: DropdownButtonFormField<String>(
                      value: v,
                      isExpanded: true, // avoids overflow on narrow screens
                      items: const [
                        DropdownMenuItem(
                            value: 'COMMUNICATION',
                            child: Text('Communication')),
                        DropdownMenuItem(
                            value: 'TEAMWORK', child: Text('Teamwork')),
                        DropdownMenuItem(
                            value: 'CREATIVITY', child: Text('Creativity')),
                        DropdownMenuItem(
                            value: 'TIME MANAGEMENT',
                            child: Text('Time Management')),
                        DropdownMenuItem(
                            value: 'LEADERSHIP', child: Text('Leadership')),
                        DropdownMenuItem(
                            value: 'PROBLEM SOLVING',
                            child: Text('Problem Solving')),
                        DropdownMenuItem(
                            value: 'SELF-REFLECTION',
                            child: Text('Self-Reflection')),
                      ],
                      onChanged: (nv) {
                        if (nv != null) {
                          category.value = nv;
                          onFilter();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        filled: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Schedule form card
// ────────────────────────────────────────────────────────────────────────────

class _ScheduleForm extends StatelessWidget {
  const _ScheduleForm({
    required this.formKey,
    required this.title,
    required this.zoom,
    required this.category,
    required this.startAt,
    required this.fmt,
    required this.saving,
    required this.onPickStart,
    required this.onSubmit,
    required this.sessionIdListenable,
    required this.onAttachZoom,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController zoom;
  final ValueNotifier<String> category;
  final DateTime? startAt;
  final DateFormat fmt;
  final bool saving;
  final VoidCallback onPickStart;
  final VoidCallback onSubmit;
  final ValueListenable<String?> sessionIdListenable;
  final VoidCallback onAttachZoom;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Glass(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule a Live Class',
                      style: base.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    ValueListenableBuilder<String>(
                      valueListenable: category,
                      builder: (_, value, __) =>
                          DropdownButtonFormField<String>(
                        value: value,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'COMMUNICATION',
                              child: Text('Communication')),
                          DropdownMenuItem(
                              value: 'TEAMWORK', child: Text('Teamwork')),
                          DropdownMenuItem(
                              value: 'CREATIVITY', child: Text('Creativity')),
                          DropdownMenuItem(
                              value: 'TIME MANAGEMENT',
                              child: Text('Time Management')),
                          DropdownMenuItem(
                              value: 'LEADERSHIP', child: Text('Leadership')),
                          DropdownMenuItem(
                              value: 'PROBLEM SOLVING',
                              child: Text('Problem Solving')),
                          DropdownMenuItem(
                              value: 'SELF-REFLECTION',
                              child: Text('Self-Reflection')),
                        ],
                        onChanged: (v) => v != null ? category.value = v : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'Session Title',
                        hintText: 'e.g., Active Listening 101',
                        prefixIcon: Icon(Icons.title_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Start time
                    OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        startAt == null
                            ? 'Pick start date & time'
                            : fmt.format(startAt!),
                      ),
                      onPressed: saving ? null : onPickStart,
                    ),
                    const SizedBox(height: 16),

                    // Schedule action
                    GradientButton(
                      loading: saving,
                      label: saving ? 'Scheduling…' : 'Schedule Live',
                      onPressed: saving ? null : onSubmit,
                    ),

                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Zoom link attach
                    Text(
                      'Attach Zoom Link',
                      style: base.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: zoom,
                      decoration: const InputDecoration(
                        labelText: 'Zoom Link (enable ~5 min before start)',
                        hintText: 'https://…',
                        prefixIcon: Icon(Icons.link_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 10),

                    // React to both session id and zoom text changes
                    ValueListenableBuilder<String?>(
                      valueListenable: sessionIdListenable,
                      builder: (_, id, __) {
                        return ValueListenableBuilder<TextEditingValue>(
                          valueListenable: zoom,
                          builder: (_, v, __) {
                            final canAttach = (id != null) &&
                                v.text.trim().isNotEmpty &&
                                !saving;
                            return FilledButton(
                              onPressed: canAttach ? onAttachZoom : null,
                              child: const Text('Attach Zoom Link'),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tips
            Glass(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: schedule early and paste the Zoom link ~5 minutes '
                      'before start. Learners get an automatic reminder.',
                      style: base.textTheme.bodyMedium?.copyWith(
                        color: base.colorScheme.onSurface.withOpacity(.80),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Sessions list with actions (duplicate, attach link, open/copy, attendance)
// ────────────────────────────────────────────────────────────────────────────

class _SessionsList extends StatelessWidget {
  const _SessionsList({
    required this.title,
    required this.items,
    required this.fmt,
    required this.onRefresh,
    required this.onDuplicate,
    required this.onAttachZoom,
    required this.onOpenZoom,
    required this.onCopyZoom,
    required this.onViewAttendance,
  });

  final String title;
  final List<LiveSession> items;
  final DateFormat fmt;
  final Future<void> Function() onRefresh;
  final void Function(LiveSession) onDuplicate;
  final Future<void> Function(LiveSession) onAttachZoom;
  final Future<void> Function(LiveSession) onOpenZoom;
  final Future<void> Function(LiveSession) onCopyZoom;
  final void Function(LiveSession) onViewAttendance;

  @override
  Widget build(BuildContext context) {
    final list = (items.isEmpty)
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            children: [
              Center(
                child: Text(
                  'No $title sessions',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = items[i];
              final hasZoom = (s.zoomUrl ?? '').trim().isNotEmpty;
              return Glass(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const CircleAvatar(child: Icon(Icons.event_available)),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(label: s.category, color: Colors.blueAccent),
                    ],
                  ),
                  subtitle: Text(fmt.format(s.startAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'duplicate':
                          onDuplicate(s);
                          break;
                        case 'attach':
                          onAttachZoom(s);
                          break;
                        case 'open':
                          onOpenZoom(s);
                          break;
                        case 'copy':
                          onCopyZoom(s);
                          break;
                        case 'attendance':
                          onViewAttendance(s);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attach',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.link_outlined),
                          title: Text('Attach / Update Zoom link'),
                        ),
                      ),
                      PopupMenuItem(
                        enabled: hasZoom,
                        value: 'open',
                        child: const ListTile(
                          dense: true,
                          leading: Icon(Icons.open_in_new),
                          title: Text('Open Zoom link'),
                        ),
                      ),
                      PopupMenuItem(
                        enabled: hasZoom,
                        value: 'copy',
                        child: const ListTile(
                          dense: true,
                          leading: Icon(Icons.content_copy),
                          title: Text('Copy Zoom link'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attendance',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.people_alt_outlined),
                          title: Text('View attendee emails'),
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_horiz),
                  ),
                ),
              );
            },
          );

    return RefreshIndicator.adaptive(onRefresh: onRefresh, child: list);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Attendance collector/viewer
// ────────────────────────────────────────────────────────────────────────────

class _AttendanceSheet extends StatefulWidget {
  const _AttendanceSheet({required this.session, required this.fmt});
  final LiveSession session;
  final DateFormat fmt;

  @override
  State<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<_AttendanceSheet> {
  final _raw = TextEditingController();
  final Set<String> _emails = <String>{};
  bool _parsed = false;

  @override
  void dispose() {
    _raw.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _raw.text;
    final regex =
        RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false);
    final found = regex.allMatches(text).map((m) => m.group(0)!.toLowerCase());
    setState(() {
      _emails
        ..clear()
        ..addAll(found);
      _parsed = true;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text != null) {
      _raw.text = clip!.text!;
      _parse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.people_alt_outlined),
            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(widget.fmt.format(s.startAt)),
            trailing: _Badge(label: 'Attendance', color: Colors.greenAccent),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _raw,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Paste emails (from Zoom CSV/log) or type manually',
              hintText: 'alice@college.edu, bob@uni.ac.in …',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste'),
                  onPressed: _paste,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Extract emails'),
                  onPressed: _parse,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _parsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Scrollbar(
                child: ListView.separated(
                  itemCount: _emails.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final email = _emails.elementAt(i);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(email),
                      trailing: IconButton(
                        tooltip: 'Copy',
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: email));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email copied')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_emails.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copy all'),
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: _emails.join(', ')));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All emails copied')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export CSV'),
                    onPressed: () async {
                      final csv = StringBuffer('email\n');
                      for (final e in _emails) {
                        csv.writeln(e);
                      }
                      await Clipboard.setData(
                          ClipboardData(text: csv.toString()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('CSV copied to clipboard')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Little badge pill
// ────────────────────────────────────────────────────────────────────────────

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
        border: Border.all(color: fg.withOpacity(.06), width: 1),
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

// ────────────────────────────────────────────────────────────────────────────
// Error UI (with Create Index button)
// ────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.indexUrl,
  });

  final String message;
  final VoidCallback onRetry;
  final String? indexUrl;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text('Something went wrong', style: t.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: t.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.75),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 8),
                if (indexUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => launchUrlString(indexUrl!,
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Create index'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
