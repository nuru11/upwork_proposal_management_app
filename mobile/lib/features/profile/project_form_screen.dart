import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/project.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  const ProjectFormScreen({super.key, this.projectId});

  final String? projectId;

  bool get isEditing => projectId != null;

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _playStoreController = TextEditingController();
  final _appStoreController = TextEditingController();
  final _webController = TextEditingController();

  final Set<ProjectType> _selectedTypes = {};
  bool _loaded = false;
  bool _saving = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _playStoreController.dispose();
    _appStoreController.dispose();
    _webController.dispose();
    super.dispose();
  }

  void _hydrate(Project project) {
    if (_loaded) return;
    _nameController.text = project.name;
    _playStoreController.text = project.playStoreUrl ?? '';
    _appStoreController.text = project.appStoreUrl ?? '';
    _webController.text = project.webUrl ?? '';
    _selectedTypes
      ..clear()
      ..addAll(project.types);
    _loaded = true;
  }

  String? _optionalUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateUrlField(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return 'Enter a valid http(s) URL';
    }
    return null;
  }

  bool _hasAtLeastOneLink() {
    return _optionalUrl(_playStoreController.text) != null ||
        _optionalUrl(_appStoreController.text) != null ||
        _optionalUrl(_webController.text) != null;
  }

  Future<void> _save({Project? existing}) async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      setState(() => _formError = 'Select at least one project type');
      return;
    }
    if (!_hasAtLeastOneLink()) {
      setState(() {
        _formError = 'Add at least one of Play Store, App Store, or Web URL';
      });
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final project = Project(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      playStoreUrl: _optionalUrl(_playStoreController.text),
      appStoreUrl: _optionalUrl(_appStoreController.text),
      webUrl: _optionalUrl(_webController.text),
      types: _selectedTypes.toList(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(projectsProvider.notifier).save(
            project,
            isNew: existing == null,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final asyncProject = ref.watch(projectByIdProvider(widget.projectId!));
      return asyncProject.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (project) {
          if (project == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit project')),
              body: const Center(child: Text('Project not found')),
            );
          }
          _hydrate(project);
          return _buildForm(existing: project);
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm({Project? existing}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add project' : 'Edit project'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(existing: existing),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'App name',
                hintText: 'My App',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'App name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Types',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjectType.values.map((type) {
                final selected = _selectedTypes.contains(type);
                return FilterChip(
                  label: Text(type.label),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedTypes.add(type);
                      } else {
                        _selectedTypes.remove(type);
                      }
                    });
                  },
                  selectedColor: AppColors.tealSoft,
                  checkmarkColor: AppColors.teal,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.teal : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.teal : AppColors.slate200,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _playStoreController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Play Store URL',
                hintText: 'https://play.google.com/store/apps/...',
              ),
              validator: _validateUrlField,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _appStoreController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'App Store URL',
                hintText: 'https://apps.apple.com/...',
              ),
              validator: _validateUrlField,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _webController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Web URL',
                hintText: 'https://example.com',
              ),
              validator: _validateUrlField,
            ),
            if (_formError != null) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(existing: existing),
              child: Text(existing == null ? 'Add project' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
