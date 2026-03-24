import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testers/screen/installizer/animated_drawer.dart';
import 'package:testers/screen/open_testers/provider/appitem.dart';
import 'package:testers/screen/open_testers/update/update_service.dart';
import 'package:testers/widget/internet/internet_banner.dart';
import '../../controllers/app_routes.dart';
import '../../controllers/height_width.dart';
import '../../controllers/info.dart';
import '../../theme/colors.dart';
import '../../widget/list tile/app_grid_card.dart';
import '../../widget/list tile/app_list_tile.dart';
import '../../widget/snackbar/custom_snackbar.dart';
import '../../widget/test field/custom_text_formField.dart';
import '../setting/bottom_sheet/group_join_sheet.dart';
import 'app_details.dart';
import 'publish_app/app_listing_screen.dart';

const _kGroupSheetShown = 'group_joining_sheet_shown';

class OpenTesters extends StatefulWidget {
  const OpenTesters({super.key, this.welcomeName});
  final String? welcomeName;

  @override
  State<OpenTesters> createState() => _OpenTestersState();
}

class _OpenTestersState extends State<OpenTesters> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.welcomeName != null) {
        CustomSnackbar.show(
          context,
          title: 'Welcome, ${widget.welcomeName}!',
          message: 'You have successfully logged in.',
          type: SnackBarType.success,
        );
      }
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        UpdateService.instance.checkForUpdate(context).then((_) {
          _maybeShowGroupSheet();
        });
      });
    });
    _searchCtrl.addListener(
      () =>
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  Future<void> _maybeShowGroupSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_kGroupSheetShown) ?? false;
    if (alreadyShown || !mounted) return;
    await prefs.setBool(_kGroupSheetShown, true);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GroupJoiningSheet(
        groupEmail: 'testers_community@googlegroups.com',
        groupLink: 'https://groups.google.com/u/2/g/testers_community',
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedDrawer(
      currentRoute: AppRoutes.ot,
      title: 'Open Testers',
      showCoinBadge: true,
      showNotificationBadge: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AppListingScreen()),
        ),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add App',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: Colors.white),
        ),
      ),
      child: Column(
        children: [
          const InternetBanner(),
          SizedBox(height: bottomPadding - 4),
          _SearchBar(controller: _searchCtrl),
          SizedBox(height: bottomPadding - 4),
          Expanded(child: _AppFeed(searchQuery: _searchQuery)),
          SizedBox(height: bottomPadding +6),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  App Feed — boosted grid first, then normal list, one count header
// ─────────────────────────────────────────────────────────────────────────────

class _AppFeed extends StatelessWidget {
  const _AppFeed({required this.searchQuery});
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<List<AppItem>>(
      stream: AppsRepository.instance.watchAvailableApps(),
      builder: (context, snap) {
        // ── Loading ─────────────────────────────────────────────────────────
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Error ────────────────────────────────────────────────────────────
        if (snap.hasError) {
          return _ErrorState(message: snap.error.toString());
        }

        final allApps = snap.data ?? [];

        // ── Filter + sort (boosted first → latest boost → newest) ────────────
        // ── Filter + sort (boosted first → latest boost → newest) ────────────
        final filtered =
        (searchQuery.isEmpty
            ? List<AppItem>.from(allApps)
            : allApps
            .where(
              (a) => a.appName.toLowerCase().contains(searchQuery),
        )
            .toList())
        // ✅ safety net: exclude apps that are full by count even if isFull flag is stale
            .where((a) => !a.isFull && a.currentTesterCount < a.maxTesters)
            .toList()
          ..sort((a, b) {
            if (b.isBoosted != a.isBoosted) return b.isBoosted ? 1 : -1;
            if (a.isBoosted && b.isBoosted) {
              final aT = a.boostTimestamp ?? DateTime(0);
              final bT = b.boostTimestamp ?? DateTime(0);
              final c = bT.compareTo(aT);
              if (c != 0) return c;
            }
            return b.createdAt.compareTo(a.createdAt);
          });

        final boostedApps = filtered.where((a) => a.isBoosted).toList();
        final normalApps = filtered.where((a) => !a.isBoosted).toList();
        final totalCount = filtered.length;

        // ── Empty ────────────────────────────────────────────────────────────
        if (filtered.isEmpty) {
          return _EmptyState(isSearch: searchQuery.isNotEmpty);
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$totalCount app${totalCount == 1 ? '' : 's'} available',
                    style: tt.titleSmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: bottomPadding - 4)),

            // ── Boosted apps — 2-column grid ──────────────────────────────
            if (boostedApps.isNotEmpty)
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.76,
                ),
                delegate: SliverChildBuilderDelegate((_, i) {
                  final app = boostedApps[i];
                  return AppGridCard(
                    appIconUrl: app.appIconUrl,
                    title: app.appName,
                    developerName: app.developerName,
                    coinCost: app.coins,
                    isBoosted: true,
                    onTap: () => _goToDetails(context, app),
                  );
                }, childCount: boostedApps.length),
              ),

            // ── Spacing between grid and list ─────────────────────────────
            if (boostedApps.isNotEmpty && normalApps.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Normal apps — list ────────────────────────────────────────
            if (normalApps.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final app = normalApps[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding - 4),
                    child: AppListTile(
                      appName: app.appName,
                      developerName: app.developerName,
                      appIconUrl: app.appIconUrl,
                      coins: app.coins,
                      onTap: () => _goToDetails(context, app),
                    ),
                  );
                }, childCount: normalApps.length),
              ),

            // ── Bottom breathing room ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  void _goToDetails(BuildContext context, AppItem app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppDetailsScreen(
          appId: app.id,
          appName: app.appName,
          developerName: app.developerName,
          appIconUrl: app.appIconUrl,
          coins: app.coins,
          testedCount: app.currentTesterCount,
          publisherUid: app.ownerUid,
          packageName: app.packageName,
          isBoosted: app.isBoosted,
          description: app.description,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomTextFormField(
      controller: controller,
      hint: 'Search apps...',
      prefixIcon: Icons.search_rounded,
      suffixWidget: controller.text.isNotEmpty
          ? GestureDetector(
              onTap: controller.clear,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : null,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      validate: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.apps_outlined,
            size: 52,
            color: cs.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 14),
          Text(
            isSearch ? 'No apps match your search' : 'No apps listed yet',
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch ? 'Try a different keyword' : 'Tap + Add App to list one',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: tt.titleMedium?.copyWith(color: cs.error),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
