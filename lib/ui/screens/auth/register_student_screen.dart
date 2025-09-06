import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_providers.dart';
import '../../../core/validators.dart';
import '../../../core/styles.dart';
import '../widgets/role_hero.dart';

class RegisterStudentScreen extends ConsumerStatefulWidget {
  const RegisterStudentScreen({super.key});
  @override
  ConsumerState<RegisterStudentScreen> createState() => _RegState();
}

class _RegState extends ConsumerState<RegisterStudentScreen> {
  final _form = GlobalKey<FormState>();

  // Inputs
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  final _college = TextEditingController();
  final _standard = TextEditingController();
  final _password = TextEditingController();

  // Focus
  final _fName = FocusNode();
  final _fEmail = FocusNode();
  final _fPhone = FocusNode();
  final _fAge = FocusNode();
  final _fCollege = FocusNode();
  final _fStandard = FocusNode();
  final _fPassword = FocusNode();

  bool _loading = false;
  bool _show = false;
  bool _agree = false;

  double get _strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    double v = 0;
    if (p.length >= 8) v += .34;
    if (RegExp(r'[A-Z]').hasMatch(p)) v += .18;
    if (RegExp(r'[0-9]').hasMatch(p)) v += .18;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) v += .18;
    if (RegExp(r'[a-z]').hasMatch(p)) v += .12;
    return v.clamp(0, 1);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _age.dispose();
    _college.dispose();
    _standard.dispose();
    _password.dispose();
    _fName.dispose();
    _fEmail.dispose();
    _fPhone.dispose();
    _fAge.dispose();
    _fCollege.dispose();
    _fStandard.dispose();
    _fPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Overlay-free, premium input theme
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
        helperStyle: base.textTheme.bodySmall?.copyWith(
          color: base.colorScheme.onSurface.withOpacity(.60),
        ),
        errorMaxLines: 3,
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
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
          ),
          title: const Text('Register • Student'),
        ),

        // Premium grenade/aurora backdrop
        body: _AuroraBackdrop(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 1000;

                if (wide) {
                  // ── Side-by-side: hero + scrollable form card
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero panel (fixed height)
                            Expanded(
                              flex: 6,
                              child: _HeroPanel(),
                            ),
                            const SizedBox(width: 16),

                            // Form panel — always scrollable, keyboard-safe
                            Expanded(
                              flex: 5,
                              child: _FormCardScroll(
                                child: _FormBody(
                                  form: _form,
                                  loading: _loading,
                                  name: _name,
                                  email: _email,
                                  phone: _phone,
                                  age: _age,
                                  college: _college,
                                  standard: _standard,
                                  password: _password,
                                  show: _show,
                                  agree: _agree,
                                  onToggleAgree: () =>
                                      setState(() => _agree = !_agree),
                                  onToggleShow: () =>
                                      setState(() => _show = !_show),
                                  onChangedPassword: () => setState(() {}),
                                  fName: _fName,
                                  fEmail: _fEmail,
                                  fPhone: _fPhone,
                                  fAge: _fAge,
                                  fCollege: _fCollege,
                                  fStandard: _fStandard,
                                  fPassword: _fPassword,
                                  strength: _strength,
                                  onSubmit: _submit,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ── Mobile / compact: stacked; card is still scrollable
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: _FormCardScroll(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _HeroInline(),
                            const SizedBox(height: 10),
                            _FormBody(
                              form: _form,
                              loading: _loading,
                              name: _name,
                              email: _email,
                              phone: _phone,
                              age: _age,
                              college: _college,
                              standard: _standard,
                              password: _password,
                              show: _show,
                              agree: _agree,
                              onToggleAgree: () =>
                                  setState(() => _agree = !_agree),
                              onToggleShow: () =>
                                  setState(() => _show = !_show),
                              onChangedPassword: () => setState(() {}),
                              fName: _fName,
                              fEmail: _fEmail,
                              fPhone: _fPhone,
                              fAge: _fAge,
                              fCollege: _fCollege,
                              fStandard: _fStandard,
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
    final current = _form.currentState;
    if (current == null) return;

    if (!current.validate()) {
      HapticFeedback.selectionClick();
      return;
    }
    if (!_agree) {
      HapticFeedback.selectionClick();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms to continue.')),
      );
      return;
    }

    final repo = ref.read(authRepoProvider);
    final parsed = int.tryParse(_age.text.trim());
    final safeAge =
        (parsed == null || parsed < 5 || parsed > 120) ? 18 : parsed;

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();

    try {
      await repo.registerStudent(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        age: safeAge,
        college: _college.text.trim(),
        standard: _standard.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created')),
      );
      context.go('/student');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create account: $e')),
      );
    }
  }
}

/* ───────────────────────── Structure ───────────────────────── */

/// A glass card that **always** scrolls and respects keyboard insets.
/// Solves “BOTTOM OVERFLOWED BY … PIXELS” in tight viewports.
class _FormCardScroll extends StatelessWidget {
  const _FormCardScroll({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets.bottom; // keyboard
    final topPad = 18.0;
    final sidePad = 18.0;
    final bottomPad = 16.0;

    return Glass(
      // Outer padding for the card chrome
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (ctx, c) {
          // Keep some headroom so shadows/rounded corners look nice
          final maxHeight = media.size.height -
              media.padding.top -
              media.padding.bottom -
              24; // safe margin
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  sidePad,
                  topPad,
                  sidePad,
                  bottomPad + viewInsets, // keyboard-safe
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Neutral-veil hero prevents tint “color mixing”
          const RoleHeroImage(
            role: RoleKind.student,
            gender: GenderKind.neutral,
            asBackground: true,
            veilOpacity: 0.28,
            veilColor: Colors.black, // <— neutral scrim
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Semantics(
              header: true,
              child: Text(
                'Build soft-skills with confidence',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInline extends StatelessWidget {
  const _HeroInline();
  @override
  Widget build(BuildContext context) {
    return const RoleHeroImage(
      role: RoleKind.student,
      gender: GenderKind.neutral,
      height: 120,
    );
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
    required this.age,
    required this.college,
    required this.standard,
    required this.password,
    required this.show,
    required this.agree,
    required this.onToggleAgree,
    required this.onToggleShow,
    required this.onChangedPassword,
    required this.fName,
    required this.fEmail,
    required this.fPhone,
    required this.fAge,
    required this.fCollege,
    required this.fStandard,
    required this.fPassword,
    required this.strength,
    required this.onSubmit,
  });

  final GlobalKey<FormState> form;
  final bool loading;

  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController age;
  final TextEditingController college;
  final TextEditingController standard;
  final TextEditingController password;

  final bool show;
  final bool agree;
  final VoidCallback onToggleAgree;
  final VoidCallback onToggleShow;
  final VoidCallback onChangedPassword;

  final FocusNode fName;
  final FocusNode fEmail;
  final FocusNode fPhone;
  final FocusNode fAge;
  final FocusNode fCollege;
  final FocusNode fStandard;
  final FocusNode fPassword;

  final double strength;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;

    return AutofillGroup(
      child: Form(
        key: form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Let’s get you started',
                style: t.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                )),
            const SizedBox(height: 4),
            Text('Create your learner profile.',
                style: t.bodyMedium?.copyWith(color: on.withOpacity(.72))),
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
              helperText:
                  'Use your real name as it appears on college records.',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z .'-]")),
                LengthLimitingTextInputFormatter(60),
              ],
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
              helperText: 'We’ll send verification here.',
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
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(fAge),
              enabled: !loading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              autofillHints: const [AutofillHints.telephoneNumber],
              helperText: 'Digits only; include country code if needed.',
            ),
            const SizedBox(height: 12),

            // Age
            _Input(
              controller: age,
              label: 'Age',
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Required';
                final n = int.tryParse(v!.trim());
                if (n == null) return 'Enter a number';
                if (n < 5 || n > 120) return 'Enter a valid age';
                return null;
              },
              textInputAction: TextInputAction.next,
              focusNode: fAge,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(fCollege),
              enabled: !loading,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
            const SizedBox(height: 12),

            // College
            _Input(
              controller: college,
              label: 'College',
              icon: Icons.school_outlined,
              validator: Validators.notEmpty,
              textInputAction: TextInputAction.next,
              focusNode: fCollege,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(fStandard),
              enabled: !loading,
              autofillHints: const [AutofillHints.organizationName],
            ),
            const SizedBox(height: 12),

            // Standard
            _Input(
              controller: standard,
              label: 'Standard (e.g., B.Tech 3rd Year)',
              icon: Icons.workspace_premium_outlined,
              validator: Validators.notEmpty,
              textInputAction: TextInputAction.next,
              focusNode: fStandard,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(fPassword),
              enabled: !loading,
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
                helperText:
                    'Use at least 8 characters, mixing letters, numbers & symbols.',
                suffixIcon: IconButton(
                  tooltip: show ? 'Hide password' : 'Show password',
                  icon: Icon(show ? Icons.visibility_off : Icons.visibility),
                  onPressed: loading ? null : onToggleShow,
                ),
              ),
              onChanged: (_) => onChangedPassword(),
              validator: (v) => Validators.minLen(v, 8, label: 'Password'),
            ),
            const SizedBox(height: 8),
            _StrengthMeter(value: strength),
            const SizedBox(height: 12),

            // Terms / consent
            Row(
              children: [
                Checkbox(
                  value: agree,
                  onChanged: loading ? null : (_) => onToggleAgree(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'I agree to the Terms and Privacy Policy.',
                    style: t.bodySmall?.copyWith(color: on.withOpacity(.85)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            GradientButton(
              loading: loading,
              label: loading ? 'Creating…' : 'Create Account',
              onPressed: loading ? null : onSubmit,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed:
                    loading ? null : () => GoRouter.of(context).go('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ───────────────────────── Input Widget ───────────────────────── */

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
    this.helperText,
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
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      textField: true,
      child: TextFormField(
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
          helperText: helperText,
          prefixIcon: Icon(icon),
        ),
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

/* ───────────────────────── Premium Backdrop (grenade gradient) ───────────────────────── */

class _AuroraBackdrop extends StatefulWidget {
  const _AuroraBackdrop({required this.child});
  final Widget child;

  @override
  State<_AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<_AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 20))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Base night tones + vivid accents
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
        final angle = 0.35 + _c.value * 0.9;

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
              angle: angle,
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
