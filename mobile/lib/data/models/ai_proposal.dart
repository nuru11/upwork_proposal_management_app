import 'project.dart';

enum AiDomain {
  ecommerce,
  marketplace,
  elearning,
  booking,
  social,
  delivery,
  fintech,
  healthcare,
  gaming,
  restaurant,
  realEstate,
  saas,
  logistics,
  travel,
  fitness,
  agency,
  other;

  String get label => switch (this) {
        AiDomain.ecommerce => 'Ecommerce',
        AiDomain.marketplace => 'Marketplace',
        AiDomain.elearning => 'E-learning',
        AiDomain.booking => 'Booking',
        AiDomain.social => 'Social',
        AiDomain.delivery => 'Delivery',
        AiDomain.fintech => 'Fintech',
        AiDomain.healthcare => 'Healthcare',
        AiDomain.gaming => 'Gaming',
        AiDomain.restaurant => 'Restaurant',
        AiDomain.realEstate => 'Real estate',
        AiDomain.saas => 'SaaS',
        AiDomain.logistics => 'Logistics',
        AiDomain.travel => 'Travel',
        AiDomain.fitness => 'Fitness',
        AiDomain.agency => 'Agency',
        AiDomain.other => 'Other',
      };

  /// Portfolio project type when this AI domain overlaps; otherwise null.
  ProjectType? get matchingProjectType {
    for (final type in ProjectType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}

class AiIssue {
  const AiIssue({
    required this.id,
    required this.title,
    this.whyItFails = '',
    this.selected = true,
  });

  final String id;
  final String title;
  final String whyItFails;
  final bool selected;

  AiIssue copyWith({
    String? id,
    String? title,
    String? whyItFails,
    bool? selected,
  }) {
    return AiIssue(
      id: id ?? this.id,
      title: title ?? this.title,
      whyItFails: whyItFails ?? this.whyItFails,
      selected: selected ?? this.selected,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'whyItFails': whyItFails,
    };
  }

  factory AiIssue.fromJson(Map<String, dynamic> json) {
    return AiIssue(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      whyItFails: json['whyItFails']?.toString() ?? '',
    );
  }
}

class AiSolution {
  const AiSolution({
    required this.issueId,
    required this.issueTitle,
    required this.offer,
  });

  final String issueId;
  final String issueTitle;
  final String offer;

  AiSolution copyWith({
    String? issueId,
    String? issueTitle,
    String? offer,
  }) {
    return AiSolution(
      issueId: issueId ?? this.issueId,
      issueTitle: issueTitle ?? this.issueTitle,
      offer: offer ?? this.offer,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'issueId': issueId,
      'issueTitle': issueTitle,
      'offer': offer,
    };
  }

  factory AiSolution.fromJson(Map<String, dynamic> json) {
    return AiSolution(
      issueId: json['issueId']?.toString() ?? '',
      issueTitle: json['issueTitle']?.toString() ?? '',
      offer: json['offer']?.toString() ?? '',
    );
  }
}

class AiWizardArgs {
  const AiWizardArgs({
    this.initialLanguage,
    this.templateBody,
    this.clientName,
  });

  final String? initialLanguage;
  final String? templateBody;
  final String? clientName;
}

class AiWizardResult {
  const AiWizardResult({required this.body});

  final String body;
}

class AiProjectMention {
  const AiProjectMention({
    required this.project,
    this.describe = false,
    this.mentionNote,
  });

  final Project project;
  final bool describe;
  final String? mentionNote;
}
