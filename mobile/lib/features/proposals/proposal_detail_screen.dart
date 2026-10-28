import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/proposal.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/status_chip.dart';

class ProposalDetailScreen extends ConsumerWidget {
  const ProposalDetailScreen({super.key, required this.proposalId});

  final String proposalId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete proposal?'),
        content: const Text(
          'This permanently removes the proposal from this device.',
        ),
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

    if (confirmed != true || !context.mounted) return;
    await ref.read(proposalsProvider.notifier).delete(proposalId);
    if (!context.mounted) return;
    context.go('/proposals');
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProposal = ref.watch(proposalByIdProvider(proposalId));

    return asyncProposal.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (proposal) {
        if (proposal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proposal')),
            body: const Center(child: Text('Proposal not found')),
          );
        }

        final isRtl = proposal.language == ProposalLanguage.arabic;
        final dateFormat = DateFormat.yMMMd().add_jm();
        final templateAsync = proposal.templateId == null
            ? null
            : ref.watch(templateByIdProvider(proposal.templateId!));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Proposal'),
            actions: [
              IconButton(
                tooltip: 'Copy text',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: proposal.body));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Proposal text copied')),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () =>
                    context.push('/proposals/${proposal.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                proposal.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...proposal.status.map(
                    (status) => StatusChip(status: status),
                  ),
                  LanguageChip(language: proposal.language),
                  ProjectTypeChip(projectType: proposal.projectType),
                ],
              ),
              if (proposal.clientName != null &&
                  proposal.clientName!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  proposal.clientName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.slate700,
                      ),
                ),
              ],
              if (proposal.jobUrl != null && proposal.jobUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openUrl(context, proposal.jobUrl!),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open job link'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Update status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProposalStatus.values.map((status) {
                  final selected = proposal.status.contains(status);
                  return FilterChip(
                    label: Text(status.label),
                    selected: selected,
                    selectedColor: AppTheme.statusSoftColor(status),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.statusColor(status)
                          : AppColors.slate700,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => ref
                        .read(proposalsProvider.notifier)
                        .updateStatus(proposal, status),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Proposal text',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Directionality(
                  textDirection:
                      isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: SelectableText(
                    proposal.body,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          height: 1.55,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _ReviewFields(proposal: proposal),
              const SizedBox(height: 24),
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _MetaRow(
                label: 'Updated',
                value: dateFormat.format(proposal.updatedAt),
              ),
              _MetaRow(
                label: 'Created',
                value: dateFormat.format(proposal.createdAt),
              ),
              if (proposal.submittedAt != null)
                _MetaRow(
                  label: 'Submitted',
                  value: dateFormat.format(proposal.submittedAt!),
                ),
              if (templateAsync != null)
                templateAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (template) => template == null
                      ? const SizedBox.shrink()
                      : _MetaRow(
                          label: 'Template',
                          value: template.name,
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewFields extends ConsumerStatefulWidget {
  const _ReviewFields({required this.proposal});

  final Proposal proposal;

  @override
  ConsumerState<_ReviewFields> createState() => _ReviewFieldsState();
}

class _ReviewFieldsState extends ConsumerState<_ReviewFields> {
  late final TextEditingController _notesController;
  late final TextEditingController _versionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.proposal.notes ?? '');
    _versionController = TextEditingController(
      text: widget.proposal.updatedVersion ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _ReviewFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proposal.id != widget.proposal.id) {
      _notesController.text = widget.proposal.notes ?? '';
      _versionController.text = widget.proposal.updatedVersion ?? '';
      return;
    }
    final notes = widget.proposal.notes ?? '';
    if (oldWidget.proposal.notes != widget.proposal.notes &&
        _notesController.text != notes) {
      _notesController.text = notes;
    }
    final version = widget.proposal.updatedVersion ?? '';
    if (oldWidget.proposal.updatedVersion != widget.proposal.updatedVersion &&
        _versionController.text != version) {
      _versionController.text = version;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notes = _notesController.text.trim();
    final version = _versionController.text.trim();
    final updated = widget.proposal.copyWith(
      notes: notes.isEmpty ? null : notes,
      clearNotes: notes.isEmpty,
      updatedVersion: version.isEmpty ? null : version,
      clearUpdatedVersion: version.isEmpty,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(proposalsProvider.notifier).save(
            updated,
            isNew: false,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
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

  Future<void> _copyVersion() async {
    final text = _versionController.text;
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated version copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.proposal.language == ProposalLanguage.arabic;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'How to improve this proposal, or its weaknesses.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate500,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Write a note',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Updated version',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _versionController.text.trim().isEmpty
                    ? null
                    : _copyVersion,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
          Text(
            'The improved proposal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate500,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _versionController,
            minLines: 6,
            maxLines: 14,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Write the improved proposal',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
