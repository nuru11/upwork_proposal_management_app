import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/proposal.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';

class ProposalsListScreen extends ConsumerStatefulWidget {
  const ProposalsListScreen({super.key});

  @override
  ConsumerState<ProposalsListScreen> createState() =>
      _ProposalsListScreenState();
}

class _ProposalsListScreenState extends ConsumerState<ProposalsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proposalsAsync = ref.watch(proposalsProvider);
    final filter = ref.watch(proposalFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposals'),
        actions: [
          IconButton(
            tooltip: 'AI drafts',
            onPressed: () => context.push('/ai-drafts'),
            icon: const Icon(Icons.psychology_outlined),
          ),
          IconButton(
            tooltip: 'Sync now',
            onPressed: () async {
              await ref.read(authProvider.notifier).syncIfAuthenticated();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync finished')),
                );
              }
            },
            icon: const Icon(Icons.sync),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/proposals/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add proposal'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, client, or text…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(proposalFilterProvider.notifier)
                              .setSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(proposalFilterProvider.notifier).setSearch(value);
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'All status',
                  selected: filter.status == null,
                  onSelected: () =>
                      ref.read(proposalFilterProvider.notifier).setStatus(null),
                ),
                ...ProposalStatus.values.map(
                  (status) => _FilterChip(
                    label: status.label,
                    selected: filter.status == status,
                    color: AppTheme.statusColor(status),
                    onSelected: () => ref
                        .read(proposalFilterProvider.notifier)
                        .setStatus(status),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'All languages',
                  selected: filter.language == null,
                  onSelected: () => ref
                      .read(proposalFilterProvider.notifier)
                      .setLanguage(null),
                ),
                ...ProposalLanguage.values.map(
                  (language) => _FilterChip(
                    label: language.label,
                    selected: filter.language == language,
                    onSelected: () => ref
                        .read(proposalFilterProvider.notifier)
                        .setLanguage(language),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'All types',
                  selected: filter.projectType == null,
                  onSelected: () => ref
                      .read(proposalFilterProvider.notifier)
                      .setProjectType(null),
                ),
                ...ProposalProjectType.values.map(
                  (type) => _FilterChip(
                    label: type.label,
                    selected: filter.projectType == type,
                    color: AppColors.blue,
                    onSelected: () => ref
                        .read(proposalFilterProvider.notifier)
                        .setProjectType(type),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: proposalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (proposals) {
                if (proposals.isEmpty) {
                  final hasFilters = filter.status != null ||
                      filter.language != null ||
                      filter.projectType != null ||
                      filter.search.isNotEmpty;
                  return EmptyState(
                    icon: Icons.description_outlined,
                    title: hasFilters ? 'No matches' : 'No proposals yet',
                    message: hasFilters
                        ? 'Try clearing filters or search to see more proposals.'
                        : 'Track your Upwork pitches, language, and status in one place.',
                    actionLabel: hasFilters ? 'Clear filters' : 'Add proposal',
                    onAction: hasFilters
                        ? () {
                            _searchController.clear();
                            ref.read(proposalFilterProvider.notifier).clear();
                          }
                        : () => context.push('/proposals/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(proposalsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: proposals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final proposal = proposals[index];
                      return _ProposalTile(proposal: proposal);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color?.withValues(alpha: 0.18) ?? AppColors.tealSoft,
        labelStyle: TextStyle(
          color: selected ? (color ?? AppColors.teal) : AppColors.slate700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        showCheckmark: false,
      ),
    );
  }
}

class _ProposalTile extends StatelessWidget {
  const _ProposalTile({required this.proposal});

  final Proposal proposal;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().format(proposal.updatedAt);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/proposals/${proposal.id}'),
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
                      proposal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (proposal.clientName != null &&
                  proposal.clientName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  proposal.clientName!,
                  style: const TextStyle(color: AppColors.slate500),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(status: proposal.status, compact: true),
                  LanguageChip(language: proposal.language),
                  ProjectTypeChip(
                    projectType: proposal.projectType,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
