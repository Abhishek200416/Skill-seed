import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/styles.dart'; // AnimatedPageGradient + Glass

class LiveJoinScreen extends StatelessWidget {
  final String sessionId;
  final String? url;

  const LiveJoinScreen({
    super.key,
    required this.sessionId,
    this.url,
  });

  // ---------- navigation ----------
  Future<bool> _handleSystemBack(BuildContext context) async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/student');
    }
    return false;
  }

  // ---------- derived states ----------
  bool get _hasUrl => (url != null) && url!.trim().isNotEmpty;
  bool get _validUrl {
    if (!_hasUrl) return false;
    final u = Uri.tryParse(url!.trim());
    return u != null && (u.isScheme('http') || u.isScheme('https'));
  }

  String get _hostLabel {
    if (!_validUrl) return '—';
    final u = Uri.parse(url!.trim());
    return u.host.replaceFirst('www.', '');
  }

  // ---------- actions ----------
  Future<void> _openLink(BuildContext context) async {
    if (!_validUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid link to open')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final u = Uri.parse(url!.trim());
    final ok = await canLaunchUrl(u);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch link')),
      );
      return;
    }
    await launchUrl(u, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink(BuildContext context) async {
    if (!_hasUrl) return;
    HapticFeedback.selectionClick();
    await Clipboard.setData(ClipboardData(text: url!.trim()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Local "quiet" theme: remove pressed glows / keep crisp surfaces
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
              color: base.colorScheme.primary.withOpacity(.45), width: 1.2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );

    final statusColor = _validUrl
        ? Colors.greenAccent
        : (_hasUrl
            ? Colors.amber
            : base.colorScheme.onSurface.withOpacity(.50));
    final statusText =
        _validUrl ? 'Ready' : (_hasUrl ? 'Invalid link' : 'Pending');

    return Theme(
      data: quiet,
      child: WillPopScope(
        onWillPop: () => _handleSystemBack(context),
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
                      onPressed: () => _handleSystemBack(context),
                    ),
                    title: const Text('Join Live Class'),
                    actions: [
                      IconButton(
                        tooltip: 'Copy link',
                        onPressed: _hasUrl ? () => _copyLink(context) : null,
                        icon: const Icon(Icons.copy_all_outlined),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),

                  // Main card
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Glass(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // header
                                Row(
                                  children: [
                                    const Icon(Icons.live_tv_outlined,
                                        size: 28),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Live session link',
                                      style:
                                          base.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                    const Spacer(),
                                    _Badge(
                                        label: statusText, color: statusColor),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(
                                    color: base.colorScheme.onSurface
                                        .withOpacity(.08),
                                    height: 1),
                                const SizedBox(height: 12),

                                // session meta
                                _MetaRow(label: 'Session ID', value: sessionId),
                                const SizedBox(height: 6),
                                _MetaRow(label: 'Host', value: _hostLabel),

                                const SizedBox(height: 16),

                                // buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FilledButton.icon(
                                      onPressed: _validUrl
                                          ? () => _openLink(context)
                                          : null,
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _hasUrl
                                          ? () => _copyLink(context)
                                          : null,
                                      icon: const Icon(Icons.link),
                                      label: const Text('Copy'),
                                    ),
                                  ],
                                ),

                                // state hint
                                const SizedBox(height: 12),
                                if (!_hasUrl)
                                  Text(
                                    'Link pending. Your teacher usually enables the Zoom link ~5 minutes before start.',
                                    textAlign: TextAlign.center,
                                    style: base.textTheme.bodySmall?.copyWith(
                                      color: base.colorScheme.onSurface
                                          .withOpacity(.75),
                                    ),
                                  )
                                else if (!_validUrl)
                                  Text(
                                    'The provided link is not a valid URL.',
                                    textAlign: TextAlign.center,
                                    style: base.textTheme.bodySmall?.copyWith(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

/* ───────────────────── small UI bits ───────────────────── */

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final on = Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: t.bodySmall?.copyWith(
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
            style: t.bodyMedium?.copyWith(letterSpacing: .1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
