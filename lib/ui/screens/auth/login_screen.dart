import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../../../core/styles.dart';
import '../widgets/role_hero.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _show = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Overlay-free, premium field theming
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
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        isDense: true,
        fillColor: base.colorScheme.surface.withOpacity(.78),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        prefixIconColor: base.colorScheme.onSurface.withOpacity(.85),
        suffixIconColor: base.colorScheme.onSurface.withOpacity(.85),
        labelStyle: base.textTheme.bodySmall?.copyWith(
          letterSpacing: .2,
          color: base.colorScheme.onSurface.withOpacity(.80),
        ),
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
              color: base.colorScheme.primary.withOpacity(.45), width: 1.2),
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
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;

                // ── Wide: form left (glass), hero right (cover)
                if (wide) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Glass(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 16),
                                child: _LoginForm(
                                  form: _form,
                                  email: _email,
                                  password: _password,
                                  loading: _loading,
                                  show: _show,
                                  emailFocus: _emailFocus,
                                  passFocus: _passFocus,
                                  onToggleShow: () =>
                                      setState(() => _show = !_show),
                                  onSubmit: _submit,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Stack(
                          fit: StackFit.expand,
                          children: const [
                            RoleHeroImage(
                              role: RoleKind.login,
                              gender: GenderKind.neutral,
                              asBackground: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // ── Mobile: hero above, form below
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Glass(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            const RoleHeroImage(
                              role: RoleKind.login,
                              gender: GenderKind.neutral,
                              height: 140,
                            ),
                            const SizedBox(height: 8),
                            _LoginForm(
                              form: _form,
                              email: _email,
                              password: _password,
                              loading: _loading,
                              show: _show,
                              emailFocus: _emailFocus,
                              passFocus: _passFocus,
                              onToggleShow: () =>
                                  setState(() => _show = !_show),
                              onSubmit: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final repo = ref.read(authRepoProvider);
    final email = _email.text.trim();
    final pass = _password.text;

    final user = await repo.signInEmail(email, pass);
    if (!mounted) return;
    setState(() => _loading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong email or password')),
      );
      return;
    }

    if (user.role == 'admin') {
      context.go('/admin');
    } else if (user.role == 'teacher') {
      user.isApproved
          ? context.go('/teacher')
          : ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Awaiting admin approval')),
            );
    } else {
      context.go('/student');
    }
  }
}

/* ───────────────────────── Form ───────────────────────── */

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.form,
    required this.email,
    required this.password,
    required this.loading,
    required this.show,
    required this.onToggleShow,
    required this.onSubmit,
    required this.emailFocus,
    required this.passFocus,
  });

  final GlobalKey<FormState> form;
  final TextEditingController email;
  final TextEditingController password;
  final bool loading;
  final bool show;
  final VoidCallback onToggleShow;
  final Future<void> Function() onSubmit;
  final FocusNode emailFocus;
  final FocusNode passFocus;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;

    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue building your soft-skills momentum.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: on.withOpacity(.72),
                ),
          ),
          const SizedBox(height: 18),

          // Email
          _Input(
            controller: email,
            label: 'Email',
            hint: 'you@college.edu',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusNode: emailFocus,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(passFocus),
            enabled: !loading,
            validator: (v) {
              final s = (v ?? '').trim();
              final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
              return ok ? null : 'Enter a valid email';
            },
          ),
          const SizedBox(height: 12),

          // Password
          _Input(
            controller: password,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscure: !show,
            trailing: IconButton(
              icon: Icon(show ? Icons.visibility_off : Icons.visibility),
              onPressed: loading ? null : onToggleShow,
            ),
            textInputAction: TextInputAction.done,
            focusNode: passFocus,
            onFieldSubmitted: (_) => onSubmit(),
            enabled: !loading,
            validator: (v) =>
                (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 16),

          // Submit
          GradientButton(
            loading: loading,
            label: loading ? 'Signing in…' : 'Sign In',
            onPressed: loading ? null : onSubmit,
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : () {}, // wire your reset flow
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('New here?'),
              TextButton(
                onPressed: loading ? null : () => _showRolePicker(context),
                child: const Text('Create account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRolePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.96),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
              title: const Text('Register as Student'),
              subtitle: const Text('Access live classes, practice, tests'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/register/student');
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const CircleAvatar(child: Icon(Icons.co_present_outlined)),
              title: const Text('Register as Teacher'),
              subtitle:
                  const Text('Upload content, schedule live, create tests'),
              trailing: const Chip(label: Text('Approval needed')),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/register/teacher');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── Inputs ───────────────────────── */

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.trailing,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Widget? trailing;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : (obscure ? const [AutofillHints.password] : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: trailing,
      ),
    );
  }
}

/* ───────────────────────── Backdrop ───────────────────────── */

// Subtle aurora gradient backdrop (linear + radial + sweep), no harsh flashes.
class _AuroraBackdrop extends StatefulWidget {
  const _AuroraBackdrop({required this.child});
  final Widget child;

  @override
  State<_AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<_AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = [Color(0xFF141826), Color(0xFF0F2A28), Color(0xFF261C30)];
    const accent = [Color(0xFF4B6FFF), Color(0xFF00D6A1), Color(0xFFFFB14B)];
    Color mix(Color x, Color y, double t) => Color.lerp(x, y, t)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_c.value);
        final c0 = mix(base[0], accent[0], .28 + .28 * t);
        final c1 = mix(base[1], accent[1], .24 + .30 * (1 - t));
        final c2 = mix(base[2], accent[2], .22 + .32 * t);

        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
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
              angle: 0.4 + _c.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: const Alignment(0.0, 0.2),
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
