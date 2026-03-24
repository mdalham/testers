import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/controllers/icons.dart';
import '../../../controllers/height_width.dart';
import '../../../controllers/info.dart';
import '../../../service/firebase/CoinTransaction/coin_transaction_service.dart';
import '../../../service/provider/auth_provider.dart';
import '../../../widget/button/custom_buttons.dart';
import '../../../widget/snackbar/custom_snackbar.dart';
import '../provider/discount_provider.dart';
import '../provider/publish_provider.dart';


class Step5Success extends StatefulWidget {
  const Step5Success({super.key});

  @override
  State<Step5Success> createState() => _Step5SuccessState();
}

class _Step5SuccessState extends State<Step5Success>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _fadeAnim;

  bool _isBoosting = false;
  bool _boosted    = false;

  @override
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(
        parent: _ctrl,
        curve:  const Interval(0.4, 1.0, curve: Curves.easeOut));
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUserData();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Boost ──────────────────────────────────────────────────────────────────

  Future<void> _boost() async {
    final p    = context.read<PublishProvider>();
    final auth = context.read<AuthProvider>();

    final docId = p.lastPublishedDocId;
    if (docId == null) {
      CustomSnackbar.show(context,
          title:   'Error',
          message: 'No app found to boost.',
          type:    SnackBarType.error);
      return;
    }

    setState(() => _isBoosting = true);

    final result = await p.boostApp(docId);

    if (!mounted) return;
    setState(() => _isBoosting = false);

    if (result.isSuccess) {
      await CoinTransactionService.instance.logTransaction(
        userId:   auth.uid,
        username: auth.username,
        amount:   -PublishConstants.boostCoinCost,
        type:     CoinTxType.boost,
        note:     p.step3AppName.trim(),
      );
      await auth.refreshUserData();
      setState(() => _boosted = true);
      CustomSnackbar.show(context,
          title:   'Boosted!',
          message: 'Your app is now boosted — it will stay boosted until all testers complete.',
          type:    SnackBarType.success);
    } else if (result.isInsufficientCoins) {
      CustomSnackbar.show(context,
          title:   'Not Enough Coins',
          message: result.errorMessage ?? 'Insufficient coins.',
          type:    SnackBarType.error);
    } else {
      CustomSnackbar.show(context,
          title:   'Boost Failed',
          message: result.errorMessage ?? 'Something went wrong.',
          type:    SnackBarType.error);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p    = context.watch<PublishProvider>();
    final auth = context.watch<AuthProvider>();
    final discount = context.watch<DiscountProvider>();
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;

    final appName      = p.step3AppName.trim();
    final originalCost = p.totalCoinsRequired;
    final finalCost    = discount.discountedCost(originalCost);
    final canBoost     = !_boosted && auth.coins >= PublishConstants.boostCoinCost;
    final hasDocId     = p.lastPublishedDocId != null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(baseScreenPadding),
          child: Column(
            children: [
              const Spacer(),

              // ── Success badge ──────────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width:  96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    color:  Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.green, size: 52),
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text('Your app is now live!',
                        style: tt.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      appName.isNotEmpty
                          ? '"$appName" is live — testers can now start testing.'
                          : 'Testers can now start testing your app.',
                      textAlign: TextAlign.center,
                      style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Stats row ──────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatBadge(
                      icon:  Icons.people_rounded,
                      label: '${p.selectedTesterCount}',
                      sub:   'testers',
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 16),
                    _StatBadge(
                      assetImage: coinIcon,
                      label: '$finalCost',
                      sub:   'coins used',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 16),
                    _StatBadge(
                      icon:  Icons.schedule_rounded,
                      label: p.testingDuration == TestingDuration.days14
                          ? '14'
                          : '∞',
                      sub:   'days',
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Boost card ─────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: _BoostCard(
                  isBoosted:  _boosted,
                  isBoosting: _isBoosting,
                  canBoost:   canBoost && hasDocId,
                  userCoins:  auth.coins,
                  onBoost:    _isBoosting ? null : _boost,
                ),
              ),

              SizedBox(height: bottomPadding+20),

              // ── Back to Home ───────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: CustomElevatedBtn(
                  label:           'Back to Home',
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  isFullWidth:     true,
                  size:            BtnSize.large,
                  borderRadius:    textFromFieldBorderRadius,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  prefixIcon:      Icons.home_rounded,
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Boost Card
// ─────────────────────────────────────────────────────────────────────────────

class _BoostCard extends StatelessWidget {
  const _BoostCard({
    required this.isBoosted,
    required this.isBoosting,
    required this.canBoost,
    required this.userCoins,
    required this.onBoost,
  });

  final bool          isBoosted;
  final bool          isBoosting;
  final bool          canBoost;
  final int           userCoins;
  final VoidCallback? onBoost;

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final tt          = Theme.of(context).textTheme;
    final accentColor = isBoosted ? Colors.green : Colors.amber;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:  const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        accentColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color:        accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBoosted ? Icons.bolt_rounded : Icons.rocket_launch_rounded,
                  size:  20,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBoosted ? 'App Boosted!' : 'Boost Your App',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isBoosted
                          ? 'Active until all testers complete'
                          : 'Get top placement until testers are full',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!isBoosted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.toll_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${PublishConstants.boostCoinCost}',
                          style: tt.labelSmall?.copyWith(
                              color:      Colors.amber,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),

          if (!isBoosted) ...[
            const SizedBox(height: 14),

            _BoostFeatureRow(
                icon:  Icons.trending_up_rounded,
                color: Colors.orange,
                text:  'Appear at the very top of the tester feed'),
            const SizedBox(height: 8),
            _BoostFeatureRow(
                icon:  Icons.people_rounded,
                color: Colors.blueAccent,
                text:  'Attract more testers quickly'),
            const SizedBox(height: 8),
            _BoostFeatureRow(
                icon:  Icons.all_inclusive_rounded,
                color: Colors.green,
                text:  'Stays boosted until all testers complete'),

            const SizedBox(height: 16),

            // Balance
            Row(
              children: [
                Text('Your balance: ',
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                const Icon(Icons.toll_rounded, size: 13, color: Colors.amber),
                const SizedBox(width: 3),
                Text('$userCoins coins',
                    style: tt.labelSmall?.copyWith(
                      color: userCoins >= PublishConstants.boostCoinCost
                          ? cs.onSurface
                          : Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canBoost ? onBoost : null,
                icon: isBoosting
                    ? const SizedBox(
                  width:  14,
                  height: 14,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.bolt_rounded, size: 18),
                label: Text(
                  isBoosting
                      ? 'Boosting...'
                      : canBoost
                      ? 'Boost Now — ${PublishConstants.boostCoinCost} coins'
                      : 'Not enough coins',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBoost
                      ? Colors.amber
                      : cs.surfaceContainerHighest,
                  foregroundColor: canBoost
                      ? Colors.black87
                      : cs.onSurfaceVariant,
                  padding:   const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BoostFeatureRow extends StatelessWidget {
  const _BoostFeatureRow({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color    color;
  final String   text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat Badge
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.sub,
    required this.color,
    this.icon,
    this.assetImage,
  }) : assert(icon != null || assetImage != null,
  '_StatBadge requires either icon or assetImage');

  final IconData? icon;
  final String?   assetImage;
  final String    label, sub;
  final Color     color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // ✅ render image or icon
          if (assetImage != null)
            Image.asset(assetImage!, width: 20, height: 20)
          else
            Icon(icon, size: 20, color: color),

          const SizedBox(height: 6),
          Text(label,
              style: tt.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800, color: color)),
          Text(sub,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}