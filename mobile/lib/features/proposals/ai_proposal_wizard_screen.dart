import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_draft.dart';
import '../../data/models/ai_proposal.dart';
import '../../data/models/project.dart';
import '../../data/models/proposal.dart';
import '../../data/models/template.dart';
import '../../data/remote/api_client.dart';
import '../../providers/providers.dart';
import '../../shared/template_placeholders.dart';
import '../../shared/theme/app_theme.dart';
import 'inline_template_preview.dart' show FieldFillMode, InlineTemplatePreview;

class AiProposalWizardScreen extends ConsumerStatefulWidget {
  const AiProposalWizardScreen({super.key, this.args});

  final AiWizardArgs? args;

  @override
  ConsumerState<AiProposalWizardScreen> createState() =>
      _AiProposalWizardScreenState();
}

class _AiProposalWizardScreenState
    extends ConsumerState<AiProposalWizardScreen> {
  final _jobController = TextEditingController();
  final _notesController = TextEditingController();
  final _draftController = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _error;

  AiDomain _domain = AiDomain.marketplace;
  ProposalLanguage _language = ProposalLanguage.english;
  late AiWizardMode _mode;
  List<ProposalTemplate> _templates = [];
  String? _selectedTemplateId;

  List<AiIssue> _issues = [];
  final Map<String, TextEditingController> _issueTitleControllers = {};
  final Map<String, TextEditingController> _issueWhyControllers = {};
  List<AiSolution> _solutions = [];
  final Map<String, TextEditingController> _solutionControllers = {};

  List<Project> _projects = [];
  final Set<String> _selectedProjectIds = {};
  final Set<String> _describeProjectIds = {};
  final Map<String, TextEditingController> _projectNoteControllers = {};
  bool _projectsLoading = true;

  final Map<String, TextEditingController> _fieldControllers = {};
  final Map<String, FieldFillMode> _fieldModes = {};
  String? _fieldTemplateId;
  String? _fieldBusyKey;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args?.initialLanguage != null) {
      _language = ProposalLanguage.fromStorage(args!.initialLanguage!);
    }
    final initialTemplateId = args?.templateId?.trim();
    if (initialTemplateId != null && initialTemplateId.isNotEmpty) {
      _selectedTemplateId = initialTemplateId;
    }
    _mode = args?.mode ?? AiWizardMode.ai;
    _loadProjects();
    _loadTemplates();
  }

  bool get _fromTemplate => _mode == AiWizardMode.fromTemplate;

  int get _draftStep => _fromTemplate ? 1 : 3;

  void _setMode(AiWizardMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
      if (mode == AiWizardMode.fromTemplate &&
          _selectedTemplateId == null &&
          _templates.isNotEmpty) {
        _selectedTemplateId = _templates.first.id;
      }
      _syncFieldControllers();
    });
  }

  Future<void> _loadTemplates() async {
    try {
      final list = await ref.read(templateRepositoryProvider).getAll();
      if (!mounted) return;
      setState(() {
        _templates = list;
        final selectedMissing = _selectedTemplateId == null ||
            list.every((t) => t.id != _selectedTemplateId);
        if (selectedMissing) {
          _selectedTemplateId = _fromTemplate && list.isNotEmpty
              ? list.first.id
              : null;
        }
        _syncFieldControllers();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error ??= _friendlyError(e));
    }
  }

  ProposalTemplate? get _selectedTemplate {
    final id = _selectedTemplateId;
    if (id == null) return null;
    for (final template in _templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  Future<void> _loadProjects() async {
    try {
      final list = await ref.read(projectRepositoryProvider).getAll();
      if (!mounted) return;
      setState(() {
        _projects = list;
        _selectedProjectIds
          ..clear()
          ..addAll(_matchingProjectIds(list, _domain));
        _projectsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectsLoading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Set<String> _matchingProjectIds(List<Project> projects, AiDomain domain) {
    final type = domain.matchingProjectType;
    if (type == null) return {};
    return projects
        .where((p) => p.types.contains(type))
        .map((p) => p.id)
        .toSet();
  }

  void _setDomain(AiDomain domain) {
    setState(() {
      _domain = domain;
      _selectedProjectIds
        ..clear()
        ..addAll(_matchingProjectIds(_projects, domain));
    });
  }

  void _toggleProject(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedProjectIds.add(id);
      } else {
        _selectedProjectIds.remove(id);
      }
    });
  }

  void _toggleDescribe(String id, bool describe) {
    setState(() {
      if (describe) {
        _describeProjectIds.add(id);
      } else {
        _describeProjectIds.remove(id);
      }
    });
  }

  TextEditingController _noteControllerFor(String id) {
    return _projectNoteControllers.putIfAbsent(
      id,
      TextEditingController.new,
    );
  }

  String _projectPreview(Project project) {
    final text = project.description?.trim() ?? '';
    if (text.isEmpty) return 'No description';
    if (text.length <= 80) return text;
    return '${text.substring(0, 80)}…';
  }

  @override
  void dispose() {
    _jobController.dispose();
    _notesController.dispose();
    _draftController.dispose();
    for (final c in _issueTitleControllers.values) {
      c.dispose();
    }
    for (final c in _issueWhyControllers.values) {
      c.dispose();
    }
    for (final c in _solutionControllers.values) {
      c.dispose();
    }
    for (final c in _projectNoteControllers.values) {
      c.dispose();
    }
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncFieldControllers() {
    final body = _fromTemplate ? (_templateBody ?? '') : '';
    final keys = extractPlaceholders(body);
    final templateId = _fromTemplate ? _selectedTemplateId : null;
    final sameKeys = keys.length == _fieldControllers.length &&
        keys.every(_fieldControllers.containsKey);
    if (templateId == _fieldTemplateId && sameKeys) return;

    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    _fieldControllers.clear();
    _fieldModes.clear();
    final client = widget.args?.clientName?.trim() ?? '';
    for (final key in keys) {
      final initial =
          isClientNamePlaceholder(key) && client.isNotEmpty ? client : '';
      _fieldControllers[key] = TextEditingController(text: initial);
      _fieldModes[key] = FieldFillMode.absolute;
    }
    _fieldTemplateId = templateId;
  }

  Map<String, String> get _fieldValues => {
        for (final entry in _fieldControllers.entries)
          entry.key: entry.value.text.trim(),
      };

  bool _isNote(String key) => _fieldModes[key] == FieldFillMode.note;

  List<String> get _keysNeedingAi => _fieldControllers.keys.where((key) {
        final value = _fieldValues[key] ?? '';
        if (isOptionalNamePlaceholder(key) && value.isEmpty && !_isNote(key)) {
          return false;
        }
        return value.isEmpty || _isNote(key);
      }).toList();

  void _toggleFieldMode(String key) {
    setState(() {
      _fieldModes[key] = _isNote(key)
          ? FieldFillMode.absolute
          : FieldFillMode.note;
    });
  }

  ({
    Map<String, String> filled,
    List<String> emptyKeys,
    Map<String, String> instructions,
  }) _splitFieldPayload({List<String>? onlyKeys}) {
    final targets = onlyKeys ?? _fieldControllers.keys.toList();
    final filled = <String, String>{};
    final emptyKeys = <String>[];
    final instructions = <String, String>{};

    for (final key in _fieldControllers.keys) {
      final value = _fieldValues[key] ?? '';
      final targeted = targets.contains(key);
      if (!targeted) {
        if (!_isNote(key) && value.isNotEmpty) filled[key] = value;
        continue;
      }
      if (_isNote(key) && value.isNotEmpty) {
        emptyKeys.add(key);
        instructions[key] = value;
      } else if (value.isEmpty) {
        if (!isOptionalNamePlaceholder(key)) emptyKeys.add(key);
      } else {
        filled[key] = value;
      }
    }
    return (filled: filled, emptyKeys: emptyKeys, instructions: instructions);
  }

  String? get _templateBody {
    final body = _selectedTemplate?.body.trim();
    if (body == null || body.isEmpty) return null;
    return body;
  }

  String? get _inspiredFrom {
    final text = _selectedTemplate?.inspiredFrom?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? get _guidanceNotes {
    final notes = _notesController.text.trim();
    return notes.isEmpty ? null : notes;
  }

  void _syncIssueControllers(List<AiIssue> issues) {
    for (final c in _issueTitleControllers.values) {
      c.dispose();
    }
    for (final c in _issueWhyControllers.values) {
      c.dispose();
    }
    _issueTitleControllers.clear();
    _issueWhyControllers.clear();
    for (final issue in issues) {
      _issueTitleControllers[issue.id] =
          TextEditingController(text: issue.title);
      _issueWhyControllers[issue.id] =
          TextEditingController(text: issue.whyItFails);
    }
  }

  void _registerIssueControllers(AiIssue issue) {
    _issueTitleControllers[issue.id]?.dispose();
    _issueWhyControllers[issue.id]?.dispose();
    _issueTitleControllers[issue.id] =
        TextEditingController(text: issue.title);
    _issueWhyControllers[issue.id] =
        TextEditingController(text: issue.whyItFails);
  }

  void _disposeIssueControllers(String id) {
    _issueTitleControllers.remove(id)?.dispose();
    _issueWhyControllers.remove(id)?.dispose();
  }

  void _syncSolutionControllers(List<AiSolution> solutions) {
    for (final c in _solutionControllers.values) {
      c.dispose();
    }
    _solutionControllers.clear();
    for (final s in solutions) {
      _solutionControllers[s.issueId] =
          TextEditingController(text: s.offer);
    }
  }

  List<AiIssue> _selectedIssuesWithEdits() {
    return _issues
        .where((i) => i.selected)
        .map(
          (i) => i.copyWith(
            title: _issueTitleControllers[i.id]?.text.trim() ?? i.title,
            whyItFails:
                _issueWhyControllers[i.id]?.text.trim() ?? i.whyItFails,
          ),
        )
        .where((i) => i.title.isNotEmpty)
        .toList();
  }

  List<AiSolution> _solutionsWithEdits() {
    return _solutions
        .map(
          (s) => s.copyWith(
            offer: _solutionControllers[s.issueId]?.text.trim() ?? s.offer,
          ),
        )
        .where((s) => s.offer.isNotEmpty)
        .toList();
  }

  List<AiProjectMention> _selectedProjectMentions() {
    return _projects
        .where((p) => _selectedProjectIds.contains(p.id))
        .map(
          (p) => AiProjectMention(
            project: p,
            describe: _describeProjectIds.contains(p.id),
            mentionNote: _projectNoteControllers[p.id]?.text.trim(),
          ),
        )
        .toList();
  }

  Future<void> _extractIssues() async {
    final job = _jobController.text.trim();
    if (job.isEmpty) {
      setState(() => _error = 'Paste a job description first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final issues = await ref.read(aiApiProvider).extractIssues(
            jobDescription: job,
            domain: _domain.name,
            language: _language.name,
            notes: _guidanceNotes,
          );
      if (!mounted) return;
      if (issues.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No issues returned. Try again.';
        });
        return;
      }
      _syncIssueControllers(issues);
      setState(() {
        _issues = issues.map((i) => i.copyWith(selected: true)).toList();
        _step = 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _suggestSolutions() async {
    final selected = _selectedIssuesWithEdits();
    if (selected.isEmpty) {
      setState(() => _error = 'Select at least one issue.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final solutions = await ref.read(aiApiProvider).suggestSolutions(
            jobDescription: _jobController.text.trim(),
            domain: _domain.name,
            language: _language.name,
            issues: selected,
            notes: _guidanceNotes,
          );
      if (!mounted) return;
      if (solutions.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No solutions returned. Try again.';
        });
        return;
      }
      _syncSolutionControllers(solutions);
      setState(() {
        _solutions = solutions;
        _step = 2;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _draftProposal() async {
    final selected = _selectedIssuesWithEdits();
    final solutions = _solutionsWithEdits();
    if (solutions.isEmpty) {
      setState(() => _error = 'Add at least one solution.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final body = await ref.read(aiApiProvider).draftProposal(
            jobDescription: _jobController.text.trim(),
            domain: _domain.name,
            language: _language.name,
            issues: selected,
            solutions: solutions,
            projects: _selectedProjectMentions(),
            templateBody: _templateBody,
            inspiredFrom: _inspiredFrom,
            clientName: widget.args?.clientName,
            notes: _guidanceNotes,
          );
      if (!mounted) return;
      if (body.trim().isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Empty draft returned. Try again.';
        });
        return;
      }
      _draftController.text = body;
      setState(() {
        _step = 3;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _fillFieldKeys(List<String> targetKeys) async {
    final split = _splitFieldPayload(onlyKeys: targetKeys);
    if (split.emptyKeys.isEmpty) return;
    final templateBody = _templateBody;
    if (templateBody == null) {
      setState(() => _error = 'Select a template first.');
      return;
    }
    final job = _jobController.text.trim();
    if (job.isEmpty) {
      setState(() => _error = 'Paste a job description to fill with AI.');
      return;
    }

    setState(() {
      _loading = true;
      _fieldBusyKey =
          split.emptyKeys.length == 1 ? split.emptyKeys.first : null;
      _error = null;
    });

    try {
      final values = await ref.read(aiApiProvider).fillTemplateFields(
            jobDescription: job,
            domain: _domain.name,
            language: _language.name,
            templateBody: templateBody,
            filled: split.filled,
            emptyKeys: split.emptyKeys,
            instructions: split.instructions,
            projects: _selectedProjectMentions(),
            clientName: widget.args?.clientName,
            notes: _guidanceNotes,
          );
      if (!mounted) return;
      values.forEach((key, value) {
        final controller = _fieldControllers[key];
        if (controller != null && value.trim().isNotEmpty) {
          controller.text = value.trim();
          _fieldModes[key] = FieldFillMode.absolute;
        }
      });
      setState(() {
        _loading = false;
        _fieldBusyKey = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fieldBusyKey = null;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _draftFromTemplate() async {
    final templateBody = _templateBody;
    if (templateBody == null) {
      setState(() => _error = 'Select a template first.');
      return;
    }

    _syncFieldControllers();
    var values = Map<String, String>.from(_fieldValues);
    final split = _splitFieldPayload();
    final job = _jobController.text.trim();

    if (split.emptyKeys.isNotEmpty && job.isNotEmpty) {
      setState(() {
        _loading = true;
        _fieldBusyKey = null;
        _error = null;
      });
      try {
        final aiValues = await ref.read(aiApiProvider).fillTemplateFields(
              jobDescription: job,
              domain: _domain.name,
              language: _language.name,
              templateBody: templateBody,
              filled: split.filled,
              emptyKeys: split.emptyKeys,
              instructions: split.instructions,
              projects: _selectedProjectMentions(),
              clientName: widget.args?.clientName,
              notes: _guidanceNotes,
            );
        if (!mounted) return;
        aiValues.forEach((key, value) {
          final trimmed = value.trim();
          if (trimmed.isEmpty) return;
          values[key] = trimmed;
          _fieldControllers[key]?.text = trimmed;
          _fieldModes[key] = FieldFillMode.absolute;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _friendlyError(e);
        });
        return;
      }
    }

    _draftController.text = stripOptionalNamePlaceholders(
      applyPlaceholders(templateBody, values),
    );
    if (_language == ProposalLanguage.arabic) {
      setState(() {
        _loading = true;
        _fieldBusyKey = null;
        _error = null;
      });
      try {
        final rewritten = await ref.read(aiApiProvider).rewriteProposalLanguage(
              body: _draftController.text,
              language: _language.name,
            );
        if (!mounted) return;
        if (rewritten.trim().isNotEmpty) {
          _draftController.text = rewritten.trim();
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = _friendlyError(e);
        });
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _step = _draftStep;
      _loading = false;
      _fieldBusyKey = null;
      _error = null;
    });
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }

  void _useDraft() {
    final body = _draftController.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Draft is empty.');
      return;
    }
    context.pop(AiWizardResult(body: body));
  }

  Future<void> _saveAiDraft() async {
    final body = _draftController.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Draft is empty.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final job = _jobController.text.trim();
      final draft = AiDraft(
        id: const Uuid().v4(),
        title: AiDraft.titleFromJob(job),
        jobDescription: job,
        notes: _guidanceNotes,
        domain: _domain.name,
        language: _language.name,
        issues: _selectedIssuesWithEdits(),
        solutions: _solutionsWithEdits(),
        body: body,
        clientName: widget.args?.clientName,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(aiDraftsProvider.notifier).save(draft, isNew: true);
      if (!mounted) return;
      context.go('/ai-drafts/${draft.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String get _stepTitle {
    if (_fromTemplate) {
      return _step == 0 ? 'Job & template' : 'Proposal draft';
    }
    return switch (_step) {
      0 => 'Job & domain',
      1 => 'Common issues',
      2 => 'Solutions to offer',
      3 => 'Proposal draft',
      _ => 'AI wizard',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _StepIndicator(
              step: _step,
              labels: _fromTemplate
                  ? const ['Job', 'Draft']
                  : const ['Job', 'Issues', 'Solutions', 'Draft'],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: AppColors.roseSoft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.rose),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.rose),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _error = null),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: AbsorbPointer(
              absorbing: _loading,
              child: switch (_step) {
                0 => _buildInputStep(),
                1 => _fromTemplate ? _buildDraftStep() : _buildIssuesStep(),
                2 => _buildSolutionsStep(),
                _ => _buildDraftStep(),
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _error = null;
                                _step -= 1;
                              }),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_step == _draftStep) ...[
                    OutlinedButton(
                      onPressed: _loading ? null : _saveAiDraft,
                      child: const Text('Save AI draft'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: _loading ? null : _primaryAction,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_primaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _primaryLabel {
    if (_fromTemplate) {
      return _step == 0 ? 'Generate draft' : 'Use draft';
    }
    return switch (_step) {
      0 => 'Extract issues',
      1 => 'Suggest solutions',
      2 => 'Generate draft',
      _ => 'Use draft',
    };
  }

  VoidCallback get _primaryAction {
    if (_fromTemplate) {
      return _step == 0 ? _draftFromTemplate : _useDraft;
    }
    return switch (_step) {
      0 => _extractIssues,
      1 => _suggestSolutions,
      2 => _draftProposal,
      _ => _useDraft,
    };
  }

  Widget _buildInputStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('How to generate', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<AiWizardMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: AiWizardMode.ai,
              label: Text('With AI'),
            ),
            ButtonSegment(
              value: AiWizardMode.fromTemplate,
              label: Text('With template'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (set) => _setMode(set.first),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _jobController,
          minLines: 8,
          maxLines: 16,
          decoration: const InputDecoration(
            labelText: 'Job description *',
            alignLabelWithHint: true,
            hintText: 'Paste the Upwork job posting here…',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes / guidance',
            alignLabelWithHint: true,
            hintText:
                'e.g. also mention issues that will reduce income or increase costs',
          ),
        ),
        const SizedBox(height: 16),
        Text('Domain', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AiDomain.values.map((type) {
            final selected = _domain == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) => _setDomain(type),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Projects to mention',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (_projects.isNotEmpty) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedProjectIds
                      ..clear()
                      ..addAll(_projects.map((p) => p.id));
                  });
                },
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: () => setState(_selectedProjectIds.clear),
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
        if (_projectsLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Loading projects…'),
          )
        else if (_projects.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(
                text: 'No projects yet. ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                    ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => context.push('/profile/projects'),
                      child: Text(
                        'Add projects',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' so the AI can mention them.'),
                ],
              ),
            ),
          )
        else
          ..._projects.map((project) {
            final selected = _selectedProjectIds.contains(project.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: selected,
                    onChanged: (value) =>
                        _toggleProject(project.id, value ?? false),
                    title: Text(project.name),
                    subtitle: Text(
                      _projectPreview(project),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selected) ...[
                    CheckboxListTile(
                      contentPadding: const EdgeInsets.only(left: 24),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _describeProjectIds.contains(project.id),
                      onChanged: (value) =>
                          _toggleDescribe(project.id, value ?? false),
                      title: const Text('Describe it'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: TextField(
                        controller: _noteControllerFor(project.id),
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Specific note',
                          alignLabelWithHint: true,
                          hintText:
                              'e.g. how you improved this app\'s security',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 16),
        Text('Language', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ProposalLanguage>(
          segments: ProposalLanguage.values
              .map(
                (l) => ButtonSegment(
                  value: l,
                  label: Text(l.label),
                ),
              )
              .toList(),
          selected: {_language},
          onSelectionChanged: (set) {
            setState(() => _language = set.first);
          },
        ),
        const SizedBox(height: 16),
        if (_fromTemplate && _templates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Text(
              'Add a template first so it can be filled for this job.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                  ),
            ),
          )
        else
          DropdownButtonFormField<String?>(
            key: ValueKey(
              '${_fromTemplate ? 'template' : 'inspire'}-$_selectedTemplateId-${_templates.length}',
            ),
            initialValue: _templates.any((t) => t.id == _selectedTemplateId)
                ? _selectedTemplateId
                : null,
            decoration: InputDecoration(
              labelText: _fromTemplate
                  ? 'Template *'
                  : 'Inspire from template',
            ),
            items: [
              if (!_fromTemplate)
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
              ..._templates.map(
                (template) => DropdownMenuItem<String?>(
                  value: template.id,
                  child: Text(
                    '${template.name} (${template.projectType.label})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTemplateId = value;
                _syncFieldControllers();
              });
            },
          ),
        if (_fromTemplate &&
            _templateBody != null &&
            _fieldControllers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Fill the highlighted fields',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _language == ProposalLanguage.arabic
                ? 'Abs = use as-is. Note = instruction for AI. Tap the label to switch. The field editor keeps the template\'s English frame. The generated draft will be fully Arabic.'
                : 'Abs = use as-is. Note = instruction for AI. Tap the label to switch.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.slate500,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading || _keysNeedingAi.isEmpty
                ? null
                : () => _fillFieldKeys(_keysNeedingAi),
            icon: _loading && _fieldBusyKey == null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(
              _keysNeedingAi.isEmpty
                  ? 'All fields filled'
                  : 'Fill empty with AI (${_keysNeedingAi.length})',
            ),
          ),
          const SizedBox(height: 12),
          InlineTemplatePreview(
            body: _templateBody!,
            controllers: _fieldControllers,
            modes: _fieldModes,
            enabled: !_loading,
            busyKey: _fieldBusyKey,
            onFillField: (token) => _fillFieldKeys([token]),
            onToggleMode: _toggleFieldMode,
            onChanged: () => setState(() {}),
          ),
        ],
      ],
    );
  }

  Widget _buildIssuesStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var index = 0; index < _issues.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          _buildIssueCard(index),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _loading ? null : _showAddIssueDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add issue'),
        ),
      ],
    );
  }

  Widget _buildIssueCard(int index) {
    final issue = _issues[index];
    final titleController = _issueTitleControllers[issue.id]!;
    final whyController = _issueWhyControllers[issue.id]!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: issue.selected,
                  onChanged: (v) {
                    setState(() {
                      _issues[index] =
                          issue.copyWith(selected: v ?? false);
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Issue',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: () {
                    setState(() {
                      _disposeIssueControllers(issue.id);
                      _issues = List<AiIssue>.from(_issues)..removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              child: TextField(
                controller: whyController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Why it matters',
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddIssueDialog() async {
    final titleController = TextEditingController();
    final whyController = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add issue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Issue title *',
                  hintText: 'e.g. High no-show rate cutting revenue',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: whyController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Why it matters (optional)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    final title = titleController.text.trim();
    final why = whyController.text.trim();
    titleController.dispose();
    whyController.dispose();

    if (added != true || title.isEmpty || !mounted) return;

    final issue = AiIssue(
      id: const Uuid().v4(),
      title: title,
      whyItFails: why,
      selected: true,
    );
    _registerIssueControllers(issue);
    setState(() {
      _error = null;
      _issues = [..._issues, issue];
    });
  }

  Widget _buildSolutionsStep() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _solutions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final solution = _solutions[index];
        final controller = _solutionControllers[solution.issueId]!;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solution.issueTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Your offer / solution',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraftStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Review and edit before applying to the proposal form.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.slate500,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _draftController,
          minLines: 14,
          maxLines: 24,
          textDirection: _language == ProposalLanguage.arabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'Proposal body',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _draftController,
          builder: (context, value, _) {
            const previewChars = 250;
            final raw = value.text;
            final preview = raw.isEmpty
                ? 'Generate a draft to see what clients read first.'
                : raw.length <= previewChars
                    ? raw
                    : '${raw.substring(0, previewChars)}…';
            final countLabel = raw.isEmpty
                ? 'Upwork preview (first 250 characters)'
                : 'Upwork preview (first 250 characters) · ${raw.length < previewChars ? raw.length : previewChars}/$previewChars';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  countLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    preview,
                    textDirection: _language == ProposalLanguage.arabic
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.slate700,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= step ? AppColors.teal : AppColors.slate200,
              ),
            ),
          CircleAvatar(
            radius: 11,
            backgroundColor: i <= step ? AppColors.teal : AppColors.slate200,
            foregroundColor: i <= step ? Colors.white : AppColors.slate500,
            child: Text(
              '${i + 1}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
