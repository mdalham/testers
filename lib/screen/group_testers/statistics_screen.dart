import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testers/controllers/height_width.dart';
import 'package:testers/screen/group_testers/service/group_model.dart';
import 'package:testers/screen/group_testers/sheet/test_detail_sheet.dart';

const _blue = Color(0xFF1565C0);
const _deepBlue = Color(0xFF1A237E);
const _orange = Color(0xFFFF9800);
const _green = Color(0xFF2E7D32);

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single proof entry
// ─────────────────────────────────────────────────────────────────────────────

class _ProofEntry {
  _ProofEntry({
    required this.testerUid,
    required this.testerName,
    required this.screenshotUrl,
    required this.submittedAt,
    required this.windowDate,
    required this.issueType,
    required this.reportText,
    required this.appDetails,
  });

  final String testerUid;
  final String testerName;
  final String screenshotUrl;
  final DateTime submittedAt; // exact timestamp → shown as "hh:mm a"
  final DateTime windowDate; // calendar date   → used for section grouping
  final String? issueType;
  final String? reportText;
  final AppDetails appDetails;

  factory _ProofEntry.fromMap(Map<String, dynamic> map, AppDetails app) {
    final submittedAt =
        (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    // Use windowDate for the section group label (March 7, March 8 …).
    // Fall back to submittedAt for older records that don't have windowDate.
    final windowDate =
        (map['windowDate'] as Timestamp?)?.toDate() ?? submittedAt;

    return _ProofEntry(
      testerUid: map['uid'] as String? ?? '',
      testerName: map['userName'] as String? ?? 'Unknown',
      screenshotUrl: map['screenshotUrl'] as String? ?? '',
      submittedAt: submittedAt,
      windowDate: windowDate,
      issueType: map['issueType'] as String?,
      reportText: map['reportText'] as String?,
      appDetails: app,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StatisticsScreen
// ─────────────────────────────────────────────────────────────────────────────

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.groupId,
    required this.uid,
    required this.group,
  });

  final String groupId;
  final String uid;
  final GroupModel group;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  String? _error;
  // date string (e.g. "12 Feb 2026") → list of proof entries
  Map<String, List<_ProofEntry>> _grouped = {};
  List<String> _sortedDates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('group_tested')
          .doc(widget.groupId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final myApp = widget.group.apps[widget.uid];
      if (myApp == null) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final Map<String, List<_ProofEntry>> grouped = {};

      for (int d = 1; d <= 14; d++) {
        final dayMap = data['day-$d'] as Map<String, dynamic>?;
        if (dayMap == null) continue;

        for (final entry in dayMap.entries) {
          // key = "{testerUid}_{targetUid}" — only keep entries targeting me
          final parts = entry.key.split('_');
          if (parts.length < 2) continue;
          final targetUid = parts.last;
          if (targetUid != widget.uid) continue;

          final map = entry.value as Map<String, dynamic>?;
          if (map == null) continue;

          final proof = _ProofEntry.fromMap(map, myApp);

          // Group by windowDate (the logical calendar date of the day-window),
          // NOT by submittedAt — this ensures a submission at e.g. 1:30 AM
          // on March 7 that belongs to the March 7 window is shown under
          // "07 Mar 2026", and one submitted at 3:00 AM after the 2:30 AM
          // reset is correctly shown under "08 Mar 2026".
          final dateKey = DateFormat('dd MMM yyyy').format(proof.windowDate);
          grouped.putIfAbsent(dateKey, () => []).add(proof);
        }
      }

      // Sort dates descending (newest first)
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Reports received for your app',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
        ],
      ),
      body: _buildBody(cs, tt),
    );
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            ],
          ),
        ),
      );
    }

    if (_sortedDates.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loading = true);
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Summary bar ───────────────────────────────────────────────
          _SummaryBar(
            totalReports: _grouped.values.fold(0, (s, l) => s + l.length),
            totalDays: _sortedDates.length,
          ),
          const SizedBox(height: 20),

          // ── Date sections ─────────────────────────────────────────────
          for (final dateKey in _sortedDates) ...[
            _DateSection(dateLabel: dateKey, entries: _grouped[dateKey]!),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SummaryBar
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.totalReports, required this.totalDays});
  final int totalReports;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: .circular(10),
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
                style: tt.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DateSection  —  expandable card for a single date
// ─────────────────────────────────────────────────────────────────────────────

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
  late Animation<double> _expand;
  late Animation<double> _fade;
  late Animation<double> _chevron;

  // 1. Start as closed
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      // 2. Set initial value to 0.0 (collapsed)
      value: 0.0,
    );

    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    // Note: If you want the chevron to animate from 0 to 0.5 when opening,
    // this logic remains correct.
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
        final borderColor = Color.lerp(cs.outlineVariant, _blue, t)!;

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04 + 0.04 * t),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────
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
                                cs.outlineVariant,
                                _blue,
                                t,
                              )!.withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: Color.lerp(cs.onSurfaceVariant, _blue, t),
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
                                  color: Color.lerp(cs.onSurface, _deepBlue, t),
                                ),
                              ),
                              Text(
                                '$count report${count == 1 ? '' : 's'}',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Report count badge
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
                            style: TextStyle(
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
                            color: Color.lerp(cs.onSurfaceVariant, _blue, t),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                SizeTransition(
                  sizeFactor: _expand,
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: cs.outlineVariant.withOpacity(0.3),
                        ),
                        for (int i = 0; i < widget.entries.length; i++) ...[
                          _ProofCard(entry: widget.entries[i]),
                          if (i < widget.entries.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color: cs.outlineVariant.withOpacity(0.25),
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

// ─────────────────────────────────────────────────────────────────────────────
// _ProofCard  —  single testing report row
// ─────────────────────────────────────────────────────────────────────────────

class _ProofCard extends StatelessWidget {
  const _ProofCard({required this.entry});
  final _ProofEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    // Show the exact submission time (not the window date)
    final time = DateFormat('hh:mm a').format(entry.submittedAt);

    return InkWell(
      onTap: () => showTestDetailSheet(
        context,
        testerUid: entry.testerUid,
        testerName: entry.testerName,
        screenshotUrl: entry.screenshotUrl,
        submittedAt: entry.submittedAt,
        appDetails: entry.appDetails,
        issueType: entry.issueType,
        reportText: entry.reportText,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App icon ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                color: cs.surfaceContainerHigh,
                child: entry.appDetails.iconUrl.isNotEmpty
                    ? Image.network(
                        entry.appDetails.iconUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _IconFallback(name: entry.appDetails.appName),
                      )
                    : _IconFallback(name: entry.appDetails.appName),
              ),
            ),
            const SizedBox(width: 12),

            // ── Text content ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name + time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.appDetails.appName,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Tester name
                  Row(
                    children: [
                      Text(
                        '@${entry.testerName}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
              'Testing reports for your app will appear here '
              'once group members start testing.',
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

// ─────────────────────────────────────────────────────────────────────────────
// _IconFallback
// ─────────────────────────────────────────────────────────────────────────────

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
