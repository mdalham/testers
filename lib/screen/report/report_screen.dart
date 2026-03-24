import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/controllers/height_width.dart';
import 'package:testers/screen/report/report_provider.dart';
import 'package:testers/widget/test%20field/custom_text_formField.dart';
import '../../widget/button/custom_buttons.dart';
import '../../widget/container/screenshot_upload.dart';
import '../../widget/dialog/confirm_dialog.dart';
import '../../widget/snackbar/custom_snackbar.dart';

const _problemTypes = [
  'App Not Found',
  'App Not Opening',
  'App Crashing',
  'App Not Showing in Play Store',
  'Closed Testing Access Problem',
  'Link Not Working',
  'App Not Available in My Country',
  'Unable to Install App',
  'Device Not Supported',
  'Other',
];

class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.appId,
    required this.appName,
    required this.developerName,
    required this.sourceType,
  });

  final String appId;
  final String appName;
  final String developerName;
  final String sourceType;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _provider = ReportProvider.instance;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _provider.resetState();
    super.dispose();
  }

  Future<bool> _checkDuplicate() async {
    final existingId = await _provider.findRecentReport(widget.appId);
    if (existingId == null) return true;

    if (!mounted) return false;

    final proceed = await ConfirmDialog.show(
      context,
      title: 'Already Reported',
      message:
          'You already submitted a report for this app within the last 24 hours.\n\nReport ID: $existingId\n\nDo you still want to submit a new report?',
      confirmLabel: 'Submit Anyway',
      cancelLabel: 'Cancel',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.amber,
    );

    return proceed ?? false;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_provider.screenshotUrl == null) {
      CustomSnackbar.show(
        context,
        message: 'Please upload a screenshot.',
        type: SnackBarType.error,
      );
      return;
    }

    // 24-hour check — may show dialog
    final shouldProceed = await _checkDuplicate();
    if (!shouldProceed || !mounted) return;

    final ok = await _provider.submitReport(
      appId: widget.appId,
      appName: widget.appName,
      developerName: widget.developerName,
      sourceType: widget.sourceType,
    );

    if (!mounted) return;

    if (ok) {
      _descriptionCtrl.clear();
      CustomSnackbar.show(
        context,
        title: 'Report Submitted',
        message: 'Thank you! We will review your report shortly.',
        type: SnackBarType.success,
      );
      Navigator.pop(context);
    } else {
      CustomSnackbar.show(
        context,
        title: 'Submission Failed',
        message:
            _provider.submitError ?? 'Something went wrong. Please try again.',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: ReportProvider.instance,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Report an Issue', style: textTheme.titleLarge),
        ),
        body: Consumer<ReportProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AppInfoPill(
                      appName: widget.appName,
                      developerName: widget.developerName,
                      sourceType: widget.sourceType,
                    ),
                    SizedBox(height: bottomPadding),

                    _SectionCard(
                      stepNumber: '1',
                      title: 'Select Problem Type',
                      child: _ProblemTypeDropdown(provider: provider),
                    ),
                    SizedBox(height: bottomPadding),

                    _SectionCard(
                      stepNumber: '2',
                      title: 'Upload Screenshot',
                      subtitle: 'Required — show what you experienced',
                      child: Column(
                        children: [
                          ScreenshotUpload(
                            file: provider.screenshotFile,
                            uploading: provider.uploadingShot,
                            uploaded: provider.screenshotUrl != null,
                            uploadError: provider.uploadError,
                            onTap: provider.pickAndUploadScreenshot,
                          ),
                          if (provider.screenshotUrl == null &&
                              provider.screenshotFile == null &&
                              provider.uploadError == null &&
                              !provider.uploadingShot) ...[
                            const SizedBox(height: 6),
                            const _ValidationHint(
                              text: 'Screenshot is required',
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: bottomPadding),

                    _SectionCard(
                      stepNumber: '3',
                      title: 'Describe the Issue',
                      subtitle: 'Minimum 10 characters',
                      child: CustomTextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 5,
                        minLines: 3,
                        hint: 'Please describe problem clearly',
                        onChanged: provider.setDescription,
                        validators: [
                          FieldValidator.required('Description is required'),
                          FieldValidator.minLength(
                            10,
                            'Minimum 10 characters required',
                          ),
                        ],
                      ),
                    ),

                    if (provider.isFormValid) ...[
                      SizedBox(height: bottomPadding + 10),
                      CustomElevatedBtn(
                        label: 'Submit Report',
                        isFullWidth: true,
                        size: BtnSize.large,
                        isLoading: provider.isLoading,
                        prefixIcon: Icons.send_rounded,
                        onPressed: _submit,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppInfoPill extends StatelessWidget {
  const _AppInfoPill({
    required this.appName,
    required this.developerName,
    required this.sourceType,
  });

  final String appName, developerName, sourceType;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isOpen = sourceType == 'open_tester';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bug_report_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'by $developerName',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.stepNumber,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String stepNumber, title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(baseBorderRadius),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Problem type dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _ProblemTypeDropdown extends StatelessWidget {
  const _ProblemTypeDropdown({required this.provider});
  final ReportProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DropdownButtonFormField<String>(
      value: provider.selectedProblemType,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      hint: const Text('Select problem type'),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
        filled: true,
        fillColor: cs.primaryContainer,
      ),
      items: _problemTypes
          .map(
            (t) => DropdownMenuItem(
              value: t,
              child: Text(t, style: textTheme.titleSmall),
            ),
          )
          .toList(),
      onChanged: provider.setProblemType,
      validator: (v) => v == null ? 'Please select a problem type' : null,
    );
  }
}

class _ValidationHint extends StatelessWidget {
  const _ValidationHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.info_outline_rounded, size: 13, color: Colors.redAccent),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.redAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
