import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/proposal.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  String _percent(int hired, int total) {
    if (total == 0) return '—';
    return '${((hired / total) * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.overall.total == 0) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No stats yet',
              message:
                  'Once you track proposals and update their status, hire rates will show up here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _StatCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall hire rate',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _percent(stats.overall.hired, stats.overall.total),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.teal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.overall.hired} hired of ${stats.overall.total} proposals',
                      style: const TextStyle(color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ProposalStatus.values.map((status) {
                  final count = stats.byStatus[status] ?? 0;
                  return Container(
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: TextStyle(
                            color: AppTheme.statusColor(status),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Hire rate by language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ...ProposalLanguage.values.map((language) {
                final data = stats.byLanguage[language]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StatCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                language.label,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${data.hired} hired · ${data.total} total',
                                style:
                                    const TextStyle(color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _percent(data.hired, data.total),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: AppColors.teal),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (stats.byTemplate.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Hire rate by template',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...stats.byTemplate.map((row) {
                  final name = stats.templateNames[row.templateId] ??
                      'Deleted template';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StatCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${row.hired} hired · ${row.total} total',
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _percent(row.hired, row.total),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: child,
    );
  }
}
