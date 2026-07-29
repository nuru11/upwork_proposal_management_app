import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/proposal.dart';
import '../../data/models/template.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class TemplateFormScreen extends ConsumerStatefulWidget {
  const TemplateFormScreen({super.key, this.templateId});

  final String? templateId;

  bool get isEditing => templateId != null;

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();

  ProposalLanguage _language = ProposalLanguage.english;
  ProposalProjectType _projectType = ProposalProjectType.mobileApp;
  bool _isFavorite = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _hydrate(ProposalTemplate template) {
    if (_loaded) return;
    _nameController.text = template.name;
    _bodyController.text = template.body;
    _language = template.language;
    _projectType = template.projectType;
    _isFavorite = template.isFavorite;
    _loaded = true;
  }

  Future<void> _save({ProposalTemplate? existing}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final template = ProposalTemplate(
      id: existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      body: _bodyController.text.trim(),
      language: _language,
      projectType: _projectType,
      isFavorite: _isFavorite,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await ref.read(templatesProvider.notifier).save(
            template,
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
      final asyncTemplate =
          ref.watch(templateByIdProvider(widget.templateId!));
      return asyncTemplate.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (template) {
          if (template == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit template')),
              body: const Center(child: Text('Template not found')),
            );
          }
          _hydrate(template);
          return _buildForm(existing: template);
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm({ProposalTemplate? existing}) {
    final isRtl = _language == ProposalLanguage.arabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add template' : 'Edit template'),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template name *',
                hintText: 'e.g. Mobile MVP pitch — English',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Project type *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProposalProjectType.values.map((type) {
                final selected = _projectType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: selected,
                  selectedColor: AppColors.blueSoft,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.blue : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => _projectType = type),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Language', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ProposalLanguage>(
              segments: ProposalLanguage.values
                  .map(
                    (lang) => ButtonSegment(
                      value: lang,
                      label: Text(lang.label),
                    ),
                  )
                  .toList(),
              selected: {_language},
              onSelectionChanged: (value) {
                setState(() => _language = value.first);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as best / favorite'),
              subtitle: const Text('Favorites appear first in the library'),
              value: _isFavorite,
              activeThumbColor: AppColors.teal,
              onChanged: (value) => setState(() => _isFavorite = value),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Template body *',
                  alignLabelWithHint: true,
                  hintText: isRtl
                      ? 'نص قالب العرض…'
                      : 'Reusable proposal text…',
                ),
                minLines: 10,
                maxLines: 20,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Template body is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(existing: existing),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(existing == null ? 'Create template' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
