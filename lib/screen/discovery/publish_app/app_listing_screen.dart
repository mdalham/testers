import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/discovery/publish_app/step1_app_setup.dart';
import 'package:testers/screen/discovery/publish_app/step2_terms_availability.dart';
import 'package:testers/screen/discovery/publish_app/step3_app_details.dart';
import 'package:testers/screen/discovery/publish_app/step4_tester_selection.dart';
import 'package:testers/screen/discovery/publish_app/step5_success.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/constants/info.dart';
import 'package:testers/services/ads/unity_interstitial_service.dart';
import 'package:testers/services/firebase/CoinTransaction/coin_transaction_service.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/widgets/button/custom_buttons.dart';
import 'package:testers/widgets/badge/coin_badge.dart';
import 'package:testers/widgets/snackbar/custom_snackbar.dart';
import 'package:testers/screen/discovery/provider/discount_provider.dart';
import 'package:testers/screen/discovery/provider/publish_provider.dart';

enum PublishFlowMode { publish, edit, republish }

extension PublishFlowModeX on PublishFlowMode {
  String get title {
    switch (this) {
      case PublishFlowMode.publish:   return 'Publish App';
      case PublishFlowMode.edit:      return 'Edit App';
      case PublishFlowMode.republish: return 'Republish App';
    }
  }
  int get startStep {
    switch (this) {
      case PublishFlowMode.publish:   return 0;
      case PublishFlowMode.edit:      return 0;
      case PublishFlowMode.republish: return 0;
    }
  }
  int get actionStep {
    switch (this) {
      case PublishFlowMode.publish:   return 3;
      case PublishFlowMode.edit:      return 3;
      case PublishFlowMode.republish: return 3;
    }
  }
  String get actionLabel {
    switch (this) {
      case PublishFlowMode.publish:   return 'Publish';
      case PublishFlowMode.edit:      return 'Save Changes';
      case PublishFlowMode.republish: return 'Republish';
    }
  }
}

const _kTotalSteps = 5;
const _kStepLabels = ['Setup', 'Terms', 'Details', 'Testers', 'Done'];
const _kStepIcons  = [
  Icons.settings_rounded,
  Icons.gavel_rounded,
  Icons.info_outline_rounded,
  Icons.group_rounded,
  Icons.check_circle_rounded,
];

class AppListingScreen extends StatefulWidget {
  const AppListingScreen({
    super.key,
    this.mode  = PublishFlowMode.publish,
    this.docId,
  });

  final PublishFlowMode mode;
  final String?         docId;

  @override
  State<AppListingScreen> createState() => _CreatePublishFlowScreenState();
}

class _CreatePublishFlowScreenState extends State<AppListingScreen> {
  late int _currentStep;
  bool     _isAdPending = false;

  String? get _docId =>
      widget.docId ?? (ModalRoute.of(context)?.settings.arguments as String?);

  bool get _isOnSuccessStep => _currentStep == _kTotalSteps - 1;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.mode.startStep;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUserData();
      UnityInterstitialService.instance.reloadAds();

      
      if (widget.mode == PublishFlowMode.publish) {
        context.read<PublishProvider>().reset();
      }
    });
  }

  

  void _goBack() {
    if (_currentStep <= widget.mode.startStep) {
      Navigator.pop(context);
      return;
    }
    setState(() => _currentStep--);
  }

  Future<void> _goNext() async {
    final p = context.read<PublishProvider>();
    if (!p.isStepValid(_currentStep)) return;
    if (_currentStep == 2 && !_validateStep3()) return;
    if (_currentStep == widget.mode.actionStep) {
      await _triggerAction();
      return;
    }
    if (_currentStep < _kTotalSteps - 2) {
      setState(() => _currentStep++);
    }
  }

  

  bool _validateStep3() {
    final p = context.read<PublishProvider>();
    if (p.step3AppName.trim().isEmpty)     { _err('App name is required.');       return false; }
    if (p.step3Developer.trim().isEmpty)   { _err('Developer name is required.'); return false; }
    if (p.step3PackageName.trim().isEmpty) { _err('Package name is required.');   return false; }
    if (!RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,}$')
        .hasMatch(p.step3PackageName.trim())) {
      _err('Package name must follow com.example.app format.');
      return false;
    }
    if (p.uploadedIconUrl == null || p.uploadedIconUrl!.isEmpty) {
      _err('Please upload an app icon before continuing.');
      return false;
    }
    return true;
  }

  

  Future<void> _triggerAction() async {
    final p        = context.read<PublishProvider>();
    final auth     = context.read<AuthProvider>();
    final discount = context.read<DiscountProvider>();

    
    if (widget.mode == PublishFlowMode.publish) {
      final finalCost = discount.discountedCost(p.totalCoinsRequired);
      if (auth.coins < finalCost) {
        _err('You need $finalCost coins but only have ${auth.coins}.');
        return;
      }
    }

    
    if (widget.mode == PublishFlowMode.edit) {
      if (auth.coins < PublishConstants.editCoinCost) {
        _err('You need ${PublishConstants.editCoinCost} coins but only have ${auth.coins}.');
        return;
      }
    }

    

    setState(() => _isAdPending = true);
    UnityInterstitialService.instance.showInterstitialAd(
      onCompleted: _doAction,
      onFailed:    _doAction,
    );
  }

  Future<void> _doAction() async {
    if (!mounted) return;
    setState(() => _isAdPending = false);
    switch (widget.mode) {
      case PublishFlowMode.publish:   await _doPublish();
      case PublishFlowMode.edit:      await _doEdit();
      case PublishFlowMode.republish: await _doRepublish();
    }
  }

  Future<void> _doPublish() async {
    final p        = context.read<PublishProvider>();
    final auth     = context.read<AuthProvider>();
    final discount = context.read<DiscountProvider>();

    
    final coinCost = discount.discountedCost(p.totalCoinsRequired);

    final ok = await p.publishApp(
      appName:       p.step3AppName.trim(),
      developerName: p.step3Developer.trim(),
      packageName:   p.step3PackageName.trim(),
      iconUrl:       p.uploadedIconUrl!,
      coinCost:      coinCost,           
      description:   p.step3Description.trim().isEmpty
          ? null
          : p.step3Description.trim(),
    );
    if (!mounted) return;
    if (ok) {
      await CoinTransactionService.instance.logTransaction(
        userId:   auth.uid,
        username: auth.username,
        amount:   -coinCost,             
        type:     CoinTxType.publishNormal,
        note:     p.step3AppName.trim(),
      );
      await auth.refreshUserData();
      setState(() => _currentStep = _kTotalSteps - 1);
    } else {
      _err(p.error ?? 'Something went wrong.');
    }
  }

  Future<void> _doEdit() async {
    final docId = _docId;
    if (docId == null) { _err('No app selected for editing.'); return; }

    final p    = context.read<PublishProvider>();
    final auth = context.read<AuthProvider>();

    final ok = await p.updateApp(
      docId:         docId,
      appName:       p.step3AppName.trim(),
      developerName: p.step3Developer.trim(),
      packageName:   p.step3PackageName.trim(),
      iconUrl:       p.uploadedIconUrl!,
      description:   p.step3Description.trim().isEmpty
          ? null
          : p.step3Description.trim(),
      isRepublish: false,
      coinCost:    PublishConstants.editCoinCost, 
    );
    if (!mounted) return;
    if (ok) {
      await CoinTransactionService.instance.logTransaction(
        userId:   auth.uid,
        username: auth.username,
        amount:   -PublishConstants.editCoinCost,
        type:     CoinTxType.editApp,
        note:     p.step3AppName.trim(),
      );
      await auth.refreshUserData();
      setState(() => _currentStep = _kTotalSteps - 1);
    } else {
      _err(p.error ?? 'Could not save changes.');
    }
  }

  Future<void> _doRepublish() async {
    final docId = _docId;
    if (docId == null) { _err('No app selected for republishing.'); return; }

    final p        = context.read<PublishProvider>();
    final auth     = context.read<AuthProvider>();
    final discount = context.read<DiscountProvider>();

    
    final storedMaxTesters = await p.fetchStoredMaxTesters(docId);
    if (!mounted) return;
    if (storedMaxTesters == null) {
      _err('Could not load app data for republishing.');
      return;
    }

    
    final baseCost = storedMaxTesters * kCoinsPerTester;
    final coinCost = discount.discountedCost(baseCost);

    if (auth.coins < coinCost) {
      _err('You need $coinCost coins but only have ${auth.coins}.');
      return;
    }

    final ok = await p.updateApp(
      docId:         docId,
      appName:       p.step3AppName.trim(),
      developerName: p.step3Developer.trim(),
      packageName:   p.step3PackageName.trim(),
      iconUrl:       p.uploadedIconUrl!,
      description:   p.step3Description.trim().isEmpty
          ? null
          : p.step3Description.trim(),
      isRepublish:   true,
      coinCost:      coinCost,           
      newMaxTesters: storedMaxTesters,   
    );
    if (!mounted) return;
    if (ok) {
      await CoinTransactionService.instance.logTransaction(
        userId:   auth.uid,
        username: auth.username,
        amount:   -coinCost,             
        type:     CoinTxType.republishNormal,
        note:     p.step3AppName.trim(),
      );
      await auth.refreshUserData();
      setState(() => _currentStep = _kTotalSteps - 1);
    } else {
      _err(p.error ?? 'Could not republish.');
    }
  }

  

  void _err(String msg) => CustomSnackbar.show(
      context, title: 'Error', message: msg, type: SnackBarType.error);

  String get _continueLabel {
    if (_isAdPending) return 'Please wait...';
    if (_currentStep == widget.mode.actionStep) return widget.mode.actionLabel;
    return 'Continue';
  }

  IconData get _continueIcon {
    if (_currentStep == widget.mode.actionStep) {
      return widget.mode == PublishFlowMode.edit
          ? Icons.check_rounded
          : Icons.rocket_launch_rounded;
    }
    return Icons.arrow_forward_rounded;
  }

  bool _canProceed(PublishProvider p, AuthProvider auth, DiscountProvider discount) {
    if (!p.isStepValid(_currentStep)) return false;

    
    if (_currentStep == widget.mode.actionStep &&
        widget.mode == PublishFlowMode.publish) {
      return auth.coins >= discount.discountedCost(p.totalCoinsRequired);
    }

    
    if (_currentStep == widget.mode.actionStep &&
        widget.mode == PublishFlowMode.edit) {
      return auth.coins >= PublishConstants.editCoinCost;
    }

    
    
    return true;
  }

  

  @override
  Widget build(BuildContext context) {
    final p          = context.watch<PublishProvider>();
    final auth       = context.watch<AuthProvider>();
    final discount   = context.watch<DiscountProvider>();
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final isLoading  = p.isLoading || _isAdPending;
    final canProceed = _canProceed(p, auth, discount);

    if (_isOnSuccessStep) return const Step5Success();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor:        cs.surface,
        surfaceTintColor:       Colors.transparent,
        elevation:              0,
        scrolledUnderElevation: 1,
        title: Text(widget.mode.title, style: tt.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: cs.primary, size: 20),
          onPressed: isLoading ? null : _goBack,
        ),
        actions: [
          CoinDisplay(),
          SizedBox(width: bottomPadding + 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepperBar(
              current: _currentStep,
              start:   widget.mode.startStep,
              labels:  _kStepLabels,
              icons:   _kStepIcons,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key:   ValueKey(_currentStep),
                  child: _buildStep(_currentStep),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _BottomActions(
              step:          _currentStep,
              startStep:     widget.mode.startStep,
              continueLabel: _continueLabel,
              continueIcon:  _continueIcon,
              canProceed:    canProceed,
              isLoading:     isLoading,
              onBack:        isLoading ? null : _goBack,
              onContinue:    isLoading || !canProceed ? null : _goNext,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0: return const Step1AppSetup();
      case 1: return const Step2TermsAvailability();
      case 2: return const Step3AppDetails();
      case 3: return const Step4TesterSelection();
      default: return const SizedBox.shrink();
    }
  }
}





class _StepperBar extends StatelessWidget {
  const _StepperBar({
    required this.current,
    required this.start,
    required this.labels,
    required this.icons,
  });
  final int            current, start;
  final List<String>   labels;
  final List<IconData> icons;

  static const _displayCount = _kTotalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Column(
        children: [
          Row(
            children: List.generate(_displayCount * 2 - 1, (i) {
              if (i.isEven) {
                final step   = i ~/ 2;
                final locked = step < start;
                final done   = !locked && step < current;
                final active = step == current;
                final color  = (done || active) && !locked
                    ? Colors.transparent
                    : cs.outline;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked
                        ? cs.outline
                        : (done || active) ? Colors.blue : cs.outline,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                      : Icon(icons[step],
                      size:  14,
                      color: active ? Colors.white : cs.onSurface),
                );
              } else {
                final seg    = i ~/ 2;
                final filled = seg < current && seg >= start;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: filled ? cs.primary : cs.outline,
                    ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(_displayCount * 2 - 1, (i) {
              if (i.isOdd) return const Expanded(child: SizedBox());
              final step   = i ~/ 2;
              final locked = step < start;
              final active = step == current;
              final done   = step < current && step >= start;
              return SizedBox(
                width: 30,
                child: Text(
                  labels[step],
                  textAlign: TextAlign.center,
                  maxLines:  1,
                  overflow:  TextOverflow.visible,
                  style: tt.labelSmall?.copyWith(
                    fontSize:   9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: locked
                        ? cs.onSurfaceVariant.withOpacity(0.25)
                        : active
                        ? cs.primary
                        : done
                        ? cs.onSurface.withOpacity(0.55)
                        : cs.onSurfaceVariant.withOpacity(0.45),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}





class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.startStep,
    required this.continueLabel,
    required this.continueIcon,
    required this.canProceed,
    required this.isLoading,
    required this.onBack,
    required this.onContinue,
  });
  final int           step, startStep;
  final String        continueLabel;
  final IconData      continueIcon;
  final bool          canProceed, isLoading;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final showBack = step > startStep;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: baseScreenPadding),
      child: Row(
        children: [
          if (showBack) ...[
            Expanded(
              flex: 1,
              child: CustomOutlineBtn(
                label:           'Back',
                onPressed:       onBack,
                isFullWidth:     true,
                size:            BtnSize.large,
                borderRadius:    textFromFieldBorderRadius,
                foregroundColor: cs.outline,
                prefixIcon:      Icons.arrow_back_rounded,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Opacity(
              opacity: canProceed ? 1.0 : 0.45,
              child: CustomElevatedBtn(
                label:        continueLabel,
                onPressed:    onContinue,
                isFullWidth:  true,
                isLoading:    isLoading,
                size:         BtnSize.large,
                borderRadius: textFromFieldBorderRadius,
                suffixIcon:   continueIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}