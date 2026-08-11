import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_draft.dart';
import '../../data/models/ai_proposal.dart';
import '../../data/models/proposal.dart';
import '../../data/models/template.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

class ProposalFormScreen extends ConsumerStatefulWidget {
  const ProposalFormScreen({super.key, this.proposalId, this.prefill});

  final String? proposalId;
  final ProposalPrefill? prefill;

  bool get isEditing => proposalId != null;

  @override
  ConsumerState<ProposalFormScreen> createState() => _ProposalFormScreenState();
}

class _ProposalFormScreenState extends ConsumerState<ProposalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _notesController = TextEditingController();

  ProposalLanguage _language = ProposalLanguage.english;
  ProposalStatus _status = ProposalStatus.submitted;
  ProposalProjectType _projectType = ProposalProjectType.mobileApp;
  String? _templateId;
  String? _templateName;
  String? _templateBody;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null && !widget.isEditing) {
      if (prefill.title != null) _titleController.text = prefill.title!;
      if (prefill.body != null) _bodyController.text = prefill.body!;
      if (prefill.clientName != null) {
        _clientController.text = prefill.clientName!;
      }
      if (prefill.language != null) {
        _language = ProposalLanguage.fromStorage(prefill.language!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _hydrate(Proposal proposal) {
    if (_loaded) return;
    _titleController.text = proposal.title;
    _clientController.text = proposal.clientName ?? '';
    _urlController.text = proposal.jobUrl ?? '';
    _bodyController.text = proposal.body;
    _notesController.text = proposal.notes ?? '';
    _language = proposal.language;
    _status = proposal.status;
    _projectType = proposal.projectType;
    _templateId = proposal.templateId;
    _loaded = true;
  }

  Future<void> _pickTemplate() async {
    final templates = await ref.read(templateRepositoryProvider).getAll();
    if (!mounted) return;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No templates yet. Create one in Templates first.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<ProposalTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      'Use a template',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.slate200),
                          ),
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.projectType.label} · ${template.language.label}'
                            '${template.isFavorite ? ' · Favorite' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, template),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _bodyController.text = selected.body;
      _language = selected.language;
      _projectType = selected.projectType;
      _templateId = selected.id;
      _templateName = selected.name;
      _templateBody = selected.body;
    });
  }

  Future<void> _openAiWizard() async {
    final result = await context.push<AiWizardResult>(
      '/proposals/ai-wizard',
      extra: AiWizardArgs(
        initialLanguage: _language.name,
        templateBody: _templateBody,
        clientName: _clientController.text.trim().isEmpty
            ? null
            : _clientController.text.trim(),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _bodyController.text = result.body;
    });
  }

  Future<void> _save({Proposal? existing}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final proposal = Proposal(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      clientName: _clientController.text.trim().isEmpty
          ? null
          : _clientController.text.trim(),
      jobUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      body: _bodyController.text.trim(),
      language: _language,
      status: _status,
      projectType: _projectType,
      templateId: _templateId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      submittedAt: existing?.submittedAt ?? now,
    );

    try {
      await ref.read(proposalsProvider.notifier).save(
            proposal,
            isNew: existing == null,
          );
      if (!mounted) return;
      if (existing == null) {
        context.go('/proposals/${proposal.id}');
      } else {
        context.pop();
      }
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
    final isEditing = widget.isEditing;

    if (isEditing) {
      final asyncProposal = ref.watch(proposalByIdProvider(widget.proposalId!));
      return asyncProposal.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (proposal) {
          if (proposal == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit proposal')),
              body: const Center(child: Text('Proposal not found')),
            );
          }
          _hydrate(proposal);
          if (_templateId != null && _templateName == null) {
            ref.watch(templateByIdProvider(_templateId!)).whenData((t) {
              if (t != null && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _templateName = t.name;
                      _templateBody ??= t.body;
                    });
                  }
                });
              }
            });
          }
          return _buildForm(existing: proposal);
        },
      );
    }

    return _buildForm();
  }

  Widget _buildForm({Proposal? existing}) {
    final isRtl = _language == ProposalLanguage.arabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add proposal' : 'Edit proposal'),
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
            OutlinedButton.icon(
              onPressed: _pickTemplate,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(
                _templateName == null
                    ? 'Use template'
                    : 'Template: $_templateName',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openAiWizard,
              icon: const Icon(Icons.psychology_outlined),
              label: const Text('Generate with AI'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Job title *',
                hintText: 'e.g. Flutter developer for delivery app',
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientController,
              decoration: const InputDecoration(
                labelText: 'Client name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Job URL',
                hintText: 'https://www.upwork.com/jobs/...',
              ),
              keyboardType: TextInputType.url,
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
                      icon: Icon(
                        lang == ProposalLanguage.arabic
                            ? Icons.translate
                            : Icons.language,
                      ),
                    ),
                  )
                  .toList(),
              selected: {_language},
              onSelectionChanged: (value) {
                setState(() => _language = value.first);
              },
            ),
            const SizedBox(height: 16),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProposalStatus.values.map((status) {
                final selected = _status == status;
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
                  onSelected: (_) => setState(() => _status = status),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: 'Proposal text *',
                  alignLabelWithHint: true,
                  hintText: isRtl
                      ? 'اكتب نص العرض هنا…'
                      : 'Write your proposal here…',
                ),
                minLines: 8,
                maxLines: 16,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Proposal text is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Private notes',
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(existing: existing),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(existing == null ? 'Create proposal' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
