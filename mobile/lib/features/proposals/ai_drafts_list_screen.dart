import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/ai_draft.dart';
import '../../data/models/ai_proposal.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';

class AiDraftsListScreen extends ConsumerWidget {
  const AiDraftsListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AiDraft draft,
  ) async {
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
    if (confirmed == true) {
      await ref.read(aiDraftsProvider.notifier).delete(draft.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(aiDraftsProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI drafts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/proposals'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(
              '/proposals/ai-wizard',
              extra: const AiWizardArgs(mode: AiWizardMode.fromTemplate),
            ),
            child: const Text('With template'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/proposals/ai-wizard'),
        icon: const Icon(Icons.psychology_outlined),
        label: const Text('New AI draft'),
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (drafts) {
          if (drafts.isEmpty) {
            return EmptyState(
              icon: Icons.psychology_outlined,
              title: 'No AI drafts yet',
              message: 'Generate a proposal with AI and save it here.',
              actionLabel: 'Generate with AI',
              onAction: () => context.push('/proposals/ai-wizard'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.slate200),
                ),
                title: Text(draft.title),
                subtitle: Text(
                  '${draft.domainLabel} · ${dateFormat.format(draft.updatedAt.toLocal())}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, draft),
                ),
                onTap: () => context.push('/ai-drafts/${draft.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
