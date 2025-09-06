import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_providers.dart';
import '../../../core/validators.dart';
import '../../../core/styles.dart';
import '../widgets/role_hero.dart';

class RegisterTeacherScreen extends ConsumerStatefulWidget {
  const RegisterTeacherScreen({super.key});
  @override
  ConsumerState<RegisterTeacherScreen> createState() => _RegTeacherState();
}

class _RegTeacherState extends ConsumerState<RegisterTeacherScreen> {
  final _form = GlobalKey<FormState>();

  // Inputs
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _specialty = TextEditingController();
  final _about = TextEditingController();
  final _password = TextEditingController();

  // Focus
  final _fName = FocusNode();
  final _fEmail = FocusNode();
  final _fPhone = FocusNode();
  final _fSpec = FocusNode();
  final _fAbout = FocusNode();
  final _fPassword = FocusNode();

  bool _loading = false;
  bool _show = false;

  double get _strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    double v = 0;
    if (p.length >= 6) v += .34;
    if (RegExp(r'[A-Z]').hasMatch(p)) v += .22;
    if (RegExp(r'[0-9]').hasMatch(p)) v += .22;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) v += .22;
    return v.clamp(0, 1);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _specialty.dispose();
    _about.dispose();
    _password.dispose();
    _fName.dispose();
    _fEmail.dispose();
    _fPhone.dispose();
    _fSpec.dispose();
    _fAbout.dispose();
    _fPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Overlay-free, premium theme for crisp inputs & buttons
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
        isDense: true,
        filled: true,
        fillColor: base.colorScheme.surface.withOpacity(.78),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            color: base.colorScheme.primary.withOpacity(.45),
            width: 1.2,
          ),
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
        extendBody: true,
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
          title: const Text('Register • Teacher'),
        ),
        body: _AuroraBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 980;

                if (wide) {
                  // Side-by-side: Hero panel + Form panel
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Hero
                            Expanded(
                              flex: 6,
                              child: Glass(
                                padding: const EdgeInsets.all(16),
                                child: RoleHeroImage(
                                  role: RoleKind.teacher,
                                  gender: GenderKind.neutral,
                                  asBackground: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Form
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 580),
                                  child: Glass(
                                    padding: const EdgeInsets.fromLTRB(
                                        18, 18, 18, 16),
                                    child: _FormBody(
                                      form: _form,
                                      loading: _loading,
                                      name: _name,
                                      email: _email,
                                      phone: _phone,
                                      specialty: _specialty,
                                      about: _about,
                                      password: _password,
                                      show: _show,
                                      onToggleShow: () =>
                                          setState(() => _show = !_show),
                                      onChangedPassword: () => setState(() {}),
                                      fName: _fName,
                                      fEmail: _fEmail,
                                      fPhone: _fPhone,
                                      fSpec: _fSpec,
                                      fAbout: _fAbout,
                                      fPassword: _fPassword,
                                      strength: _strength,
                                      onSubmit: _submit,
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

                // Mobile/compact: stacked
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Glass(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            const RoleHeroImage(
                              role: RoleKind.teacher,
                              gender: GenderKind.neutral,
                              height: 120,
                            ),
                            const SizedBox(height: 6),
                            _FormBody(
                              form: _form,
                              loading: _loading,
                              name: _name,
                              email: _email,
                              phone: _phone,
                              specialty: _specialty,
                              about: _about,
                              password: _password,
                              show: _show,
                              onToggleShow: () =>
                                  setState(() => _show = !_show),
                              onChangedPassword: () => setState(() {}),
                              fName: _fName,
                              fEmail: _fEmail,
                              fPhone: _fPhone,
                              fSpec: _fSpec,
                              fAbout: _fAbout,
                              fPassword: _fPassword,
                              strength: _strength,
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

    try {
      final repo = ref.read(authRepoProvider);
      await repo.registerTeacher(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        specialty: _specialty.text.trim(),
        about: _about.text.trim().isEmpty ? null : _about.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted. Await admin approval.')),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

/* ───────────────────────── Form Body ───────────────────────── */

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.form,
    required this.loading,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.about,
    required this.password,
    required this.show,
    required this.onToggleShow,
    required this.onChangedPassword,
    required this.fName,
    required this.fEmail,
    required this.fPhone,
    required this.fSpec,
    required this.fAbout,
    required this.fPassword,
    required this.strength,
    required this.onSubmit,
  });

  final GlobalKey<FormState> form;
  final bool loading;

  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController specialty;
  final TextEditingController about;
  final TextEditingController password;

  final bool show;
  final VoidCallback onToggleShow;
  final VoidCallback onChangedPassword;

  final FocusNode fName;
  final FocusNode fEmail;
  final FocusNode fPhone;
  final FocusNode fSpec;
  final FocusNode fAbout;
  final FocusNode fPassword;

  final double strength;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;

    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teach on SkillSeed',
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              )),
          const SizedBox(height: 4),
          Text(
            'Tell us what you’ll teach. Admin approval required.',
            style: t.bodyMedium?.copyWith(color: on.withOpacity(.72)),
          ),
          const SizedBox(height: 16),

          // Name
          _Input(
            controller: name,
            label: 'Full Name',
            icon: Icons.badge_outlined,
            validator: Validators.notEmpty,
            textInputAction: TextInputAction.next,
            focusNode: fName,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(fEmail),
            enabled: !loading,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 12),

          // Email
          _Input(
            controller: email,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
            focusNode: fEmail,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(fPhone),
            enabled: !loading,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),

          // Phone
          _Input(
            controller: phone,
            label: 'Phone Number',
            icon: Icons.phone_iphone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.notEmpty,
            textInputAction: TextInputAction.next,
            focusNode: fPhone,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(fSpec),
            enabled: !loading,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: 12),

          // Specialty
          _Input(
            controller: specialty,
            label: 'Specialty / Professional Area',
            icon: Icons.workspace_premium_outlined,
            validator: Validators.notEmpty,
            textInputAction: TextInputAction.next,
            focusNode: fSpec,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(fAbout),
            enabled: !loading,
          ),
          const SizedBox(height: 12),

          // About
          TextFormField(
            controller: about,
            focusNode: fAbout,
            minLines: 2,
            maxLines: 5,
            enabled: !loading,
            decoration: const InputDecoration(
              labelText: 'About (what will you teach?)',
              filled: true,
              isDense: true,
              prefixIcon: Icon(Icons.article_outlined),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: password,
            focusNode: fPassword,
            obscureText: !show,
            enabled: !loading,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(show ? Icons.visibility_off : Icons.visibility),
                onPressed: loading ? null : onToggleShow,
              ),
            ),
            onChanged: (_) => onChangedPassword(),
            validator: (v) => Validators.minLen(v, 6, label: 'Password'),
          ),
          const SizedBox(height: 8),
          _StrengthMeter(value: strength),

          const SizedBox(height: 18),
          GradientButton(
            loading: loading,
            label: loading ? 'Submitting…' : 'Submit for Approval',
            onPressed: loading ? null : onSubmit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : () => context.go('/login'),
            child: const Text('Back to sign in'),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Input ───────────────────────── */

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.enabled = true,
    this.inputFormatters,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final List<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

/* ───────────────────────── Strength Meter ───────────────────────── */

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final good = value >= .66;
    final ok = value >= .34 && value < .66;
    final label = good ? 'Strong' : (ok ? 'Fair' : 'Weak');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Container(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.10),
                ),
                FractionallySizedBox(
                  widthFactor: value.clamp(0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.redAccent.withOpacity(.85),
                          Colors.amber.withOpacity(.90),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(.95),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: $label',
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/* ───────────────────────── Premium Backdrop ───────────────────────── */

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
