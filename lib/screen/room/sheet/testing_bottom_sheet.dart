import 'dart:async';
import 'dart:io';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/widgets/test%20field/custom_text_formField.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:testers/services/upload/image_upload.dart';
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/container/animated_expandable_card.dart';
import '../../../models/room_model.dart';
import '../../../services/ads/unity_interstitial_service.dart';
import '../../../services/room_service.dart';

const _deepBlue = Color(0xFF1A237E);
const _blue = Color(0xFF1565C0);
const _orange = Color(0xFFFF9800);
const _green = Color(0xFF2E7D32);

void showTestingSheet(
  BuildContext context, {
  required String groupId,
  required String uid,
  required String username,
  required String targetUserId,
  required String targetName,
  required AppDetails appDetails,
  required DateTime taskStartDate,
  required VoidCallback onSubmitted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => _TestingSheet(
      groupId: groupId,
      uid: uid,
      username: username,
      targetUserId: targetUserId,
      targetName: targetName,
      appDetails: appDetails,
      taskStartDate: taskStartDate,
      onSubmitted: onSubmitted,
    ),
  );
}

class _TestingSheet extends StatefulWidget {
  const _TestingSheet({
    required this.groupId,
    required this.uid,
    required this.username,
    required this.targetUserId,
    required this.targetName,
    required this.appDetails,
    required this.taskStartDate,
    required this.onSubmitted,
  });

  final String groupId;
  final String uid;
  final String username;
  final String targetUserId;
  final String targetName;
  final AppDetails appDetails;
  final DateTime taskStartDate;
  final VoidCallback onSubmitted;

  @override
  State<_TestingSheet> createState() => _TestingSheetState();
}

class _TestingSheetState extends State<_TestingSheet>
    with WidgetsBindingObserver {
  bool _installed = false;
  bool _appOpened = false;

  bool _timerRunning = false;
  bool _timerComplete = false;
  int _secondsLeft = 30;
  Timer? _usageTimer;
  Timer? _pollTimer;
  DateTime? _openedAt;

  File? _screenshotFile;
  String? _screenshotUrl;
  bool _uploadingShot = false;
  String? _uploadError;
  final _uploadService = ImageUploadService();

  final _reportCtrl = TextEditingController();
  String? _selectedIssue;

  bool _submitting = false;

  static const _kAdCooldownKey = 'interstitial_last_shown_ms';
  static const _kCooldownMinutes = 10;

  static const _issueTypes = [
    (id: 'bug', icon: Icons.bug_report_rounded, label: 'Bug'),
    (id: 'ui', icon: Icons.design_services_rounded, label: 'UI Problem'),
    (id: 'crash', icon: Icons.warning_amber_rounded, label: 'App Crash'),
    (id: 'other', icon: Icons.more_horiz_rounded, label: 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInstall();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInstall();
      if (_appOpened && _openedAt != null && !_timerComplete) {
        final elapsed = DateTime.now().difference(_openedAt!).inSeconds;
        if (elapsed >= 30) _finishTimer();
      }
    }
    if (state == AppLifecycleState.paused && _appOpened) {
      _openedAt ??= DateTime.now();
    }
  }

  Future<bool> _canShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_kAdCooldownKey) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastShown;
    return elapsed >= const Duration(minutes: _kCooldownMinutes).inMilliseconds;
  }

  Future<void> _recordAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAdCooldownKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _checkInstall() async {
    try {
      final ok = await LaunchApp.isAppInstalled(
        androidPackageName: widget.appDetails.packageName,
      );
      if (mounted && ok != _installed) setState(() => _installed = ok);
    } catch (_) {}
  }

  Future<void> _openPlayStore() async {
    final pkg = widget.appDetails.packageName;
    final marketUri = Uri.parse('market://details?id=$pkg');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$pkg',
    );
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _checkInstall(),
        );
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Play Store: $e');
    }
  }

  Future<void> _openApp() async {
    try {
      await LaunchApp.openApp(
        androidPackageName: widget.appDetails.packageName,
      );
    } catch (_) {
      final uri = Uri.parse('android-app://${widget.appDetails.packageName}');
      if (await canLaunchUrl(uri)) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (!_appOpened) {
      setState(() {
        _appOpened = true;
        _timerRunning = true;
      });
      _openedAt = DateTime.now();
      _startUsageTimer();
    }
  }

  void _startUsageTimer() {
    _secondsLeft = 30;
    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          _finishTimer();
        }
      });
    });
  }

  void _finishTimer() {
    _usageTimer?.cancel();
    setState(() {
      _timerComplete = true;
      _timerRunning = false;
      _secondsLeft = 0;
    });
  }

  Future<void> _pickScreenshot() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _screenshotFile = File(picked.path);
        _uploadingShot = true;
        _screenshotUrl = null;
        _uploadError = null;
      });

      final result = await _uploadService.uploadImage(_screenshotFile!);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _screenshotUrl = result.imageUrl;
          _uploadingShot = false;
          _uploadError = null;
        });
      } else {
        setState(() {
          _screenshotFile = null;
          _screenshotUrl = null;
          _uploadingShot = false;
          _uploadError = result.errorMessage ?? 'Upload failed. Tap to retry.';
        });
        CustomSnackbar.show(
          context,
          message: 'Upload failed. Tap to retry.',
          type: SnackBarType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _screenshotFile = null;
          _uploadingShot = false;
          _uploadError = 'Something went wrong. Tap to retry.';
        });
        CustomSnackbar.show(
          context,
          message: 'Something went wrong. Tap to retry.',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_screenshotUrl == null || _screenshotUrl!.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Please upload a screenshot before submitting.',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _submitting = true);

    final adReady = UnityInterstitialService.instance.isAdReady;
    final cooldownOk = await _canShowAd();

    if (adReady && cooldownOk) {
      UnityInterstitialService.instance.showInterstitialAd(
        onCompleted: () async {
          await _recordAdShown();
          await _runSubmitUpload();
        },
        onFailed: () async {
          await _runSubmitUpload();
        },
      );
    } else {
      await _runSubmitUpload();
    }
  }

  Future<void> _runSubmitUpload() async {
    final error = await RoomService.instance.uploadProof(
      groupId: widget.groupId,
      uid: widget.uid,
      username: widget.username,
      targetUserId: widget.targetUserId,
      screenshotUrl: _screenshotUrl!,
      taskStartDate: widget.taskStartDate,
      issueType: _selectedIssue,
      reportText: _reportCtrl.text.trim().isEmpty
          ? null
          : _reportCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      CustomSnackbar.show(
        context,
        message: 'Something went wrong',
        type: SnackBarType.error,
      );
    } else {
      widget.onSubmitted();
      Navigator.pop(context);
      CustomSnackbar.show(
        context,
        message: 'Testing submitted successfully!',
        type: SnackBarType.success,
      );
    }
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    _pollTimer?.cancel();
    _reportCtrl.dispose();
    _uploadService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.75, 0.95],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.appDetails.appName,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.bug_report),
                      style: IconButton.styleFrom(backgroundColor: cs.surface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(10),
                  children: [
                    AnimatedExpandableCard(
                      icon: Icons.apps_rounded,
                      title: 'App details',
                      iconColor: _blue,
                      accentColor: _blue,
                      collapsedTrailing: [
                        _SmallChip(
                          label: widget.appDetails.appName,
                          icon: Icons.smartphone_rounded,
                          color: _blue,
                        ),
                      ],
                      children: [
                        _AppDetailsContent(
                          appDetails: widget.appDetails,
                          targetName: widget.targetName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedExpandableCard(
                      icon: Icons.info_outline_rounded,
                      title: 'App description',
                      iconColor: cs.onSurfaceVariant,
                      accentColor: _blue,
                      initiallyExpanded: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'Please explore the app and try to find any bugs or issues.\n'
                            '${widget.appDetails.description}',
                            style: tt.bodyMedium?.copyWith(height: 1.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _OpenAppButton(
                      installed: _installed,
                      onOpen: _openApp,
                      onInstall: _openPlayStore,
                    ),
                    const SizedBox(height: 10),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      child: _appOpened
                          ? _TimerCard(
                              timerComplete: _timerComplete,
                              secondsLeft: _secondsLeft,
                            )
                          : _HintText(installed: _installed),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOutCubic,
                      child: _timerComplete
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                Divider(height: 1, color: cs.outline),
                                const SizedBox(height: 10),
                                _SectionLabel(label: 'Upload Screenshot'),
                                const SizedBox(height: 10),
                                _ScreenshotPicker(
                                  file: _screenshotFile,
                                  uploading: _uploadingShot,
                                  uploaded: _screenshotUrl != null,
                                  uploadError: _uploadError,
                                  onTap: _pickScreenshot,
                                ),
                                const SizedBox(height: 10),
                                _SectionLabel(label: 'Issue Type (optional)'),
                                const SizedBox(height: 10),
                                _IssueTypeChips(
                                  types: _issueTypes,
                                  selected: _selectedIssue,
                                  onSelect: (v) =>
                                      setState(() => _selectedIssue = v),
                                ),
                                const SizedBox(height: 10),
                                _SectionLabel(
                                  label: 'Testing Report (optional)',
                                ),
                                const SizedBox(height: 10),
                                CustomTextFormField(
                                  controller: _reportCtrl,
                                  hint:
                                      'e.g. "App crashes on the home screen when…"',
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  validate: false,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomOutlineBtn(
                                        label: 'Cancel',
                                        onPressed: _submitting
                                            ? null
                                            : () => Navigator.pop(context),
                                        isFullWidth: true,
                                        size: BtnSize.large,
                                        borderRadius: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 2,
                                      child: CustomElevatedBtn(
                                        label: _submitting
                                            ? 'Submitting…'
                                            : 'Submit',
                                        onPressed: _submitting ? null : _submit,
                                        prefixIcon: Icons.check_circle_rounded,
                                        backgroundColor: Colors.green,
                                        isFullWidth: true,
                                        isLoading: _submitting,
                                        size: BtnSize.large,
                                        borderRadius: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppDetailsContent extends StatelessWidget {
  const _AppDetailsContent({
    required this.appDetails,
    required this.targetName,
  });
  final AppDetails appDetails;
  final String targetName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 70,
                  height: 70,
                  color: cs.surfaceContainerHigh,
                  child: appDetails.iconUrl.isNotEmpty
                      ? Image.network(
                          appDetails.iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _IconFallback(name: appDetails.appName),
                        )
                      : _IconFallback(name: appDetails.appName),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(
                      label: 'App name:',
                      value: appDetails.appName,
                      bold: true,
                    ),
                    const SizedBox(height: 5),
                    _DetailRow(label: 'Developed by:', value: targetName),
                    const SizedBox(height: 5),
                    _DetailRow(
                      label: 'Package:',
                      value: appDetails.packageName,
                      small: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outline, thickness: 1),
        InkWell(
          onTap: () async {
            final uri = Uri.parse(
              'https://play.google.com/store/apps/details?id=${appDetails.packageName}',
            );
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Text(
                  'Play Store',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'View on Play Store',
                  style: tt.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.small = false,
  });
  final String label;
  final String value;
  final bool bold;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: base?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: base?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: .end,
          ),
        ),
      ],
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    color: _deepBlue.withOpacity(0.1),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _deepBlue,
      ),
    ),
  );
}

class _OpenAppButton extends StatelessWidget {
  const _OpenAppButton({
    required this.installed,
    required this.onOpen,
    required this.onInstall,
  });
  final bool installed;
  final VoidCallback onOpen;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) => CustomElevatedBtn(
    label: installed ? 'Open App' : 'Install App',
    onPressed: installed ? onOpen : onInstall,
    prefixIcon: installed ? Icons.open_in_new_rounded : Icons.download_rounded,
    backgroundColor: _blue,
    isFullWidth: true,
    size: BtnSize.large,
    borderRadius: 14,
  );
}

class _HintText extends StatelessWidget {
  const _HintText({required this.installed});
  final bool installed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        installed
            ? 'Tap the button above to open the app.\nYou must keep it open for at least 30 seconds.'
            : 'Install the app first, then tap Open App\nto begin the 30 second testing timer.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.55,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.timerComplete, required this.secondsLeft});
  final bool timerComplete;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    if (timerComplete) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green, width: 1.5),
        ),
        child: Center(
          child: Text(
            '30 Seconds Completed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _green,
            ),
          ),
        ),
      );
    }

    final progress = (30 - secondsLeft) / 30;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withOpacity(0.65), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏳ ', style: TextStyle(fontSize: 14)),
              Text(
                'Keep App Open',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _orange.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${secondsLeft}s remaining',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _orange,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: _orange,
              backgroundColor: _orange.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotPicker extends StatelessWidget {
  const _ScreenshotPicker({
    required this.file,
    required this.uploading,
    required this.uploaded,
    required this.onTap,
    this.uploadError,
  });

  final File? file;
  final bool uploading;
  final bool uploaded;
  final String? uploadError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasError = uploadError != null && !uploading && !uploaded;
    final hasPreview = file != null;

    Color borderColor = cs.outlineVariant.withOpacity(0.5);
    if (uploaded) borderColor = _green;
    if (hasError) borderColor = Colors.red.withOpacity(0.6);
    if (uploading) borderColor = _blue.withOpacity(0.4);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: uploaded ? 1.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildBody(context, cs, tt, hasError, hasPreview),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    bool hasError,
    bool hasPreview,
  ) {
    if (uploading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _blue,
                    backgroundColor: _blue.withOpacity(0.12),
                  ),
                ),
                Icon(Icons.cloud_upload_rounded, size: 22, color: _blue),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Uploading screenshot…',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Please wait',
              style: tt.labelSmall?.copyWith(color: cs.onPrimary),
            ),
          ],
        ),
      );
    }

    if (hasPreview) {
      return Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.file(file!, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: _StatusBadge(uploaded: uploaded),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              children: [
                Icon(
                  uploaded
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size: 14,
                  color: uploaded ? Colors.greenAccent : Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    uploaded
                        ? 'Screenshot uploaded successfully'
                        : 'Processing upload…',
                    style: TextStyle(
                      fontSize: 11,
                      color: uploaded ? Colors.greenAccent : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 10,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change',
                        style: tt.bodySmall!.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 26,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upload Failed',
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              uploadError!,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tap to retry',
                    style: tt.labelMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.07),
              shape: BoxShape.circle,
              border: Border.all(color: _blue.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(
              Icons.add_photo_alternate_rounded,
              size: 30,
              color: _blue.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tap to upload screenshot',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'PNG or JPG',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HintPill(icon: Icons.image_rounded, label: 'Gallery'),
              const SizedBox(width: 8),
              _HintPill(
                icon: Icons.cloud_upload_outlined,
                label: 'Auto-upload',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.uploaded});
  final bool uploaded;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: uploaded
          ? _green.withOpacity(0.85)
          : Colors.black.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          uploaded ? Icons.check_circle_rounded : Icons.pending_rounded,
          size: 12,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          uploaded ? 'Uploaded' : 'Uploading…',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueTypeChips extends StatelessWidget {
  const _IssueTypeChips({
    required this.types,
    required this.selected,
    required this.onSelect,
  });
  final List<({String id, IconData icon, String label})> types;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((t) {
        final active = selected == t.id;
        return GestureDetector(
          onTap: () => onSelect(active ? null : t.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: active ? _blue.withOpacity(0.12) : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active ? _blue : cs.outline,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 15, color: active ? _blue : cs.onSurface),
                const SizedBox(width: 6),
                Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? _blue : cs.onPrimary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
