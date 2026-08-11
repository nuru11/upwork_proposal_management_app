import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/models/ai_draft.dart';
import '../../data/models/proposal.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class AiDraftDetailScreen extends ConsumerStatefulWidget {
  const AiDraftDetailScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<AiDraftDetailScreen> createState() =>
      _AiDraftDetailScreenState();
}

class _AiDraftDetailScreenState extends ConsumerState<AiDraftDetailScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _hydrate(AiDraft draft) {
    if (_hydrated) return;
    _titleController.text = draft.title;
    _bodyController.text = draft.body;
    _hydrated = true;
  }

  Future<void> _save(AiDraft existing) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(aiDraftsProvider.notifier).save(
            existing.copyWith(
              title: title,
              body: body,
              updatedAt: DateTime.now(),
            ),
            isNew: false,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AiDraft draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI draft?'),
        content: Text('“${draft.title}” will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(aiDraftsProvider.notifier).delete(draft.id);
    if (!mounted) return;
    context.go('/ai-drafts');
  }

  void _createProposal(AiDraft draft) {
    context.push(
      '/proposals/new',
      extra: ProposalPrefill(
        title: _titleController.text.trim().isEmpty
            ? draft.title
            : _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty
            ? draft.body
            : _bodyController.text.trim(),
        clientName: draft.clientName,
        language: draft.language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDraft = ref.watch(aiDraftByIdProvider(widget.draftId));

    return asyncDraft.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (draft) {
        if (draft == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('AI draft')),
            body: const Center(child: Text('Draft not found')),
          );
        }
        _hydrate(draft);
        final isRtl = draft.language == ProposalLanguage.arabic.name;
        final dateFormat = DateFormat.yMMMd().add_jm();

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI draft'),
            actions: [
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _delete(draft),
                icon: const Icon(Icons.delete_outline),
              ),
              TextButton(
                onPressed: _saving ? null : () => _save(draft),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                '${draft.domainLabel} · ${dateFormat.format(draft.updatedAt.toLocal())}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.slate500,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                minLines: 12,
                maxLines: 24,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'Proposal body',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _createProposal(draft),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Create proposal'),
              ),
            ],
          ),
        );
      },
    );
  }
}
