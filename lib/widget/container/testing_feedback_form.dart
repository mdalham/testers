// testing_feedback_form.dart
import 'package:flutter/material.dart';
import '../../widget/test field/custom_text_formField.dart';

const _blue = Color(0xFF1565C0);

class TestingFeedbackForm extends StatelessWidget {
  const TestingFeedbackForm({
    super.key,
    required this.reportCtrl,
    required this.selectedIssue,
    required this.onIssueSelect,
    this.issueLabel    = 'Issue Type (optional)',
    this.reportLabel   = 'Testing Report (optional)',
    this.reportHint    = 'e.g. "App crashes on the home screen when…"',
  });

  final TextEditingController      reportCtrl;
  final String?                    selectedIssue;
  final ValueChanged<String?>      onIssueSelect;
  final String                     issueLabel;
  final String                     reportLabel;
  final String                     reportHint;

  static const _issueTypes = [
    (id: 'bug',   icon: Icons.bug_report_rounded,      label: 'Bug'),
    (id: 'ui',    icon: Icons.design_services_rounded,  label: 'UI Problem'),
    (id: 'crash', icon: Icons.warning_amber_rounded,    label: 'App Crash'),
    (id: 'other', icon: Icons.more_horiz_rounded,       label: 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Issue type ────────────────────────────────────────────────────
        _Label(label: issueLabel),
        const SizedBox(height: 10),
        _IssueChips(
          types:    _issueTypes,
          selected: selectedIssue,
          onSelect: onIssueSelect,
        ),

        const SizedBox(height: 10),

        // ── Report text ───────────────────────────────────────────────────
        _Label(label: reportLabel),
        const SizedBox(height: 10),
        CustomTextFormField(
          controller:      reportCtrl,
          hint:            reportHint,
          maxLines:        3,
          keyboardType:    TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          validate:        false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section label
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Issue type chips
// ─────────────────────────────────────────────────────────────────────────────

class _IssueChips extends StatelessWidget {
  const _IssueChips({
    required this.types,
    required this.selected,
    required this.onSelect,
  });

  final List<({String id, IconData icon, String label})> types;
  final String?                                          selected;
  final ValueChanged<String?>                            onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing:    6,
      runSpacing: 6,
      children: types.map((t) {
        final active = selected == t.id;
        return GestureDetector(
          onTap: () => onSelect(active ? null : t.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? _blue.withOpacity(0.12)
                  : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active ? _blue : cs.outline,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon,
                    size:  15,
                    color: active ? _blue : cs.onSurface),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: TextStyle(
                    fontSize:   13,
                    color:      active ? _blue : cs.onSurfaceVariant,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}