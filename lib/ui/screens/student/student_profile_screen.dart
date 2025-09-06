import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/styles.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});
  @override
  State<StudentProfileScreen> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfileScreen> {
  final _auth = AuthRepository();
  AppUser? me;
  bool _loading = true;

  // Persist scroll position to avoid visual “jump” on return
  final _scrollKey = const PageStorageKey<String>('profile_scroll');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    me = await _auth.currentUser();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) context.go('/login');
  }

  void _openEditSheet() async {
    if (me == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        user: me!,
        onSaved: (updated) async {
          await _auth.updateStudentProfile(
            id: updated.id,
            name: updated.name,
            phone: updated.phone ?? '',
            age: updated.age ?? 0,
            college: updated.college ?? '',
            standard: updated.standard ?? '',
          );
          if (!mounted) return;
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated')),
          );
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Local, overlay-free theme (no blue/tint washes; neat textography)
    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: WidgetStatePropertyAll<Color>(Colors.transparent),
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
      // Inputs mainly used inside the sheet (filled + subtle border)
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
        backgroundColor: Colors.transparent, // prevents route flash
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
                                context.go('/student');
                              }
                            },
                          ),
                          title: const Text('Profile'),
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
                                  // slight frosted avatar to fit the glass theme
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
                                    child: _TitleBlock(
                                      name: me?.name ?? '—',
                                      email: me?.email ?? '—',
                                    ),
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
                                ('Phone', me?.phone ?? '—'),
                                ('College', me?.college ?? '—'),
                                ('Standard', me?.standard ?? '—'),
                                (
                                  'Age',
                                  ((me?.age ?? 0) == 0) ? '—' : '${me!.age}'
                                ),
                                ('Role', me?.role ?? 'student'),
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
                                    icon: Icons.military_tech_outlined,
                                    label: 'Leaderboard',
                                    onTap: () => context.go(
                                      '/leaderboard?category=COMMUNICATION',
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.notifications_outlined,
                                    label: 'Notifications',
                                    onTap: () => context.go('/notifications'),
                                  ),
                                  _QuickAction(
                                    icon: Icons.psychology_outlined,
                                    label: 'Explore categories',
                                    onTap: () => context.go('/student'),
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
              maxLines: 2,
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
          gradient: s.gradients.button, // keep your brand gradient
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSaved});
  final AppUser user;
  final ValueChanged<AppUser> onSaved;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone ?? '');
  late final TextEditingController _college =
      TextEditingController(text: widget.user.college ?? '');
  late final TextEditingController _standard =
      TextEditingController(text: widget.user.standard ?? '');
  late final TextEditingController _age = TextEditingController(
      text: (widget.user.age ?? 0) == 0 ? '' : '${widget.user.age}');

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _college.dispose();
    _standard.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = widget.user.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      college: _college.text.trim().isEmpty ? null : _college.text.trim(),
      standard: _standard.text.trim().isEmpty ? null : _standard.text.trim(),
      age: int.tryParse(_age.text.trim().isEmpty ? '0' : _age.text.trim()),
    );

    await Future<void>.delayed(
        const Duration(milliseconds: 200)); // tiny UX delay
    if (!mounted) return;
    widget.onSaved(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Frosted sheet that adapts to keyboard
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
                      const Icon(Icons.badge_outlined),
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
                    controller: _phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                        labelText: 'Phone', hintText: '10 digits'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _college,
                          autofillHints: const [AutofillHints.organizationName],
                          decoration:
                              const InputDecoration(labelText: 'College'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _standard,
                          decoration:
                              const InputDecoration(labelText: 'Standard'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _age,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: (v) {
                      if ((v ?? '').isEmpty) return null; // optional
                      final n = int.tryParse(v!);
                      if (n == null || n < 5 || n > 120)
                        return 'Enter a valid age';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Save
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

// Premium aurora backdrop (linear + radial + sweep – subtle, not loud)
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
    // Palette A (deep base) → Palette B (brand-ish accents)
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
            // Base linear gradient
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
            // Soft radial glow
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
            // Gentle sweep shimmer
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
