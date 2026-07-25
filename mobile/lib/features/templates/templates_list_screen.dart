import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/proposal.dart';
import '../../data/models/template.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';

class TemplatesListScreen extends ConsumerWidget {
  const TemplatesListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProposalTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('“${template.name}” will be removed from this device.'),
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
      await ref.read(templatesProvider.notifier).delete(template.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/templates/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add template'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'No templates yet',
              message:
                  'Save your best English and Arabic pitches, then apply them when you send a new proposal.',
              actionLabel: 'Add template',
              onAction: () => context.push('/templates/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(templatesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final template = templates[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/templates/${template.id}/edit'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  template.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: template.isFavorite
                                    ? 'Unmark favorite'
                                    : 'Mark as best',
                                onPressed: () => ref
                                    .read(templatesProvider.notifier)
                                    .toggleFavorite(template),
                                icon: Icon(
                                  template.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: template.isFavorite
                                      ? AppColors.amber
                                      : AppColors.slate500,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () =>
                                    _confirmDelete(context, ref, template),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          LanguageChip(language: template.language),
                          const SizedBox(height: 8),
                          Directionality(
                            textDirection:
                                template.language == ProposalLanguage.arabic
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                            child: Text(
                              template.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
