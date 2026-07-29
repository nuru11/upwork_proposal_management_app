import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/project.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import 'copy_projects_sheet.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('“${project.name}” will be removed from this device.'),
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
      await ref.read(projectsProvider.notifier).delete(project.id);
    }
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

  Future<void> _openCopySheet(
    BuildContext context,
    List<Project>? projects,
  ) async {
    if (projects == null || projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No projects to copy')),
      );
      return;
    }
    await showCopyProjectsSheet(context, projects: projects);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final filter = ref.watch(projectFilterProvider);
    final projects = projectsAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            tooltip: 'Copy projects',
            onPressed: () => _openCopySheet(context, projects),
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/projects/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add project'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All types'),
                    selected: filter.type == null,
                    onSelected: (_) =>
                        ref.read(projectFilterProvider.notifier).setType(null),
                    selectedColor: AppColors.tealSoft,
                    labelStyle: TextStyle(
                      color: filter.type == null
                          ? AppColors.teal
                          : AppColors.slate700,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    showCheckmark: false,
                  ),
                ),
                ...ProjectType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(type.label),
                      selected: filter.type == type,
                      onSelected: (_) => ref
                          .read(projectFilterProvider.notifier)
                          .setType(type),
                      selectedColor: AppColors.blue.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: filter.type == type
                            ? AppColors.blue
                            : AppColors.slate700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      showCheckmark: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: projectsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (projects) {
                if (projects.isEmpty) {
                  final hasFilter = filter.type != null;
                  return EmptyState(
                    icon: Icons.apps_outlined,
                    title: hasFilter ? 'No matches' : 'No projects yet',
                    message: hasFilter
                        ? 'Try clearing the type filter to see more projects.'
                        : 'Add your apps with Play Store, App Store, or web links.',
                    actionLabel: hasFilter ? 'Clear filter' : 'Add project',
                    onAction: hasFilter
                        ? () =>
                            ref.read(projectFilterProvider.notifier).clear()
                        : () => context.push('/profile/projects/new'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(projectsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: projects.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push(
                            '/profile/projects/${project.id}/edit',
                          ),
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
                                        project.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _confirmDelete(
                                        context,
                                        ref,
                                        project,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ...project.types.map(
                                      (type) => Chip(
                                        label: Text(type.label),
                                        visualDensity: VisualDensity.compact,
                                        side: const BorderSide(
                                          color: AppColors.slate200,
                                        ),
                                        backgroundColor: AppColors.blueSoft
                                            .withValues(alpha: 0.45),
                                        labelStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.blue,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (project.hasPlayStore)
                                      _LinkChip(
                                        label: 'Play Store',
                                        icon: Icons.shop_outlined,
                                        onTap: () => _openUrl(
                                          context,
                                          project.playStoreUrl!,
                                        ),
                                      ),
                                    if (project.hasAppStore)
                                      _LinkChip(
                                        label: 'App Store',
                                        icon: Icons.apple,
                                        onTap: () => _openUrl(
                                          context,
                                          project.appStoreUrl!,
                                        ),
                                      ),
                                    if (project.hasWeb)
                                      _LinkChip(
                                        label: 'Web',
                                        icon: Icons.language,
                                        onTap: () => _openUrl(
                                          context,
                                          project.webUrl!,
                                        ),
                                      ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.teal),
      label: Text(label),
      labelStyle: const TextStyle(
        color: AppColors.slate700,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      onPressed: onTap,
      side: const BorderSide(color: AppColors.slate200),
      backgroundColor: AppColors.tealSoft.withValues(alpha: 0.35),
    );
  }
}
