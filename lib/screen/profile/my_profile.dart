import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/constants/app_routes.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/widgets/list tile/app_card.dart';
import 'package:testers/screen/auth/animated_drawer.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedDrawer(
      currentRoute: AppRoutes.profile,
      title: 'Profile',
      showCoinBadge: true,
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().uid; 
    return Column(
      children: [
        _ProfileHeader(uid: uid),
        SizedBox(height: bottomPadding),
        _ProfileTabBar(controller: _tabCtrl),
        SizedBox(height: bottomPadding),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _MyApplicationsTab(uid: uid),
              _TestHistoryTab(uid: uid),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.uid});
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProfileAvatar(
                photoURL:    auth.photoURL,
                displayName: auth.displayName,
                username:    auth.username,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (auth.displayName.trim().isNotEmpty)
                      Text(
                        auth.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(
                          fontWeight:  FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    if (auth.username.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.alternate_email_rounded,
                              size: 13, color: cs.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              auth.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                color:      cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (FirebaseAuth.instance.currentUser?.email != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.mail_outline_rounded,
                              size:  13,
                              color: cs.onSurfaceVariant.withOpacity(0.65)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              FirebaseAuth.instance.currentUser!.email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant.withOpacity(0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.photoURL,
    required this.displayName,
    required this.username,
  });

  final String photoURL;
  final String displayName;
  final String username;

  String get _initial {
    if (displayName.trim().isNotEmpty) return displayName[0].toUpperCase();
    if (username.trim().isNotEmpty)    return username[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape:  BoxShape.circle,
        border: Border.all(color: cs.outline, width: 1.5), 
      ),
      child: CircleAvatar(
        radius:          36,
        backgroundColor: cs.surfaceContainerHighest,
        child: ClipOval(
          child: photoURL.isNotEmpty
              ? Image.network(
            photoURL,
            width:  72,
            height: 72,
            fit:    BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _AvatarInitial(initial: _initial, cs: cs),
          )
              : _AvatarInitial(initial: _initial, cs: cs),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.initial, required this.cs});
  final String      initial;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:     72,
      height:    72,
      color:     cs.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize:   26,
          fontWeight: FontWeight.bold,
          color:      cs.primary,
        ),
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color:        cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: TabBar(
        controller:           controller,
        indicator: BoxDecoration(
          color:        Colors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize:        TabBarIndicatorSize.tab,
        dividerColor:         Colors.transparent,
        labelColor:           cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle:           const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        padding:              const EdgeInsets.all(5),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.grid_view_rounded, size: 15),
                SizedBox(width: 6),
                Text('Applications'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.history_rounded, size: 15),
                SizedBox(width: 6),
                Text('History'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyApplicationsTab extends StatelessWidget {
  const _MyApplicationsTab({required this.uid});
  final String? uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const _EmptyTab(message: 'Not signed in.');

    return StreamBuilder<QuerySnapshot>(
      key:    ValueKey(uid), 
      stream: FirebaseFirestore.instance
          .collection('apps')
          .where('ownerUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const _EmptyTab(
            icon:    Icons.error_outline_rounded,
            message: 'Failed to load apps.',
          );
        }

        final docs = [...(snap.data?.docs ?? [])]
          ..sort((a, b) {
            final aTs = (a.data() as Map<String, dynamic>)['createdAt'];
            final bTs = (b.data() as Map<String, dynamic>)['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });

        if (docs.isEmpty) {
          return const _EmptyTab(
            icon:    Icons.add_box_outlined,
            message: 'No apps published yet.',
            sub:     'Publish your first app.',
          );
        }

        return ListView.separated(
          padding:          EdgeInsets.zero,
          itemCount:        docs.length,
          separatorBuilder: (_, __) => SizedBox(height: bottomPadding - 8),
          itemBuilder: (context, i) {
            final data  = docs[i].data() as Map<String, dynamic>;
            final count = (data['currentTesterCount'] as num?)?.toInt() ?? 0;
            final maxT  = (data['maxTesters']         as num?)?.toInt() ?? 12;

            return AppCard(
              docId:       docs[i].id,
              ownerUid:    data['ownerUid']      as String? ?? '',
              iconUrl:     data['iconUrl']       as String? ?? '',
              appName:     data['appName']       as String? ?? 'Unknown',
              developer:   data['developerName'] as String? ?? '',
              packageName: data['packageName']   as String? ?? '',
              description: data['description']   as String? ?? '',
              testerCount: count,
              maxTesters:  maxT,
              isBoosted:   data['isBoosted']     as bool? ?? false,
              isFull:      data['isFull']        as bool? ?? count >= maxT,
              createdAt:   data['createdAt']     as Timestamp?,
            );
          },
        );
      },
    );
  }
}

class _TestHistoryTab extends StatefulWidget {
  const _TestHistoryTab({required this.uid});
  final String? uid;

  @override
  State<_TestHistoryTab> createState() => _TestHistoryTabState();
}

class _TestHistoryTabState extends State<_TestHistoryTab> {
  Stream<List<_HistoryEntry>>? _stream;

  @override
  void initState() {
    super.initState();
    if (widget.uid != null) {
      _stream = _buildCombinedStream(widget.uid!);
    }
  }

  @override
  void didUpdateWidget(_TestHistoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.uid != widget.uid && widget.uid != null) {
      _stream = _buildCombinedStream(widget.uid!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Stream<List<_HistoryEntry>> _buildCombinedStream(String uid) {
    List<_HistoryEntry> _tested  = [];
    List<_HistoryEntry> _reports = [];
    StreamSubscription? testedSub;
    StreamSubscription? reportsSub;
    late StreamController<List<_HistoryEntry>> controller;

    void emit() {
      if (controller.isClosed) return;
      final all = [..._tested, ..._reports]
        ..sort((a, b) {
          if (a.sortDate == null && b.sortDate == null) return 0;
          if (a.sortDate == null) return 1;
          if (b.sortDate == null) return -1;
          return b.sortDate!.compareTo(a.sortDate!);
        });
      controller.add(all);
    }

    controller = StreamController<List<_HistoryEntry>>(
      onListen: () {
        testedSub = FirebaseFirestore.instance
            .collection('user_tested_apps')
            .doc(uid)
            .snapshots()
            .listen((doc) async {
          final raw     = (doc.data()?['testedApps'] as List<dynamic>?) ?? [];
          final entries = <_HistoryEntry>[];

          for (final item in raw.whereType<Map<String, dynamic>>()) {
            final appId    = item['appId']      as String?   ?? '';
            final joinedAt = item['joinedAt']   as Timestamp?;
            var   appName  = item['appName']    as String?;
            var   iconUrl  = item['appIconUrl'] as String?;
            var   coins    = (item['coinsEarned'] as num?)?.toInt();

            if (appName == null || coins == null) {
              try {
                final d = (await FirebaseFirestore.instance
                    .collection('apps')
                    .doc(appId)
                    .get())
                    .data();
                appName ??= d?['appName']       as String? ?? 'Unknown App';
                iconUrl ??= d?['iconUrl']       as String?;
                coins   ??= (d?['testerReward'] as num?)?.toInt() ?? 0;
              } catch (_) {
                appName ??= 'Unknown App';
                coins   ??= 0;
              }
            }

            entries.add(_HistoryEntry(
              type:     _EntryType.tested,
              sortDate: joinedAt,
              appName:  appName ?? 'Unknown App',
              iconUrl:  iconUrl,
              coins:    coins   ?? 0,
              joinedAt: joinedAt,
            ));
          }

          _tested = entries;
          emit();
        }, onError: (_) => emit());

        reportsSub = FirebaseFirestore.instance
            .collection('report')
            .where('userId', isEqualTo: uid)
            .snapshots()
            .listen((snap) {
          _reports = snap.docs.map((doc) {
            final d = doc.data();
            return _HistoryEntry(
              type:          _EntryType.report,
              sortDate:      d['createdAt']     as Timestamp?,
              appName:       d['appName']       as String? ?? 'Unknown App',
              problemType:   d['problemType']   as String? ?? '—',
              reportId:      d['reportId']      as String? ?? doc.id,
              createdAt:     d['createdAt']     as Timestamp?,
              screenshotUrl: d['screenshotUrl'] as String?,
            );
          }).toList();
          emit();
        }, onError: (_) => emit());
      },
      onCancel: () {
        testedSub?.cancel();
        reportsSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid == null) {
      return const _EmptyTab(message: 'Not signed in.');
    }

    return StreamBuilder<List<_HistoryEntry>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return const _EmptyTab(
            icon:    Icons.error_outline_rounded,
            message: 'Failed to load history.',
          );
        }

        final entries = snap.data ?? [];

        if (entries.isEmpty) {
          return const _EmptyTab(
            icon:    Icons.history_rounded,
            message: 'No activity yet.',
            sub:     'Your tested apps and submitted reports will appear here.',
          );
        }

        return ListView.builder(
          padding:     EdgeInsets.zero,
          itemCount:   entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding - 4),
              child: entry.type == _EntryType.tested
                  ? _TestedAppItem(entry: entry)
                  : _ReportItem(entry: entry),
            );
          },
        );
      },
    );
  }
}

enum _EntryType { tested, report }

class _HistoryEntry {
  const _HistoryEntry({
    required this.type,
    required this.sortDate,
    required this.appName,
    this.iconUrl,
    this.coins,
    this.joinedAt,
    this.problemType,
    this.reportId,
    this.createdAt,
    this.screenshotUrl,
  });

  final _EntryType  type;
  final Timestamp?  sortDate;
  final String      appName;
  final String?     iconUrl;
  final int?        coins;
  final Timestamp?  joinedAt;
  final String?     problemType;
  final String?     reportId;
  final Timestamp?  createdAt;
  final String?     screenshotUrl;
}

class _TestedAppItem extends StatelessWidget {
  const _TestedAppItem({required this.entry});
  final _HistoryEntry entry;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String _fmt(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color:        cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 46, height: 46,
              child: entry.iconUrl != null && entry.iconUrl!.isNotEmpty
                  ? Image.network(
                entry.iconUrl!,
                fit:          BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconPlaceholder(cs),
              )
                  : _iconPlaceholder(cs),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.appName,
                    style:    tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 11, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_fmt(entry.joinedAt),
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color:        Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_rounded, size: 13, color: Colors.amber),
                const SizedBox(width: 4),
                Text('+${entry.coins ?? 0}',
                    style: tt.labelSmall?.copyWith(
                      color:      Colors.amber,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconPlaceholder(ColorScheme cs) => Container(
    color: cs.surface,
    child: Icon(Icons.grid_view_rounded,
        size: 24, color: cs.onSurfaceVariant),
  );
}

class _ReportItem extends StatelessWidget {
  const _ReportItem({required this.entry});
  final _HistoryEntry entry;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String _fmt(Timestamp? ts) {
    if (ts == null) return '—';
    final dt = ts.toDate();
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color:        cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  46, height: 46,
            decoration: BoxDecoration(
              color:        Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: const Icon(Icons.bug_report_rounded,
                color: Colors.redAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.appName,
                    style:    tt.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.25)),
                  ),
                  child: Text(entry.problemType ?? '—',
                      style: tt.labelSmall?.copyWith(
                        color:      Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                const SizedBox(height: 5),
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 11, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_fmt(entry.createdAt),
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:        cs.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.outline.withOpacity(0.4)),
            ),
            child: Text('#${entry.reportId ?? '—'}',
                style: tt.labelSmall?.copyWith(
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 0.5,
                  color:         cs.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.sub,
  });

  final IconData icon;
  final String   message;
  final String?  sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54,
                color: cs.onSurfaceVariant.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}