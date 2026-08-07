import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/ai_proposal.dart';
import '../../data/models/project.dart';
import '../../data/models/proposal.dart';
import '../../data/remote/api_client.dart';
import '../../providers/providers.dart';
import '../../shared/theme/app_theme.dart';

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

  ProjectType _domain = ProjectType.marketplace;
  ProposalLanguage _language = ProposalLanguage.english;
  bool _useTemplate = false;

  List<AiIssue> _issues = [];
  final Map<String, TextEditingController> _issueTitleControllers = {};
  final Map<String, TextEditingController> _issueWhyControllers = {};
  List<AiSolution> _solutions = [];
  final Map<String, TextEditingController> _solutionControllers = {};

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    if (args?.initialLanguage != null) {
      _language = ProposalLanguage.fromStorage(args!.initialLanguage!);
    }
    if (args?.templateBody != null && args!.templateBody!.trim().isNotEmpty) {
      _useTemplate = true;
    }
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
    super.dispose();
  }

  String? get _templateBody {
    if (!_useTemplate) return null;
    final body = widget.args?.templateBody?.trim();
    if (body == null || body.isEmpty) return null;
    return body;
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
      final allProjects =
          await ref.read(projectRepositoryProvider).getAll(type: _domain);
      final matching = allProjects;

      final body = await ref.read(aiApiProvider).draftProposal(
            jobDescription: _jobController.text.trim(),
            domain: _domain.name,
            language: _language.name,
            issues: selected,
            solutions: solutions,
            projects: matching,
            templateBody: _templateBody,
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

  String get _stepTitle => switch (_step) {
        0 => 'Job & domain',
        1 => 'Common issues',
        2 => 'Solutions to offer',
        3 => 'Proposal draft',
        _ => 'AI wizard',
      };

  @override
  Widget build(BuildContext context) {
    final hasTemplate = (widget.args?.templateBody?.trim().isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _StepIndicator(step: _step),
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
                0 => _buildInputStep(hasTemplate: hasTemplate),
                1 => _buildIssuesStep(),
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

  String get _primaryLabel => switch (_step) {
        0 => 'Extract issues',
        1 => 'Suggest solutions',
        2 => 'Generate draft',
        _ => 'Use draft',
      };

  VoidCallback get _primaryAction => switch (_step) {
        0 => _extractIssues,
        1 => _suggestSolutions,
        2 => _draftProposal,
        _ => _useDraft,
      };

  Widget _buildInputStep({required bool hasTemplate}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
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
          children: ProjectType.values.map((type) {
            final selected = _domain == type;
            return ChoiceChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (_) => setState(() => _domain = type),
            );
          }).toList(),
        ),
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
        if (hasTemplate) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use current template style'),
            subtitle: const Text(
              'Match tone/structure of the template selected on the form',
            ),
            value: _useTemplate,
            onChanged: (v) => setState(() => _useTemplate = v),
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
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Job', 'Issues', 'Solutions', 'Draft'];
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
