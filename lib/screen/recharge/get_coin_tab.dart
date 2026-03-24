import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testers/screen/recharge/service/ads/unity/unity_ads_service.dart';
import 'package:testers/screen/recharge/widget/milestone_card.dart';
import '../../controllers/info.dart';
import '../../service/firebase/CoinTransaction/coin_transaction_service.dart';
import '../../service/provider/auth_provider.dart';
import '../../widget/internet/internet_banner.dart';
import '../../widget/snackbar/custom_snackbar.dart';

// ─── SharedPreferences Keys ───────────────────────────────────────────────────
const String _kMilestone1Done     = 'milestone_1_done';
const String _kMilestone2Progress = 'milestone_2_progress';
const String _kMilestone3Progress = 'milestone_3_progress';
const String _kMilestone1LastAd   = 'milestone_1_last_ad_time';
const String _kMilestone2LastAd   = 'milestone_2_last_ad_time';
const String _kMilestone3LastAd   = 'milestone_3_last_ad_time';

const int _kCooldownSeconds = PublishConstants.adsCoolDown;

class GetCoinTab extends StatefulWidget {
  final Future<void> Function(int coins)? onCoinsEarned;
  const GetCoinTab({super.key, this.onCoinsEarned});

  @override
  State<GetCoinTab> createState() => _GetCoinTabState();
}

class _GetCoinTabState extends State<GetCoinTab> {
  // ── Milestone state ───────────────────────────────────────────────────────
  bool _milestone1Done     = false;
  int  _milestone2Progress = 0;
  int  _milestone3Progress = 0;

  // ── Cooldown state ────────────────────────────────────────────────────────
  bool _m1Cooldown = false;
  bool _m2Cooldown = false;
  bool _m3Cooldown = false;

  int _m1Secs = 0;
  int _m2Secs = 0;
  int _m3Secs = 0;

  Timer? _m1Timer;
  Timer? _m2Timer;
  Timer? _m3Timer;

  // Whether the cooldown in progress is a post-completion cooldown
  bool _m1WasCompletion = false;
  bool _m2WasCompletion = false;
  bool _m3WasCompletion = false;

  // Prevent double-tapping while an ad is loading/playing
  bool _m1AdPending = false;
  bool _m2AdPending = false;
  bool _m3AdPending = false;

  bool _isLoading = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadState();
    // Ensure ads are pre-loaded when we land on this tab
    UnityAdsService.instance.reloadAds();
  }

  @override
  void dispose() {
    _m1Timer?.cancel();
    _m2Timer?.cancel();
    _m3Timer?.cancel();
    super.dispose();
  }

  // ── Load from SharedPreferences ───────────────────────────────────────────
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final bool m1Done = prefs.getBool(_kMilestone1Done)    ?? false;
      final int  m2Prog = prefs.getInt(_kMilestone2Progress) ?? 0;
      final int  m3Prog = prefs.getInt(_kMilestone3Progress) ?? 0;

      if (!mounted) return;
      setState(() {
        _milestone1Done     = m1Done;
        _milestone2Progress = m2Prog;
        _milestone3Progress = m3Prog;
        _isLoading          = false;
      });

      _restoreCooldown(prefs, _kMilestone1LastAd, 1);
      _restoreCooldown(prefs, _kMilestone2LastAd, 2);
      _restoreCooldown(prefs, _kMilestone3LastAd, 3);
    } catch (e) {
      debugPrint('GetCoinTab._loadState error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _restoreCooldown(SharedPreferences prefs, String key, int m) {
    final int? lastMs = prefs.getInt(key);
    if (lastMs == null) return;

    final int elapsed   = DateTime.now().millisecondsSinceEpoch - lastMs;
    final int remaining = _kCooldownSeconds - (elapsed ~/ 1000);

    final bool wasCompletion = (m == 1 && _milestone1Done) ||
        (m == 2 && _milestone2Progress >= 4) ||
        (m == 3 && _milestone3Progress >= 10);

    if (remaining > 0) {
      _startCooldown(m, initial: remaining, wasCompletion: wasCompletion);
    } else if (wasCompletion) {
      // Cooldown already expired while app was closed — reset immediately
      _resetMilestone(m);
    }
  }

  // ── Cooldown timer ────────────────────────────────────────────────────────
  void _startCooldown(int m,
      {int initial = _kCooldownSeconds, bool wasCompletion = false}) {
    if (!mounted) return;

    setState(() {
      if (m == 1) {
        _m1Cooldown = true; _m1Secs = initial; _m1WasCompletion = wasCompletion;
      } else if (m == 2) {
        _m2Cooldown = true; _m2Secs = initial; _m2WasCompletion = wasCompletion;
      } else {
        _m3Cooldown = true; _m3Secs = initial; _m3WasCompletion = wasCompletion;
      }
    });

    final timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (m == 1) {
          _m1Secs--;
          if (_m1Secs <= 0) {
            _m1Cooldown = false; _m1Secs = 0; t.cancel();
            if (_m1WasCompletion) _resetMilestone(1);
          }
        } else if (m == 2) {
          _m2Secs--;
          if (_m2Secs <= 0) {
            _m2Cooldown = false; _m2Secs = 0; t.cancel();
            if (_m2WasCompletion) _resetMilestone(2);
          }
        } else {
          _m3Secs--;
          if (_m3Secs <= 0) {
            _m3Cooldown = false; _m3Secs = 0; t.cancel();
            if (_m3WasCompletion) _resetMilestone(3);
          }
        }
      });
    });

    if (m == 1)      { _m1Timer?.cancel(); _m1Timer = timer; }
    else if (m == 2) { _m2Timer?.cancel(); _m2Timer = timer; }
    else             { _m3Timer?.cancel(); _m3Timer = timer; }
  }

  // ── Reset milestone (memory + SharedPreferences) ──────────────────────────
  Future<void> _resetMilestone(int m) async {
    final prefs = await SharedPreferences.getInstance();

    if (m == 1) {
      await prefs.remove(_kMilestone1Done);
      await prefs.remove(_kMilestone1LastAd);
      if (mounted) setState(() { _milestone1Done = false; _m1WasCompletion = false; });
    } else if (m == 2) {
      await prefs.remove(_kMilestone2Progress);
      await prefs.remove(_kMilestone2LastAd);
      if (mounted) setState(() { _milestone2Progress = 0; _m2WasCompletion = false; });
    } else {
      await prefs.remove(_kMilestone3Progress);
      await prefs.remove(_kMilestone3LastAd);
      if (mounted) setState(() { _milestone3Progress = 0; _m3WasCompletion = false; });
    }
  }

  Future<void> _saveLastAdTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  // ── Ad handlers ───────────────────────────────────────────────────────────

  Future<void> _onWatchAdMilestone1() async {
    if (_m1Cooldown || _milestone1Done || _m1AdPending) return;
    if (mounted) setState(() => _m1AdPending = true);

    await UnityAdsService.instance.showRewardedAd(
      onCompleted: () async {
        await _saveLastAdTime(_kMilestone1LastAd);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kMilestone1Done, true);
        if (!mounted) return;

        setState(() { _milestone1Done = true; _m1AdPending = false; });
        _startCooldown(1, wasCompletion: true);
        _claimReward(PublishConstants.adsM1,  CoinTxType.adReward);      },
      onFailed: () {
        if (!mounted) return;
        setState(() => _m1AdPending = false);
        _showNoAdSnackbar();
      },
    );
  }

  Future<void> _onWatchAdMilestone2() async {
    if (_m2Cooldown || _milestone2Progress >= 4 || _m2AdPending) return;
    if (mounted) setState(() => _m2AdPending = true);

    await UnityAdsService.instance.showRewardedAd(
      onCompleted: () async {
        await _saveLastAdTime(_kMilestone2LastAd);

        final prefs  = await SharedPreferences.getInstance();
        final int next = (_milestone2Progress + 1).clamp(0, 4);
        await prefs.setInt(_kMilestone2Progress, next);
        if (!mounted) return;

        setState(() { _milestone2Progress = next; _m2AdPending = false; });
        final bool justCompleted = next == 4;
        _startCooldown(2, wasCompletion: justCompleted);
        if (justCompleted) _claimReward(PublishConstants.adsM2, CoinTxType.adReward);
      },
      onFailed: () {
        if (!mounted) return;
        setState(() => _m2AdPending = false);
        _showNoAdSnackbar();
      },
    );
  }

  Future<void> _onWatchAdMilestone3() async {
    if (_m3Cooldown || _milestone3Progress >= 10 || _m3AdPending) return;
    if (mounted) setState(() => _m3AdPending = true);

    await UnityAdsService.instance.showRewardedAd(
      onCompleted: () async {
        await _saveLastAdTime(_kMilestone3LastAd);

        final prefs  = await SharedPreferences.getInstance();
        final int next = (_milestone3Progress + 1).clamp(0, 10);
        await prefs.setInt(_kMilestone3Progress, next);
        if (!mounted) return;

        setState(() { _milestone3Progress = next; _m3AdPending = false; });
        final bool justCompleted = next == 10;
        _startCooldown(3, wasCompletion: justCompleted);
        if (justCompleted) _claimReward(PublishConstants.adsM3, CoinTxType.adReward);
      },
      onFailed: () {
        if (!mounted) return;
        setState(() => _m3AdPending = false);
        _showNoAdSnackbar();
      },
    );
  }

  // ── Claim reward ──────────────────────────────────────────────────────────
  Future<void> _claimReward(int coins, CoinTxType type) async {
    final auth = context.read<AuthProvider>();

    await CoinTransactionService.instance.logTransaction(
      userId:   auth.uid,
      username: auth.username,
      amount:   coins,
      type:     type,
      note:     'Ad reward',
    );

    await context.read<AuthProvider>().refreshUserData();

    widget.onCoinsEarned?.call(coins);
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      type:    SnackBarType.success,
      title:   'Reward Claimed!',
      message: '+$coins Coins added to your balance',
    );
  }

  // ── No-ad fallback snackbar ───────────────────────────────────────────────
  void _showNoAdSnackbar() {
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      type:    SnackBarType.error,
      title:   'No Ad Available',
      message: 'Please try again in a moment.',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme   tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surface,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const InternetBanner(),

          // ── Section label ─────────────────────────────────────────────────
          Text('MILESTONES', style: tt.titleMedium),

          // ── Milestone 1 ───────────────────────────────────────────────────
          MilestoneCard(
            title:                   'Milestone 1',
            rewardCoins:             2,
            totalAds:                1,
            currentProgress:         _milestone1Done ? 1 : 0,
            isCompleted:             _milestone1Done,
            isCooldownActive:        _m1Cooldown,
            cooldownSecondsRemaining: _m1Secs,
            isAdPending:             _m1AdPending,
            onWatchAd:               _onWatchAdMilestone1,
          ),

          // ── Milestone 2 ───────────────────────────────────────────────────
          MilestoneCard(
            title:                   'Milestone 2',
            rewardCoins:             10,
            totalAds:                4,
            currentProgress:         _milestone2Progress,
            isCompleted:             _milestone2Progress >= 4,
            isCooldownActive:        _m2Cooldown,
            cooldownSecondsRemaining: _m2Secs,
            isAdPending:             _m2AdPending,
            onWatchAd:               _onWatchAdMilestone2,
          ),

          // ── Milestone 3 ───────────────────────────────────────────────────
          MilestoneCard(
            title:                   'Milestone 3',
            rewardCoins:             26,
            totalAds:                10,
            currentProgress:         _milestone3Progress,
            isCompleted:             _milestone3Progress >= 10,
            isCooldownActive:        _m3Cooldown,
            cooldownSecondsRemaining: _m3Secs,
            isAdPending:             _m3AdPending,
            onWatchAd:               _onWatchAdMilestone3,
          ),

        ],
      ),
    );
  }
}