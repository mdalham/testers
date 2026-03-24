import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/discovery/provider/publish_provider.dart';
import 'package:testers/screen/discovery/publish_app/app_listing_screen.dart';
import 'package:testers/screen/discovery/publish_app/step5_success.dart';
import 'package:testers/screen/discovery/testing_progress_bottom_sheet.dart';
import 'package:testers/screen/discovery/update/app_info_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../screen/auth/provider/auth_provider.dart';
import '../constants/icons.dart';
import '../screen/report/report_screen.dart';
import '../utils/height_width.dart';
import '../widgets/button/custom_buttons.dart';
import '../widgets/container/animated_expandable_card.dart';

class AppDetailsScreen extends StatefulWidget {
  const AppDetailsScreen({
    super.key,
    required this.appId,
    required this.appName,
    required this.developerName,
    required this.coins,
    required this.testedCount,
    required this.publisherUid,
    required this.packageName,
    required this.isBoosted,
    this.appIconUrl,
    required this.description,
  });

  final String appId;
  final String appName;
  final String developerName;
  final int coins;
  final int testedCount;
  final String publisherUid;
  final String packageName;
  final bool isBoosted;
  final String? appIconUrl;
  final String description;

  static const _steps = [
    'Open app in Play Store',
    'Install the app',
    'Explore the app and try to find a bug',
    'Provide feedback',
    'Claim your coins!',
  ];

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isOwner = false;
  bool _alreadyTested = false;
  bool _historyLoaded = false;

  int get _rewardCoins => widget.coins;

  @override
  void initState() {
    super.initState();
    _isOwner = _currentUid == widget.publisherUid;
    if (!_isOwner) _checkHistory();
    
    FirebaseFirestore.instance
        .collection('apps')
        .doc(widget.appId)
        .get()
        .then((doc) {
      final d       = doc.data();
      if (d == null) return;
      final current = (d['currentTesterCount'] as num?)?.toInt() ?? 0;
      final max     = (d['maxTesters']         as num?)?.toInt() ?? 0;
      final isFull  = (d['isFull']             as bool?) ?? false;
      if (current >= max && !isFull) {
        doc.reference.update({'isFull': true});
      }
    });
  }

  Future<void> _openInPlayStore() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=${widget.packageName}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _seedProvider() {
    final p = context.read<PublishProvider>();
    p.reset();
    p.setStep3AppName(widget.appName);
    p.setStep3Developer(widget.developerName);
    p.setStep3PackageName(widget.packageName);
    p.setStep3Description(widget.description);
    if ((widget.appIconUrl ?? '').isNotEmpty) p.setIconUrl(widget.appIconUrl!);
  }

  void _openEdit() {
    _seedProvider();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:  (_) => const AppListingScreen(mode: PublishFlowMode.edit),
        settings: RouteSettings(arguments: widget.appId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          color: cs.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('App details', style: tt.titleLarge),
        actions: [
          GestureDetector(
            onTap: ()=>Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReportScreen(
                appId:         widget.appId,
                appName:       widget.appName,
                developerName: widget.developerName,
                sourceType:    'open_tester',
              ),
            )),
            child: Icon(Icons.bug_report,color: Colors.red,),

          ),
          SizedBox(width: 16,)
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            
            SingleChildScrollView(
              padding: .all(baseScreenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppHeaderCard(
                    appName:      widget.appName,
                    developerName: widget.developerName,
                    appIconUrl:   widget.appIconUrl,
                    coins:        widget.coins,
                    testedCount:  widget.testedCount,
                    rewardCoins:  _rewardCoins,
                    isBoosted:    widget.isBoosted,
                    appId:        widget.appId,
                  ),
                  SizedBox(height: bottomPadding),
                  _AboutCard(description: widget.description),
                  SizedBox(height: bottomPadding),
                  AppInfoCard(
                    appId:         widget.appId,
                    currentUid:    _currentUid,
                    publisherUid:  widget.publisherUid,
                    appName:       widget.appName,
                    developerName: widget.developerName,
                    packageName:   widget.packageName,
                    appIconUrl:    widget.appIconUrl,
                    onEdit:  _openEdit,
                    onBoost: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:  (_) => const Step5Success(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: bottomPadding),
                  AnimatedExpandableCard(
                    icon:        Icons.checklist_rounded,
                    iconColor:   Colors.blueAccent,
                    accentColor: Colors.blueAccent,
                    title:       'How to test',
                    collapsedTrailing: [
                      CardChip(
                        label: '${AppDetailsScreen._steps.length} Steps',
                        color: Colors.blueAccent,
                      ),
                    ],
                    children: [
                      ...AppDetailsScreen._steps.asMap().entries.map(
                            (e) => CardInfoRow(
                          label:       '${e.key + 1}. ${e.value}',
                          showDivider: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 80),
                ],
              ),
            ),

            
            Positioned(
              left:   0,
              right:  0,
              bottom: 0,
              child: _BottomButton(
                isOwner:       _isOwner,
                alreadyTested: _alreadyTested,
                historyLoaded: _historyLoaded,
                rewardCoins:   _rewardCoins,
                onOpenApp:     _openInPlayStore,
                onStartTesting: () {
                  TestingProgressBottomSheet.show(
                    context:       context,
                    username:      context.read<AuthProvider>().username,
                    appId:         widget.appId,
                    appName:       widget.appName,
                    developerName: widget.developerName,
                    packageName:   widget.packageName,
                    rewardCoins:   _rewardCoins,
                    onClaimed: () {
                      if (mounted) setState(() => _alreadyTested = true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkHistory() async {
    if (_currentUid.isEmpty) {
      if (mounted) setState(() => _historyLoaded = true);
      return;
    }
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('user_tested_apps')
            .doc(_currentUid)
            .get(),
        FirebaseFirestore.instance.collection('apps').doc(widget.appId).get(),
      ]);

      final userDoc = results[0];
      final appDoc = results[1];
      bool alreadyTested = false;

      if (userDoc.exists) {
        final testedApps =
            (userDoc.data()?['testedApps'] as List<dynamic>?) ?? [];
        final matches = testedApps
            .whereType<Map<String, dynamic>>()
            .where((e) => e['appId'] == widget.appId)
            .toList();

        if (matches.isNotEmpty) {
          final relistedAt =
              (appDoc.data() as Map<String, dynamic>?)?['relistedAt']
                  as Timestamp?;
          final claimedAt = matches.last['joinedAt'] as Timestamp?;

          if (relistedAt != null &&
              claimedAt != null &&
              relistedAt.compareTo(claimedAt) > 0) {
            alreadyTested = false;
          } else {
            alreadyTested = true;
          }
        }
      }

      if (mounted) {
        setState(() {
          _alreadyTested = alreadyTested;
          _historyLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _historyLoaded = true);
    }
  }
}





class _AppHeaderCard extends StatelessWidget {
  const _AppHeaderCard({
    required this.appName,
    required this.developerName,
    required this.coins,
    required this.testedCount,
    required this.rewardCoins,
    required this.isBoosted, 
    required this.appId,
    this.appIconUrl,
  });

  final String appName;
  final String developerName;
  final int coins;
  final int testedCount;
  final int rewardCoins;
  final bool isBoosted; 
  final String appId;
  final String? appIconUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: _cardDecoration(cs),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AppIconBox(imageUrl: appIconUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabelValue(label: 'App name:', value: appName),
                      const SizedBox(height: 2),
                      _LabelValue(label: 'Developed by:', value: developerName),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: cs.outline),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: _StatBadge.coins(rewardCoins)),
                const SizedBox(width: 10),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('apps')
                        .doc(appId)
                        .snapshots(),
                    builder: (context, snap) {
                      final liveCount =
                          (snap.data?.data()
                                  as Map<
                                    String,
                                    dynamic
                                  >?)?['currentTesterCount']
                              as int? ??
                          testedCount;
                      return _StatBadge.tested(liveCount);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





class _AppIconBox extends StatelessWidget {
  const _AppIconBox({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 70,
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(cs),
              )
            : _placeholder(cs),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) =>
      Icon(Icons.grid_view_rounded, size: 40, color: cs.onSurface);
}





class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: tt.titleSmall),
        ),
      ],
    );
  }
}





class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.borderColor,
    required this.iconColor,
    this.icon,
    this.assetIcon,
  }) : assert(
         icon != null || assetIcon != null,
         'Provide either icon or assetIcon',
       );

  factory _StatBadge.coins(int amount) => _StatBadge(
    assetIcon: coinIcon,
    label: '+$amount Coins Reward',
    borderColor: Colors.amber,
    iconColor: const Color(0xFFFFB800),
  );

  factory _StatBadge.tested(int count) => _StatBadge(
    icon: Icons.people_rounded,
    label: '$count Tested',
    borderColor: Colors.blueAccent,
    iconColor: Colors.blueAccent,
  );

  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (assetIcon != null)
            Image.asset(assetIcon!, width: 18, height: 18)
          else if (icon != null)
            Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}





class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      decoration: _cardDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(bottomPadding),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(width: bottomPadding),
                Text('About this app', style: tt.titleMedium),
              ],
            ),
          ),
          Divider(color: cs.outline),
          Padding(
            padding: EdgeInsets.all(bottomPadding),
            child: Text(
              'Keep testing app for 14 days\n$description',
              style: tt.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}





class _EarnCoinsCard extends StatelessWidget {
  const _EarnCoinsCard({required this.rewardCoins});
  final int rewardCoins;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(baseBorderRadius),
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Image.asset(coinIcon),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earn $rewardCoins Coins',
                style: tt.titleMedium!.copyWith(color: Colors.blue),
              ),
              const SizedBox(height: 3),
              Text(
                'Complete testing to earn $rewardCoins coins',
                style: tt.bodySmall!.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}





class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.isOwner,
    required this.alreadyTested,
    required this.historyLoaded,
    required this.rewardCoins,
    required this.onOpenApp,
    required this.onStartTesting,
  });

  final bool         isOwner;
  final bool         alreadyTested;
  final bool         historyLoaded;
  final int          rewardCoins;
  final VoidCallback onOpenApp;
  final VoidCallback onStartTesting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final String    label;
    final Color     bg;
    final IconData  icon;
    final VoidCallback? action;

    if (isOwner) {
      label  = 'Open App';
      bg     = Colors.blueAccent;
      icon   = Icons.open_in_new_rounded;
      action = onOpenApp;
    } else if (!historyLoaded) {
      label  = 'Loading...';
      bg     = Colors.blueAccent;
      icon   = Icons.hourglass_top_rounded;
      action = null;
    } else if (alreadyTested) {
      label  = 'Already Tested';
      bg     = Colors.blueAccent;
      icon   = Icons.check_circle_rounded;
      action = null;
    } else {
      label  = 'Start Testing';
      bg     = Colors.blue;
      icon   = Icons.play_arrow_rounded;
      action = onStartTesting;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [
            cs.surface.withOpacity(0.0),
            cs.surface.withOpacity(0.85),
            cs.surface,
          ],
        ),
      ),
      padding: .all(baseScreenPadding),
      child: CustomElevatedBtn(
        label:           label,
        onPressed:       action,
        prefixIcon:      icon,
        backgroundColor: bg,
        size:            BtnSize.large,
        isFullWidth:     true,
        borderRadius:    baseBorderRadius,
        enabled:         action != null,
        isLoading:       !historyLoaded && !isOwner,
      ),
    );
  }
}




BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
  color: cs.primaryContainer,
  borderRadius: BorderRadius.circular(baseBorderRadius),
  border: Border.all(color: cs.outline, width: 1),
);
