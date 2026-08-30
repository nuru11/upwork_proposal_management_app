import 'package:flutter/material.dart';

import '../../shared/template_placeholders.dart';
import '../../shared/theme/app_theme.dart';

enum FieldFillMode { absolute, note }

class InlineTemplatePreview extends StatelessWidget {
  const InlineTemplatePreview({
    super.key,
    required this.body,
    required this.controllers,
    required this.modes,
    this.enabled = true,
    this.busyKey,
    this.onFillField,
    this.onToggleMode,
    this.onChanged,
  });

  final String body;
  final Map<String, TextEditingController> controllers;
  final Map<String, FieldFillMode> modes;
  final bool enabled;
  final String? busyKey;
  final ValueChanged<String>? onFillField;
  final ValueChanged<String>? onToggleMode;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final paragraphs = <List<InlineSpan>>[];
    var current = <InlineSpan>[];

    void flush() {
      if (current.isEmpty) return;
      paragraphs.add(current);
      current = <InlineSpan>[];
    }

    for (final segment in splitTemplate(body)) {
      if (segment is TemplateTextSegment) {
        final parts = segment.text.split('\n');
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            current.add(TextSpan(text: parts[i]));
          }
          if (i < parts.length - 1) flush();
        }
      } else if (segment is TemplateFieldSegment) {
        final token = segment.token;
        final controller = controllers[token];
        if (controller == null) {
          current.add(TextSpan(text: token));
          continue;
        }
        current.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _InlineField(
              controller: controller,
              label: placeholderLabel(token),
              mode: modes[token] ?? FieldFillMode.absolute,
              enabled: enabled,
              busy: busyKey == token,
              onFill: onFillField == null ? null : () => onFillField!(token),
              onToggleMode:
                  onToggleMode == null ? null : () => onToggleMode!(token),
              onChanged: onChanged,
            ),
          ),
        );
      }
    }
    flush();

    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.7,
          color: AppColors.ink,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final spans in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(style: style, children: spans),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    required this.label,
    required this.mode,
    required this.enabled,
    required this.busy,
    this.onFill,
    this.onToggleMode,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final FieldFillMode mode;
  final bool enabled;
  final bool busy;
  final VoidCallback? onFill;
  final VoidCallback? onToggleMode;
  final VoidCallback? onChanged;

  bool get _isNote => mode == FieldFillMode.note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 108, maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: enabled ? onToggleMode : null,
              child: Text(
                _isNote ? 'Note' : 'Abs',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _isNote ? AppColors.amber : AppColors.teal,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodySmall,
              onChanged: (_) => onChanged?.call(),
              decoration: InputDecoration(
                isDense: true,
                hintText: _isNote ? 'Instruction…' : label,
                hintMaxLines: 2,
                filled: true,
                fillColor:
                    _isNote ? AppColors.amberSoft : AppColors.tealSoft,
                contentPadding: const EdgeInsets.fromLTRB(8, 6, 28, 6),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                suffixIcon: busy
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Fill with AI',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: enabled ? onFill : null,
                        icon: const Icon(Icons.auto_awesome_outlined),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
