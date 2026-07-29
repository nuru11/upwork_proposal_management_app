import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/project.dart';
import '../../shared/theme/app_theme.dart';

String formatProjectsForCopy({
  required List<Project> projects,
  required bool includePlayStore,
  required bool includeAppStore,
  required bool includeWeb,
}) {
  final blocks = <String>[];
  for (final project in projects) {
    final lines = <String>['app name: ${project.name}'];
    if (includePlayStore && project.hasPlayStore) {
      lines.add('play store: ${project.playStoreUrl}');
    }
    if (includeAppStore && project.hasAppStore) {
      lines.add('app store: ${project.appStoreUrl}');
    }
    if (includeWeb && project.hasWeb) {
      lines.add('web app: ${project.webUrl}');
    }
    blocks.add(lines.join('\n'));
  }
  return blocks.join('\n\n');
}

Future<void> showCopyProjectsSheet(
  BuildContext context, {
  required List<Project> projects,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _CopyProjectsSheet(projects: projects),
  );
}

class _CopyProjectsSheet extends StatefulWidget {
  const _CopyProjectsSheet({required this.projects});

  final List<Project> projects;

  @override
  State<_CopyProjectsSheet> createState() => _CopyProjectsSheetState();
}

class _CopyProjectsSheetState extends State<_CopyProjectsSheet> {
  late final Set<String> _selectedIds;
  bool _includePlayStore = true;
  bool _includeAppStore = true;
  bool _includeWeb = true;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.projects.map((p) => p.id).toSet();
  }

  bool get _hasLinkType =>
      _includePlayStore || _includeAppStore || _includeWeb;

  bool get _canCopy => _selectedIds.isNotEmpty && _hasLinkType;

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(widget.projects.map((p) => p.id));
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }

  Future<void> _copy() async {
    if (!_canCopy) return;

    final selected = widget.projects
        .where((p) => _selectedIds.contains(p.id))
        .toList();
    final text = formatProjectsForCopy(
      projects: selected,
      includePlayStore: _includePlayStore,
      includeAppStore: _includeAppStore,
      includeWeb: _includeWeb,
    );

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to copy for the selected options')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          selected.length == 1
              ? 'Copied 1 project'
              : 'Copied ${selected.length} projects',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Copy projects',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Include links',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Play Store'),
                  selected: _includePlayStore,
                  onSelected: (value) =>
                      setState(() => _includePlayStore = value),
                  selectedColor: AppColors.tealSoft,
                  checkmarkColor: AppColors.teal,
                  labelStyle: TextStyle(
                    color: _includePlayStore
                        ? AppColors.teal
                        : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                FilterChip(
                  label: const Text('App Store'),
                  selected: _includeAppStore,
                  onSelected: (value) =>
                      setState(() => _includeAppStore = value),
                  selectedColor: AppColors.tealSoft,
                  checkmarkColor: AppColors.teal,
                  labelStyle: TextStyle(
                    color:
                        _includeAppStore ? AppColors.teal : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                FilterChip(
                  label: const Text('Web'),
                  selected: _includeWeb,
                  onSelected: (value) => setState(() => _includeWeb = value),
                  selectedColor: AppColors.tealSoft,
                  checkmarkColor: AppColors.teal,
                  labelStyle: TextStyle(
                    color: _includeWeb ? AppColors.teal : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (!_hasLinkType)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Select at least one link type',
                style: TextStyle(color: AppColors.rose, fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Projects',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select all'),
                ),
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.projects.length,
              itemBuilder: (context, index) {
                final project = widget.projects[index];
                final selected = _selectedIds.contains(project.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(project.id);
                      } else {
                        _selectedIds.remove(project.id);
                      }
                    });
                  },
                  title: Text(project.name),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _canCopy ? _copy : null,
              icon: const Icon(Icons.copy_outlined),
              label: Text(
                _selectedIds.isEmpty
                    ? 'Copy'
                    : 'Copy ${_selectedIds.length} selected',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
