import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../shared/template_placeholders.dart';
import '../../shared/theme/app_theme.dart';

Future<String?> showTemplateFillSheet({
  required BuildContext context,
  required String templateBody,
  required String language,
  String? clientName,
  String? notes,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => TemplateFillSheet(
      templateBody: templateBody,
      language: language,
      clientName: clientName,
      notes: notes,
    ),
  );
}

class TemplateFillSheet extends ConsumerStatefulWidget {
  const TemplateFillSheet({
    super.key,
    required this.templateBody,
    required this.language,
    this.clientName,
    this.notes,
  });

  final String templateBody;
  final String language;
  final String? clientName;
  final String? notes;

  @override
  ConsumerState<TemplateFillSheet> createState() => _TemplateFillSheetState();
}

class _TemplateFillSheetState extends ConsumerState<TemplateFillSheet> {
  late final List<String> _keys;
  late final Map<String, TextEditingController> _controllers;
  final _jobController = TextEditingController();
  bool _busy = false;
  String? _busyKey;
  String? _error;

  @override
  void initState() {
    super.initState();
    _keys = extractPlaceholders(widget.templateBody);
    _controllers = {
      for (final key in _keys) key: TextEditingController(),
    };
    final client = widget.clientName?.trim() ?? '';
    if (client.isNotEmpty) {
      for (final key in _keys) {
        if (isClientNamePlaceholder(key)) {
          _controllers[key]!.text = client;
        }
      }
    }
  }

  @override
  void dispose() {
    _jobController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _values => {
        for (final key in _keys) key: _controllers[key]!.text.trim(),
      };

  List<String> get _emptyKeys => _keys
      .where((key) => _controllers[key]!.text.trim().isEmpty)
      .where((key) => !isOptionalNamePlaceholder(key))
      .toList();

  Map<String, String> get _filled => {
        for (final entry in _values.entries)
          if (entry.value.isNotEmpty) entry.key: entry.value,
      };

  Future<void> _fillWithAi(List<String> emptyKeys) async {
    if (emptyKeys.isEmpty) return;
    final job = _jobController.text.trim();
    if (job.isEmpty) {
      setState(() => _error = 'Paste a job description to fill with AI.');
      return;
    }

    setState(() {
      _busy = true;
      _busyKey = emptyKeys.length == 1 ? emptyKeys.first : null;
      _error = null;
    });

    try {
      final filledForRequest = {
        for (final entry in _filled.entries)
          if (!emptyKeys.contains(entry.key)) entry.key: entry.value,
      };
      final values = await ref.read(aiApiProvider).fillTemplateFields(
            jobDescription: job,
            language: widget.language,
            templateBody: widget.templateBody,
            filled: filledForRequest,
            emptyKeys: emptyKeys,
            clientName: widget.clientName,
            notes: widget.notes,
          );
      if (!mounted) return;
      values.forEach((key, value) {
        final controller = _controllers[key];
        if (controller != null && value.trim().isNotEmpty) {
          controller.text = value.trim();
        }
      });
      setState(() {
        _busy = false;
        _busyKey = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _busyKey = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _apply() async {
    var assembled = stripOptionalNamePlaceholders(
      applyPlaceholders(widget.templateBody, _values),
    );
    if (widget.language == 'arabic') {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        final rewritten = await ref.read(aiApiProvider).rewriteProposalLanguage(
              body: assembled,
              language: widget.language,
            );
        if (rewritten.trim().isNotEmpty) {
          assembled = rewritten.trim();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
        return;
      }
    }
    if (!mounted) return;
    Navigator.pop(context, assembled);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    final emptyCount = _emptyKeys.length;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fill template fields',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.rose),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                TextFormField(
                  controller: _jobController,
                  minLines: 3,
                  maxLines: 6,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Job description (for AI)',
                    alignLabelWithHint: true,
                    hintText: 'Paste the Upwork job posting to fill empty fields…',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy || emptyCount == 0
                      ? null
                      : () => _fillWithAi(_emptyKeys),
                  icon: _busy && _busyKey == null
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    emptyCount == 0
                        ? 'All fields filled'
                        : 'Fill empty with AI ($emptyCount)',
                  ),
                ),
                const SizedBox(height: 16),
                for (final key in _keys) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _controllers[key],
                          minLines: 1,
                          maxLines: 4,
                          enabled: !_busy,
                          decoration: InputDecoration(
                            labelText: placeholderLabel(key),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fill this field with AI',
                        onPressed: _busy ? null : () => _fillWithAi([key]),
                        icon: _busyKey == key
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: _busy ? null : _apply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
