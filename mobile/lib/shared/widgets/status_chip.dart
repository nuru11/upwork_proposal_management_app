import 'package:flutter/material.dart';

import '../../data/models/proposal.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ProposalStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.statusColor(status);
    final bg = AppTheme.statusSoftColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key, required this.language});

  final ProposalLanguage language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        language.label,
        style: const TextStyle(
          color: AppColors.slate700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class ProjectTypeChip extends StatelessWidget {
  const ProjectTypeChip({
    super.key,
    required this.projectType,
    this.compact = false,
  });

  final ProposalProjectType projectType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        projectType.label,
        style: TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}
