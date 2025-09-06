import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/styles.dart'; // for Glass / AnimatedPageGradient if you use it elsewhere
import '../../../data/models/test_models.dart';
import '../../../data/repositories/test_repository.dart';

class TestRunnerScreen extends StatefulWidget {
  final String paperId;
  const TestRunnerScreen({super.key, required this.paperId});

  @override
  State<TestRunnerScreen> createState() => _TestState();
}

class _TestState extends State<TestRunnerScreen> {
  final _repo = TestRepository();

  // data
  List<Question> _qs = [];
  final Map<String, int> _answers = {}; // q.id -> chosen index

  // ui state
  bool _loading = true;
  bool _submitting = false;
  late final PageController _pager = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.questions(widget.paperId);
    if (!mounted) return;
    setState(() {
      _qs = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /* ───────────────────────── UI ───────────────────────── */

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    // Quiet screen-local theme: no blue ink/overlay, crisp typography
    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
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

    final progress = (_qs.isEmpty) ? 0.0 : _answers.length / max(1, _qs.length);

    return Theme(
      data: quiet,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Test'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${_answers.length}/${_qs.length}',
                  style: base.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        base.colorScheme.onSurface.withOpacity(.08),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: AnimatedPageGradient(
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // top meta strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            _MetaChip(
                              icon: Icons.help_outline,
                              label:
                                  'Unanswered: ${_qs.length - _answers.length}',
                            ),
                            const SizedBox(width: 8),
                            _MetaChip(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Questions: ${_qs.length}',
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Review unanswered',
                              onPressed: _reviewUnanswered,
                              icon: const Icon(Icons.list_alt_outlined),
                            ),
                          ],
                        ),
                      ),

                      // questions
                      Expanded(
                        child: PageView.builder(
                          controller: _pager,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (i) => setState(() => _index = i),
                          itemCount: _qs.length,
                          itemBuilder: (_, i) => _QuestionCard(
                            index: i,
                            q: _qs[i],
                            groupValue: _answers[_qs[i].id],
                            onChanged: (v) {
                              HapticFeedback.selectionClick();
                              setState(() => _answers[_qs[i].id] = v);
                            },
                          ),
                        ),
                      ),

                      // bottom nav
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _index == 0
                                    ? null
                                    : () async {
                                        await _pager.previousPage(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Previous'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _index == _qs.length - 1
                                    ? _confirmSubmit
                                    : () async {
                                        await _pager.nextPage(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                icon: Icon(_index == _qs.length - 1
                                    ? Icons.check
                                    : Icons.chevron_right),
                                label: Text(_index == _qs.length - 1
                                    ? 'Submit'
                                    : 'Next'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /* ───────────────────────── interactions ───────────────────────── */

  void _reviewUnanswered() {
    if (_qs.isEmpty) return;
    final missing = <int>[];
    for (var i = 0; i < _qs.length; i++) {
      if (!_answers.containsKey(_qs[i].id)) missing.add(i);
    }
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All questions answered')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Wrap(
          runSpacing: 8,
          spacing: 8,
          children: [
            for (final i in missing)
              ActionChip(
                label: Text('Q${i + 1}'),
                avatar: const Icon(Icons.error_outline, size: 16),
                onPressed: () {
                  Navigator.pop(context);
                  _pager.jumpToPage(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmit() async {
    final unanswered = _qs.length - _answers.length;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit answers?'),
        content: Text(
          unanswered == 0
              ? 'Ready to submit your answers.'
              : 'You have $unanswered unanswered question(s). Submit anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    int score = 0;
    for (final q in _qs) {
      if (_answers[q.id] == q.correctIndex) score++;
    }

    await _repo.recordAttempt(
      paperId: widget.paperId,
      userId: 'local-user', // TODO: wire real user id
      score: score,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final shareText = 'I scored $score/${_qs.length} in SkillSeed!';
    await showDialog(
      context: context,
      builder: (_) => _ResultDialog(
        score: score,
        total: _qs.length,
        qs: _qs,
        answers: _answers,
        onShare: () async {
          await Share.share(shareText);
        },
      ),
    );
  }
}

/* ───────────────────────── widgets ───────────────────────── */

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fg.withOpacity(.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.q,
    required this.groupValue,
    required this.onChanged,
  });

  final int index;
  final Question q;
  final int? groupValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Glass(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // heading
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: on.withOpacity(.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Q${index + 1}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),

            // options
            const SizedBox(height: 6),
            for (int i = 0; i < q.options.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: groupValue,
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(v);
                },
                dense: true,
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -2),
                title: Text(q.options[i]),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.score,
    required this.total,
    required this.qs,
    required this.answers,
    required this.onShare,
  });

  final int score;
  final int total;
  final List<Question> qs;
  final Map<String, int> answers;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total == 0 ? 0.0 : score / total;

    return AlertDialog(
      title: const Text('Result'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // headline score
            Row(
              children: [
                Expanded(
                  child: Text(
                    'You scored $score/$total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(.08),
              ),
            ),
            const SizedBox(height: 12),
            // quick review list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: qs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final q = qs[i];
                  final your = answers[q.id];
                  final correct = q.correctIndex;
                  final ok = your == correct;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      ok ? Icons.check_circle : Icons.cancel,
                      color: ok ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      'Q${i + 1}. ${q.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Your: ${your == null ? '—' : q.options[your]}'
                      '   •   Correct: ${q.options[correct]}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
      ],
    );
  }
}
