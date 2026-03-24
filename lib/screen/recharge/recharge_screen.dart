import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/installizer/animated_drawer.dart';
import 'package:testers/screen/recharge/service/coin_service.dart';
import '../../controllers/app_routes.dart';
import '../../service/provider/auth_provider.dart';
import 'buy_coin_tab.dart';
import 'get_coin_tab.dart';

const _orange = Color(0xFFFF9800);
const _blue   = Color(0xFF1565C0);

// ─────────────────────────────────────────────────────────────────────────────
// RechargeScreen
// ─────────────────────────────────────────────────────────────────────────────

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) => const _RechargeView();
}

class _RechargeView extends StatefulWidget {
  const _RechargeView();

  @override
  State<_RechargeView> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<_RechargeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  //
  Future<void> _onCoinsEarned(int coins) async {
    try {
      // Step 1 — write to Firestore
      await CoinService.addCoins(coins);

      // Step 2 — refresh local auth/user state so UI updates everywhere
      if (mounted) {
        await context.read<AuthProvider>().refreshUserData();
      }
    } catch (e) {
      debugPrint('RechargeScreen._onCoinsEarned error: $e');
      // Optionally show an error snackbar here
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    return AnimatedDrawer(
      currentRoute:          AppRoutes.recharge,
      title:                 'Recharge',
      showCoinBadge:         true,
      showNotificationBadge: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── TabBar ──────────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            indicator: const BoxDecoration(
              color: Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.blue)),
            ),
            indicatorSize:        TabBarIndicatorSize.tab,
            labelColor:           _orange,
            unselectedLabelColor: cs.onPrimary,
            labelStyle: theme.textTheme.labelLarge!
                .copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: theme.textTheme.labelLarge,
            dividerColor:  cs.outline,
            dividerHeight: 2,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Buy Coin'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Get Coin'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── TabBarView ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const BuyCoinTab(),

                // Pass the async callback — GetCoinTab calls it on auto-claim
                GetCoinTab(onCoinsEarned: _onCoinsEarned),
              ],
            ),
          ),
        ],
      ),
    );
  }
}