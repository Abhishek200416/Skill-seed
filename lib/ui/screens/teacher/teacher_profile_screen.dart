// lib/ui/screens/teacher/teacher_profile_screen.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/styles.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});
  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileState();
}

class _TeacherProfileState extends State<TeacherProfileScreen> {
  bool _loading = true;
  String? _error;

  String _name = '—';
  String _email = '—';
  String _specialty = '—';
  String _about = '—';

  final _scrollKey = const PageStorageKey<String>('teacher_profile_scroll');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final mail = FirebaseAuth.instance.currentUser?.email ?? '—';
      if (uid == null) {
        setState(() {
          _loading = false;
          _error = 'Not signed in';
        });
        return;
      }
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final m = doc.data() ?? {};
      setState(() {
        _email = mail;
        _name =
            (m['name'] as String?)?.trim().isNotEmpty == true ? m['name'] : '—';
        _specialty = (m['specialty'] as String?)?.trim().isNotEmpty == true
            ? m['specialty']
            : '—';
        _about = (m['about'] as String?)?.trim().isNotEmpty == true
            ? m['about']
            : '—';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _openEditSheet() async {
    final updated = await showModalBottomSheet<
        ({String name, String specialty, String about})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditTeacherSheet(
        name: _name == '—' ? '' : _name,
        specialty: _specialty == '—' ? '' : _specialty,
        about: _about == '—' ? '' : _about,
      ),
    );
    if (updated == null) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': updated.name.trim(),
        'specialty': updated.specialty.trim(),
        'about': updated.about.trim(),
        'role': 'teacher',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

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
      appBarTheme: base.appBarTheme.copyWith(
        surfaceTintColor: Colors.transparent,
        backgroundColor: base.colorScheme.surface.withOpacity(.78),
        elevation: 0,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
          color: base.colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: base.colorScheme.surface.withOpacity(.70),
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
              color: base.colorScheme.primary.withOpacity(.45), width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: base.textTheme.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.80),
          letterSpacing: .2,
        ),
      ),
    );

    return Theme(
      data: quiet,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: _AuroraBackdrop(
          child: SafeArea(
            child: ScrollConfiguration(
              behavior: const _NoGlow(),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      key: _scrollKey,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          floating: true,
                          snap: true,
                          leading: IconButton(
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              if (GoRouter.of(context).canPop()) {
                                context.pop();
                              } else {
                                context.go('/teacher');
                              }
                            },
                          ),
                          title: const Text('Teacher Profile'),
                          actions: [
                            IconButton(
                              tooltip: 'Log out',
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                            ),
                          ],
                        ),

                        // Header card
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          sliver: SliverToBoxAdapter(
                            child: Glass(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: const CircleAvatar(
                                        radius: 28,
                                        child: Icon(Icons.person),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child:
                                        _TitleBlock(name: _name, email: _email),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                    onPressed: _openEditSheet,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Details section
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          sliver: SliverToBoxAdapter(
                            child: _DetailSection(
                              title: 'Details',
                              rows: [
                                ('Specialty', _specialty),
                                ('About', _about),
                                ('Email', _email),
                                ('Role', 'teacher'),
                              ],
                            ),
                          ),
                        ),

                        // Quick actions
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          sliver: SliverToBoxAdapter(
                            child: Glass(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _QuickAction(
                                    icon: Icons.add_circle_outline,
                                    label: 'Schedule class',
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      context
                                          .go('/teacher'); // lands on dashboard
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.upload_file_outlined,
                                    label: 'Upload content',
                                    onTap: () => context.go('/teacher/upload'),
                                  ),
                                  _QuickAction(
                                    icon: Icons.notifications_outlined,
                                    label: 'Notifications',
                                    onTap: () => context.go('/notifications'),
                                  ),
                                ],
                              ),
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
}

/* ───────────────────────── UI pieces ───────────────────────── */

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: t.bodySmall?.copyWith(color: on.withOpacity(.80)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;

    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .2),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rows.length; i++) ...[
            _Row(label: rows[i].$1, value: rows[i].$2),
            if (i != rows.length - 1)
              Divider(height: 12, color: on.withOpacity(.06)),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: style.bodySmall?.copyWith(
                color: on.withOpacity(.80),
                letterSpacing: .2,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: style.bodyMedium?.copyWith(letterSpacing: .1),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: s.radii.chip,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: s.radii.chip,
          gradient: s.gradients.button,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
    );
  }
}

/* ───────────────────────── Edit Sheet ───────────────────────── */

class _EditTeacherSheet extends StatefulWidget {
  const _EditTeacherSheet({
    required this.name,
    required this.specialty,
    required this.about,
  });

  final String name;
  final String specialty;
  final String about;

  @override
  State<_EditTeacherSheet> createState() => _EditTeacherSheetState();
}

class _EditTeacherSheetState extends State<_EditTeacherSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.name);
  late final TextEditingController _spec =
      TextEditingController(text: widget.specialty);
  late final TextEditingController _about =
      TextEditingController(text: widget.about);

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _spec.dispose();
    _about.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    // tiny UX delay
    Future<void>.delayed(const Duration(milliseconds: 180)).then((_) {
      if (!mounted) return;
      Navigator.pop<({String name, String specialty, String about})>(context, (
        name: _name.text.trim(),
        specialty: _spec.text.trim(),
        about: _about.text.trim(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Glass(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 8),
                      Text(
                        'Edit profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(.08),
                  ),

                  // Fields
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _spec,
                    decoration: const InputDecoration(labelText: 'Specialty'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _about,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'About'),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── Backdrops & Helpers ───────────────────────── */

// Premium aurora backdrop (linear + radial + sweep – subtle)
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
    const a = [Color(0xFF141826), Color(0xFF0F2A28), Color(0xFF261C30)];
    const b = [Color(0xFF4B6FFF), Color(0xFF00D6A1), Color(0xFFFFB14B)];
    Color mix(Color x, Color y, double t) => Color.lerp(x, y, t)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
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
                    c2.withOpacity(.90),
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
              angle: 0.4 + _c.value * 1.0,
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

class _NoGlow extends ScrollBehavior {
  const _NoGlow();
  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
