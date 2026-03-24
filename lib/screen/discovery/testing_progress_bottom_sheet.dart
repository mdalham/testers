import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:testers/services/testing_logic.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/services/upload/image_upload.dart';
import 'package:testers/theme/colors.dart';
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/container/screenshot_upload.dart';
import 'package:testers/widgets/container/testing_feedback_form.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/screen/report/report_screen.dart';

class TestingProgressBottomSheet extends StatefulWidget {
  const TestingProgressBottomSheet({
    super.key,
    required this.appId,
    required this.appName,
    required this.packageName,
    required this.rewardCoins,
    required this.onClaimed,
    required this.username,
    this.scrollController,
    required this.devName,
  });

  final String appId;
  final String appName;
  final String packageName;
  final int rewardCoins;
  final VoidCallback onClaimed;
  final String username;
  final String devName;

  
  final ScrollController? scrollController;

  static Future<void> show({
    required BuildContext context,
    required String appId,
    required String appName,
    required String packageName,
    required int rewardCoins,
    required VoidCallback onClaimed,
    required String username,
    required String developerName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.52,
        minChildSize: 0.30,
        maxChildSize: 0.96,
        expand: false,
        snap: true,
        snapSizes: const [0.55, 0.75, 0.92],
        builder: (_, scrollController) => TestingProgressBottomSheet(
          appId: appId,
          appName: appName,
          packageName: packageName,
          rewardCoins: rewardCoins,
          onClaimed: onClaimed,
          username: username,
          scrollController: scrollController,
          devName: developerName,
        ),
      ),
    );
  }

  @override
  State<TestingProgressBottomSheet> createState() =>
      _TestingProgressBottomSheetState();
}

class _TestingProgressBottomSheetState
    extends State<TestingProgressBottomSheet> {
  
  int _currentStep = 0;
  bool _isClaiming = false;
  bool _stepLoading = false;

  
  File? _screenshotFile;
  String? _screenshotUrl;
  bool _uploadingShot = false;
  String? _uploadError;
  final _uploadService = ImageUploadService();

  
  final _reportCtrl = TextEditingController();
  String? _selectedIssue;

  
  static const _stepLabels = [
    'Open in Play Store',
    'Open the App',
    'Upload Screenshot',
    'Leave Feedback',
  ];

  static const _stepIcons = [
    Icons.storefront_rounded,
    Icons.launch_rounded,
    Icons.add_photo_alternate_rounded,
    Icons.rate_review_rounded,
  ];

  static const _stepDescriptions = [
    'Find the app on Google Play Store and install it.',
    'Open the installed app on your device.',
    'Upload a screenshot proving you tested the app.',
    'Share issue type and testing notes (optional).',
  ];

  
  
  

  Future<void> _handleStepTap(int step) async {
    if (_stepLoading) return;
    switch (step) {
      case 0:
        await TestingLogic.instance.openPlayStore(
          packageName: widget.packageName,
        );
        _advance(step);
      case 1:
        await _tryOpen();
      case 2:
        await _pickScreenshot();
      case 3:
        break;
    }
  }

  void _advance(int step) {
    if (mounted && _currentStep == step) {
      setState(() => _currentStep = step + 1);
    }
  }

  
  
  

  Future<void> _tryOpen() async {
    setState(() => _stepLoading = true);
    final ok = await TestingLogic.instance.tryOpenApp(
      context: context,
      packageName: widget.packageName,
    );
    if (mounted) {
      setState(() => _stepLoading = false);
      if (ok) _advance(1);
    }
  }

  
  
  

  Future<void> _pickScreenshot() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
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
        });
        _advance(2);
      } else {
        setState(() {
          _screenshotFile = null;
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
      if (!mounted) return;
      setState(() {
        _screenshotFile = null;
        _uploadingShot = false;
        _uploadError = 'Something went wrong. Tap to retry.';
      });
    }
  }

  
  
  

  Future<void> _claimCoins() async {
    if (_screenshotUrl == null) {
      CustomSnackbar.show(
        context,
        message: 'Please upload a screenshot first.',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _isClaiming = true);

    await TestingLogic.instance.claimCoins(
      context: context,
      appId: widget.appId,
      appName: widget.appName,
      packageName: widget.packageName,
      rewardCoins: widget.rewardCoins,
      username: widget.username,
      screenshotUrl: _screenshotUrl!, 
      issueType: _selectedIssue, 
      feedbackNote:
          _reportCtrl.text
              .trim()
              .isEmpty 
          ? null
          : _reportCtrl.text.trim(),
      onClaimed: widget.onClaimed,
      onLoadingChanged: () {
        if (mounted) setState(() => _isClaiming = false);
      },
    );

    if (mounted) {
      await context.read<AuthProvider>().refreshUserData();
    }
  }

  @override
  void dispose() {
    _reportCtrl.dispose();
    _uploadService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenshotDone = _screenshotUrl != null;
    final canClaim = _currentStep >= 2 && screenshotDone;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
      ),
      
      child: CustomScrollView(
        
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.science_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.appName,
                              style: tt.titleSmall?.copyWith(fontSize: 17),
                            ),
                            Text(
                              '${widget.rewardCoins} coins reward',
                              style: tt.bodySmall?.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(
                              appId: widget.appId,
                              appName: widget.appName,
                              developerName: widget.devName,
                              sourceType: 'open_tester',
                            ),
                          ),
                        ),
                        child: Icon(Icons.bug_report, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  
                  _ProgressBar(
                    current: _currentStep.clamp(0, _stepLabels.length),
                    total: _stepLabels.length,
                  ),
                  const SizedBox(height: 10),

                  
                  ...List.generate(_stepLabels.length, (i) {
                    final isDone = _currentStep > i;
                    final isActive = _currentStep == i;
                    final isLocked = _currentStep < i;
                    final showLoader = isActive && i == 1 && _stepLoading;

                    Widget? inlineContent;

                    if (i == 2 && (isActive || isDone)) {
                      inlineContent = Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ScreenshotUpload(
                          file: _screenshotFile,
                          uploading: _uploadingShot,
                          uploaded: _screenshotUrl != null,
                          uploadError: _uploadError,
                          onTap: _pickScreenshot,
                        ),
                      );
                    }

                    if (i == 3 && (isActive || isDone)) {
                      inlineContent = Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TestingFeedbackForm(
                          reportCtrl: _reportCtrl,
                          selectedIssue: _selectedIssue,
                          onIssueSelect: (v) =>
                              setState(() => _selectedIssue = v),
                        ),
                      );
                    }

                    return _StepTile(
                      index: i,
                      label: _stepLabels[i],
                      description: _stepDescriptions[i],
                      icon: _stepIcons[i],
                      isDone: isDone,
                      isActive: isActive,
                      isLocked: isLocked,
                      isLoading: showLoader,
                      isOptional: i == 3,
                      inlineContent: inlineContent,
                      onTap: (isActive && !_stepLoading)
                          ? () => _handleStepTap(i)
                          : null,
                    );
                  }),

                  
                  CustomElevatedBtn(
                    label: _isClaiming
                        ? 'Claiming...'
                        : canClaim
                        ? 'Claim ${widget.rewardCoins} Coins'
                        : 'Complete steps to claim',
                    onPressed: canClaim && !_isClaiming ? _claimCoins : null,
                    isLoading: _isClaiming,
                    isFullWidth: true,
                    size: BtnSize.large,
                    borderRadius: 14,
                    backgroundColor: canClaim ? blue : Colors.white12,
                    foregroundColor: canClaim ? Colors.white : Colors.white38,
                    prefixIcon: canClaim
                        ? Icons.redeem_rounded
                        : Icons.lock_outline_rounded,
                    enabled: canClaim && !_isClaiming,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}





class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current, total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : current / total;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current of $total steps completed',
              style: tt.bodySmall?.copyWith(color: cs.primary, fontSize: 12),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: tt.bodySmall?.copyWith(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }
}





class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.label,
    required this.description,
    required this.icon,
    required this.isDone,
    required this.isActive,
    required this.isLocked,
    this.isLoading = false,
    this.isOptional = false,
    this.inlineContent,
    this.onTap,
  });

  final int index;
  final String label, description;
  final IconData icon;
  final bool isDone, isActive, isLocked, isLoading, isOptional;
  final Widget? inlineContent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color iconBg, iconColor, borderColor;
    if (isDone) {
      iconBg = Colors.green.withOpacity(0.15);
      iconColor = Colors.green;
      borderColor = Colors.green.withOpacity(0.3);
    } else if (isActive) {
      iconBg = Colors.blueAccent.withOpacity(0.15);
      iconColor = Colors.blueAccent;
      borderColor = Colors.blueAccent.withOpacity(0.5);
    } else {
      iconBg = cs.primaryContainer.withOpacity(0.3);
      iconColor = cs.onSurface;
      borderColor = cs.outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blueAccent.withOpacity(0.06)
              : cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: iconColor,
                                ),
                              )
                            : Icon(
                                isDone ? Icons.check_rounded : icon,
                                size: 20,
                                color: iconColor,
                              ),
                      ),
                      const SizedBox(width: 12),

                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isDone ? Colors.green : cs.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isOptional) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.outline.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      
                      const SizedBox(width: 8),
                      if (isLoading)
                        const SizedBox.shrink()
                      else if (isDone)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 18,
                        )
                      else if (isActive)
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.blueAccent,
                          size: 14,
                        )
                      else
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white24,
                          size: 16,
                        ),
                    ],
                  ),

                  
                  if (inlineContent != null) inlineContent!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
