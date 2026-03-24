import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testers/utils/height_width.dart';
import 'package:testers/models/room_model.dart';
import 'package:testers/screen/room/sheet/test_detail_sheet.dart';

const _blue = Colors.blue;
const _deepBlue = Color(0xFF1A237E);
const _orange = Color(0xFFFF9800);
const _green = Color(0xFF2E7D32);

enum _ReportSource { open, group }

class _ProofEntry {
  _ProofEntry({
    required this.testerUid,
    required this.testerName,
    required this.screenshotUrl,
    required this.submittedAt,
    required this.windowDate,
    required this.issueType,
    required this.reportText,
    required this.source,
    required this.appName,
    required this.appIconUrl,
    required this.packageName,
    required this.developerName,
    required this.description,
  });

  final String testerUid;
  final String testerName;
  final String screenshotUrl;
  final DateTime submittedAt;
  final DateTime windowDate;
  final String? issueType;
  final String? reportText;
  final _ReportSource source;
  final String appName;
  final String appIconUrl;
  final String packageName;
  final String developerName;
  final String description;
}

class ProfileStatisticsScreen extends StatefulWidget {
  const ProfileStatisticsScreen({
    super.key,
    required this.uid,
    this.filterAppId,
  });

  final String uid;
  final String? filterAppId;

  @override
  State<ProfileStatisticsScreen> createState() =>
      _ProfileStatisticsScreenState();
}

class _ProfileStatisticsScreenState extends State<ProfileStatisticsScreen> {
  bool _loading = true;
  String? _error;

  Map<String, List<_ProofEntry>> _grouped = {};
  List<String> _sortedDates = [];
  int _openCount = 0;
  int _groupCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });

    try {
      final groupsSnap = await FirebaseFirestore.instance
          .collection('groups')
          .where('status', whereIn: ['active', 'completed', 'forming'])
          .get();

      final groups = groupsSnap.docs
          .map(RoomModel.fromDoc)
          .where((g) => g.apps.containsKey(widget.uid))
          .toList();

      final results = await Future.wait([
        _fetchOpenReports(),
        _fetchGroupReports(groups),
      ]);

      final openEntries = results[0];
      final groupEntries = results[1];
      final all = [...openEntries, ...groupEntries];

      final Map<String, List<_ProofEntry>> grouped = {};
      for (final entry in all) {
        final key = DateFormat('dd MMM yyyy').format(entry.windowDate);
        grouped.putIfAbsent(key, () => []).add(entry);
      }

      for (final list in grouped.values) {
        list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      }

      final sortedDates = grouped.keys.toList()
        ..sort((a, b) {
          final da = DateFormat('dd MMM yyyy').parse(a);
          final db = DateFormat('dd MMM yyyy').parse(b);
          return db.compareTo(da);
        });

      if (mounted) {
        setState(() {
          _grouped = grouped;
          _sortedDates = sortedDates;
          _openCount = openEntries.length;
          _groupCount = groupEntries.length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<String> _resolveTesterName(String uid, String? storedName) async {
    if (storedName != null && storedName.isNotEmpty) return storedName;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()?['username'] as String? ??
          doc.data()?['displayName'] as String? ??
          uid;
    } catch (_) {
      return uid;
    }
  }

  Future<List<_ProofEntry>> _fetchOpenReports() async {
    try {
      final appsSnap = await FirebaseFirestore.instance
          .collection('apps')
          .where('ownerUid', isEqualTo: widget.uid)
          .get();

      if (appsSnap.docs.isEmpty) return [];

      final entries = <_ProofEntry>[];

      for (final appDoc in appsSnap.docs) {
        if (widget.filterAppId != null && appDoc.id != widget.filterAppId) {
          continue;
        }

        final appData = appDoc.data();
        final appName = appData['appName'] as String? ?? 'Unknown App';
        final appIcon = appData['iconUrl'] as String? ?? '';
        final pkgName = appData['packageName'] as String? ?? '';
        final devName = appData['developerName'] as String? ?? '';
        final desc = appData['description'] as String? ?? '';

        final reportsSnap = await FirebaseFirestore.instance
            .collection('report')
            .where('appId', isEqualTo: appDoc.id)
            .get();

        for (final rDoc in reportsSnap.docs) {
          final d = rDoc.data();
          final createdAt =
              (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final testerUid = d['userId'] as String? ?? '';

          final testerName = await _resolveTesterName(
            testerUid,
            d['userName'] as String?,
          );

          entries.add(
            _ProofEntry(
              testerUid: testerUid,
              testerName: testerName,
              screenshotUrl: d['screenshotUrl'] as String? ?? '',
              submittedAt: createdAt,
              windowDate: createdAt,
              issueType: d['problemType'] as String?,
              reportText: d['description'] as String?,
              source: _ReportSource.open,
              appName: appName,
              appIconUrl: appIcon,
              packageName: pkgName,
              developerName: devName,
              description: desc,
            ),
          );
        }
      }
      return entries;
    } catch (e) {
      debugPrint('[ProfileStats] fetchOpenReports error: $e');
      return [];
    }
  }

  Future<List<_ProofEntry>> _fetchGroupReports(List<RoomModel> groups) async {
    final entries = <_ProofEntry>[];

    for (final group in groups) {
      final myApp = group.apps[widget.uid];
      if (myApp == null) continue;

      if (widget.filterAppId != null &&
          myApp.packageName != widget.filterAppId) {
        continue;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('group_tested')
            .doc(group.uniqueId)
            .get();

        if (!doc.exists) continue;
        final data = doc.data() as Map<String, dynamic>;

        for (int d = 1; d <= 14; d++) {
          final dayMap = data['day-$d'] as Map<String, dynamic>?;
          if (dayMap == null) continue;

          for (final entry in dayMap.entries) {
            final parts = entry.key.split('_');
            if (parts.length < 2) continue;
            if (parts.last != widget.uid) continue;

            final map = entry.value as Map<String, dynamic>?;
            if (map == null) continue;

            final submittedAt =
                (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final windowDate =
                (map['windowDate'] as Timestamp?)?.toDate() ?? submittedAt;

            entries.add(
              _ProofEntry(
                testerUid: map['uid'] as String? ?? '',
                testerName: map['userName'] as String? ?? 'Unknown',
                screenshotUrl: map['screenshotUrl'] as String? ?? '',
                submittedAt: submittedAt,
                windowDate: windowDate,
                issueType: map['issueType'] as String?,
                reportText: map['reportText'] as String?,
                source: _ReportSource.group,
                appName: myApp.appName,
                appIconUrl: myApp.iconUrl,
                packageName: myApp.packageName,
                developerName: myApp.developerName,
                description: myApp.description,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint(
          '[ProfileStats] fetchGroupReports error '
          'for ${group.uniqueId}: $e',
        );
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          color: cs.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistics',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(cs, tt),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('Failed to load reports', style: tt.titleMedium),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sortedDates.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _SummaryBar(
            totalReports: _openCount + _groupCount,
            totalDays: _sortedDates.length,
          ),
          const SizedBox(height: 20),
          for (final dateKey in _sortedDates) ...[
            _DateSection(dateLabel: dateKey, entries: _grouped[dateKey]!),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totalReports, required this.totalDays});

  final int totalReports, totalDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(baseBorderRadius),
        border: Border.all(color: _blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _SummaryItem(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Total Reports',
            value: '$totalReports',
            color: _blue,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 36, color: _blue.withOpacity(0.15)),
          const SizedBox(width: 8),
          _SummaryItem(
            icon: Icons.calendar_month_rounded,
            label: 'Active Days',
            value: '$totalDays',
            color: _green,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatefulWidget {
  const _DateSection({required this.dateLabel, required this.entries});
  final String dateLabel;
  final List<_ProofEntry> entries;

  @override
  State<_DateSection> createState() => _DateSectionState();
}

class _DateSectionState extends State<_DateSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expand, _fade, _chevron;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 0.0,
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
    _chevron = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final count = widget.entries.length;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final borderColor = Color.lerp(cs.outline, _blue, t)!;

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(baseBorderRadius),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(baseBorderRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _toggle,
                  splashColor: _blue.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.08 + 0.06 * t),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color.lerp(
                                cs.outline,
                                _blue,
                                t,
                              )!.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Color.lerp(cs.onSurface, _blue, t),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.dateLabel,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Color.lerp(cs.primary, _blue, t),
                                ),
                              ),
                              Text(
                                '$count report${count == 1 ? '' : 's'}',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _blue.withOpacity(0.25)),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RotationTransition(
                          turns: _chevron,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color.lerp(cs.onSurface, _blue, t),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizeTransition(
                  sizeFactor: _expand,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(height: 1, thickness: 1, color: cs.outline),
                        for (int i = 0; i < widget.entries.length; i++) ...[
                          _ProofCard(entry: widget.entries[i]),
                          if (i < widget.entries.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color: cs.outline,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({required this.entry});
  final _ProofEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final time = DateFormat('hh:mm a').format(entry.submittedAt);

    return InkWell(
      onTap: () => showTestDetailSheet(
        context,
        testerUid: entry.testerUid,
        testerName: entry.testerName,
        screenshotUrl: entry.screenshotUrl,
        submittedAt: entry.submittedAt,
        appDetails: AppDetails(
          appName: entry.appName,
          iconUrl: entry.appIconUrl,
          packageName: entry.packageName,
          developerName: entry.developerName,
          description: entry.description,
        ),
        issueType: entry.issueType,
        reportText: entry.reportText,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                color: cs.primaryContainer,
                child: entry.appIconUrl.isNotEmpty
                    ? Image.network(
                        entry.appIconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _IconFallback(name: entry.appName),
                      )
                    : _IconFallback(name: entry.appName),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.appName,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.reportText != null &&
                          entry.reportText!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Icon(Icons.bug_report, color: Colors.red, size: 16),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        time,
                        style: tt.labelSmall?.copyWith(color: cs.onPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${entry.testerName}',
                    style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _blue.withOpacity(0.2), width: 2),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 36,
                color: _blue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Reports Yet',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Reports from Discovery and Room\n'
              'will appear here once members start testing.',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    color: _deepBlue.withOpacity(0.08),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _deepBlue,
      ),
    ),
  );
}
