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
              Row(
                children: [
                  StatusChip(status: proposal.status),
                  const SizedBox(width: 8),
                  LanguageChip(language: proposal.language),
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
                  final selected = proposal.status == status;
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: selected,
                    selectedColor: AppTheme.statusSoftColor(status),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.statusColor(status)
                          : AppColors.slate700,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: selected
                        ? null
                        : (_) => ref
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
              if (proposal.notes != null && proposal.notes!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(proposal.notes!),
              ],
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
