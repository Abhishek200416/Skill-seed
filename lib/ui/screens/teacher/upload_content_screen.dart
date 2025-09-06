// lib/ui/screens/teacher/upload_content_screen.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

// Optional, used for Logout menu. If you don't use Firebase, remove these 2 lines.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb show FirebaseAuth;

import '../../../core/styles.dart'; // Glass, GradientButton, AnimatedPageGradient
import '../../../data/models/content_item.dart';
import '../../../data/repositories/class_repository.dart';

class UploadContentScreen extends StatefulWidget {
  const UploadContentScreen({super.key});
  @override
  State<UploadContentScreen> createState() => _UploadState();
}

class _UploadState extends State<UploadContentScreen> {
  final _form = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController(); // optional: direct link

  String _category = 'COMMUNICATION';
  String _type = 'note'; // note | pdf | video | image | link
  String? _pathOrData; // file path (mobile/desktop) OR data URI (web)
  String? _pickedName;
  int? _pickedBytes;
  bool _saving = false;

  // Advanced (UI-only) options — safe no-ops for backends that don’t store them.
  String _audience = 'all'; // all | my | link
  bool _featured = false;
  bool _allowDownload = true;

  // unsaved-change guard
  bool get _dirty =>
      _title.text.trim().isNotEmpty ||
      _desc.text.trim().isNotEmpty ||
      _url.text.trim().isNotEmpty ||
      _pickedName != null;

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {})); // refresh preview/validate
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _url.dispose();
    super.dispose();
  }

  /* ───────── helpers ───────── */

  String _inferTypeFromFilename(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'pdf';
    if (n.endsWith('.mp4') || n.endsWith('.mov') || n.endsWith('.m4v')) {
      return 'video';
    }
    if (n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp')) {
      return 'image';
    }
    if (n.endsWith('.txt') ||
        n.endsWith('.md') ||
        n.endsWith('.doc') ||
        n.endsWith('.docx')) {
      return 'note';
    }
    return 'note';
  }

  String _inferTypeFromUrl(String link) {
    final u = link.toLowerCase();
    if (u.contains('youtube.com/') ||
        u.contains('youtu.be/') ||
        u.contains('vimeo.com')) {
      return 'video';
    }
    if (u.endsWith('.pdf')) return 'pdf';
    if (u.endsWith('.png') ||
        u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.gif') ||
        u.endsWith('.webp')) {
      return 'image';
    }
    return 'link';
  }

  String? _validateIfUrl(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    try {
      final uri = Uri.parse(s);
      final ok = (uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty);
      return ok ? null : 'Enter a valid URL';
    } catch (_) {
      return 'Enter a valid URL';
    }
  }

  String _prettySize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _pickFile() async {
    HapticFeedback.selectionClick();
    final res = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: kIsWeb, // web needs bytes
      allowMultiple: false,
    );
    if (!mounted || res == null || res.files.isEmpty) return;

    final file = res.files.single;
    _pickedName = file.name;
    _type = _inferTypeFromFilename(file.name);
    _pickedBytes = file.bytes?.lengthInBytes;

    if (kIsWeb) {
      final Uint8List? data = file.bytes;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file bytes')),
        );
        return;
      }
      // Minimal mime guess
      final mime = switch (_type) {
        'pdf' => 'application/pdf',
        'image' => 'image/*',
        'video' => 'video/*',
        'note' => 'text/plain',
        _ => 'application/octet-stream',
      };
      final b64 = base64Encode(data);
      _pathOrData = 'data:$mime;base64,$b64';
    } else {
      _pathOrData = file.path;
    }
    setState(() {});
  }

  void _autoDetectType() {
    final link = _url.text.trim();
    if (link.isNotEmpty && _validateIfUrl(link) == null) {
      setState(() => _type = _inferTypeFromUrl(link));
      return;
    }
    if (_pickedName != null) {
      setState(() => _type = _inferTypeFromFilename(_pickedName!));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add a link or pick a file to detect type')),
    );
  }

  Future<void> _pasteLink() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text == null || clip!.text!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }
    _url.text = clip.text!.trim();
    _autoDetectType();
  }

  Future<void> _previewLink() async {
    final link = _url.text.trim();
    if (_validateIfUrl(link) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a valid link to preview')),
      );
      return;
    }
    // Let the router/webview on your side handle this route:
    // Example: context.push('/webview?url=...');
    // For now, just copy to clipboard and inform:
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied — open in browser.')),
    );
  }

  Future<void> _save() async {
    // If a URL is provided, it takes priority and becomes a "link" or inferred type.
    final hasUrl = _url.text.trim().isNotEmpty;
    if (!hasUrl && (_pathOrData == null || _pickedName == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a file or paste a link')),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final id = const Uuid().v4();

      // Determine final type & value:
      final finalType = hasUrl ? _inferTypeFromUrl(_url.text.trim()) : _type;
      final finalValue = hasUrl ? _url.text.trim() : _pathOrData!;

      // Optional UX-only flags can be encoded into description suffix
      // if you want to keep them for later without changing your model.
      final metaSuffix =
          '\n\n— visibility:${_audience}; featured:${_featured ? 'yes' : 'no'}; downloads:${_allowDownload ? 'allowed' : 'blocked'}';
      final desc = _desc.text.trim().isEmpty ? '' : _desc.text.trim();

      final item = ContentItem(
        id: id,
        category: _category,
        title: _title.text.trim(),
        description: '$desc$metaSuffix',
        type: finalType,
        urlOrPath: finalValue,
      );

      await ClassRepository().addContent(item);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content saved')),
      );

      _resetForm();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _title.clear();
      _desc.clear();
      _url.clear();
      _pickedName = null;
      _pathOrData = null;
      _pickedBytes = null;
      _type = 'note';
      _category = 'COMMUNICATION';
      _audience = 'all';
      _featured = false;
      _allowDownload = true;
    });
  }

  Future<bool> _confirmPop() async {
    if (!_dirty || _saving) return true;
    HapticFeedback.selectionClick();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits on this form.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return ok ?? false;
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    final quiet = base.copyWith(
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        isDense: true,
        filled: true,
        fillColor: base.colorScheme.surface.withOpacity(.78),
        labelStyle: base.textTheme.bodySmall?.copyWith(
          letterSpacing: .2,
          color: base.colorScheme.onSurface.withOpacity(.82),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

    final canSave = _title.text.trim().isNotEmpty &&
        ((_url.text.trim().isNotEmpty && _validateIfUrl(_url.text) == null) ||
            (_pickedName != null && _pathOrData != null));

    return Theme(
      data: quiet,
      child: WillPopScope(
        onWillPop: _confirmPop,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (!await _confirmPop()) return;
                final r = GoRouter.of(context);
                if (r.canPop()) {
                  context.pop();
                } else {
                  context.go('/teacher');
                }
              },
            ),
            title: const Text('Upload Content'),
            actions: [
              IconButton(
                tooltip: 'Reset',
                onPressed: _saving ? null : _resetForm,
                icon: const Icon(Icons.restore),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) async {
                  switch (v) {
                    case 'paste':
                      await _pasteLink();
                      break;
                    case 'preview':
                      await _previewLink();
                      break;
                    case 'logout':
                      try {
                        await fb.FirebaseAuth.instance.signOut();
                      } finally {
                        if (mounted) context.go('/login');
                      }
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'paste',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.paste),
                      title: Text('Paste link from clipboard'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'preview',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.open_in_new),
                      title: Text('Preview link'),
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
          ),
          body: AnimatedPageGradient(
            // same premium animated gradient as other screens
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Glass(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Form(
                      key: _form,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                          _categoryTypeRow(), // responsive, no overflow
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'e.g., Active Listening Basics',
                              prefixIcon: Icon(Icons.title_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().length < 2)
                                ? 'Enter a title'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _desc,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Short summary that helps learners',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Paste a link OR pick a file
                          TextFormField(
                            controller: _url,
                            decoration: const InputDecoration(
                              labelText: 'Web link (optional)',
                              hintText: 'https://… (YouTube, Drive, article)',
                              prefixIcon: Icon(Icons.link_outlined),
                            ),
                            keyboardType: TextInputType.url,
                            validator: _validateIfUrl,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _saving ? null : _pickFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(_pickedName ?? 'Pick a file'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _saving ? null : _autoDetectType,
                                icon: const Icon(Icons.auto_fix_high_outlined),
                                label: const Text('Auto-detect'),
                              ),
                            ],
                          ),

                          if (_pickedName != null ||
                              _url.text.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _PreviewCard(
                                name: _pickedName,
                                bytes: _pickedBytes,
                                type: _url.text.trim().isNotEmpty
                                    ? _inferTypeFromUrl(_url.text.trim())
                                    : _type,
                                url: _url.text.trim().isEmpty
                                    ? null
                                    : _url.text.trim(),
                                onClear: _saving
                                    ? null
                                    : () => setState(() {
                                          _pickedName = null;
                                          _pickedBytes = null;
                                          _pathOrData = null;
                                          _url.clear();
                                        }),
                              ),
                            ),

                          const SizedBox(height: 14),
                          _advancedOptions(),
                          const SizedBox(height: 18),

                          GradientButton(
                            loading: _saving,
                            label: _saving
                                ? 'Saving…'
                                : (canSave
                                    ? 'Save'
                                    : 'Save (add title + content)'),
                            onPressed: _saving || !canSave ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* ───────── UI bits ───────── */

  // Fixed the overflow by making Category/Type responsive (Row -> Column on narrow),
  // and by setting isExpanded: true on both dropdowns.
  Widget _categoryTypeRow() {
    final categoryField = DropdownButtonFormField<String>(
      value: _category,
      isExpanded: true,
      menuMaxHeight: 380,
      items: const [
        DropdownMenuItem(value: 'COMMUNICATION', child: Text('Communication')),
        DropdownMenuItem(value: 'TEAMWORK', child: Text('Teamwork')),
        DropdownMenuItem(value: 'CREATIVITY', child: Text('Creativity')),
        DropdownMenuItem(
            value: 'TIME MANAGEMENT', child: Text('Time Management')),
        DropdownMenuItem(value: 'LEADERSHIP', child: Text('Leadership')),
        DropdownMenuItem(
            value: 'PROBLEM SOLVING', child: Text('Problem Solving')),
        DropdownMenuItem(
            value: 'SELF-REFLECTION', child: Text('Self-Reflection')),
      ],
      onChanged: (v) => setState(() => _category = v ?? _category),
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
    );

    final typeField = DropdownButtonFormField<String>(
      value: _type,
      isExpanded: true,
      menuMaxHeight: 380,
      items: const [
        DropdownMenuItem(value: 'note', child: Text('Note / Doc')),
        DropdownMenuItem(value: 'pdf', child: Text('PDF')),
        DropdownMenuItem(value: 'image', child: Text('Image')),
        DropdownMenuItem(value: 'video', child: Text('Video')),
        DropdownMenuItem(value: 'link', child: Text('Link only')),
      ],
      onChanged: (v) => setState(() => _type = v ?? _type),
      decoration: const InputDecoration(
        labelText: 'Type',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
    );

    return LayoutBuilder(
      builder: (_, c) {
        final narrow = c.maxWidth < 420;
        if (narrow) {
          return Column(
            children: [
              categoryField,
              const SizedBox(height: 10),
              typeField,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: categoryField),
            const SizedBox(width: 10),
            Expanded(child: typeField),
          ],
        );
      },
    );
  }

  Widget _advancedOptions() {
    final base = Theme.of(context);
    return Glass(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Advanced (optional)',
              style: base.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _audience,
                    items: const [
                      DropdownMenuItem(
                          value: 'all', child: Text('Audience: All students')),
                      DropdownMenuItem(
                          value: 'my',
                          child: Text('Audience: Only my students')),
                      DropdownMenuItem(
                          value: 'link', child: Text('Audience: Link access')),
                    ],
                    onChanged: (v) => setState(() => _audience = v ?? 'all'),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Featured'),
                  selected: _featured,
                  onSelected: (v) => setState(() => _featured = v),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(_allowDownload
                      ? 'Downloads allowed'
                      : 'Downloads blocked'),
                  selected: !_allowDownload,
                  onSelected: (v) => setState(() => _allowDownload = !v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/* ───────── Preview card ───────── */

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.name,
    required this.bytes,
    required this.type,
    required this.onClear,
    this.url,
  });

  final String? name;
  final int? bytes;
  final String type;
  final String? url;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'video' => Icons.play_circle_outline,
      'image' => Icons.image_outlined,
      'link' => Icons.link_outlined,
      _ => Icons.description_outlined,
    };
    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  url ?? (name ?? '—'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    type.toUpperCase(),
                    if (bytes != null) _pretty(bytes!),
                    if (url != null) 'URL',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Clear',
            onPressed: onClear,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  String _pretty(int b) {
    const kb = 1024, mb = kb * 1024;
    if (b >= mb) return '${(b / mb).toStringAsFixed(2)} MB';
    if (b >= kb) return '${(b / kb).toStringAsFixed(1)} KB';
    return '$b B';
  }
}
