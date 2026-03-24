import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../widget/list tile/app_icon.dart';
import '../service/group_model.dart';
import '../service/group_service.dart';
import '../sheet/testing_bottom_sheet.dart';

const _blue = Color(0xFF1565C0);
const _orange = Color(0xFFFF9800);
const _green = Color(0xFF2E7D32);


class MandatoryTaskCard extends StatefulWidget {
  const MandatoryTaskCard({
    super.key,
    required this.groupId,
    required this.currentUid,
    required this.currentUsername,
    required this.member,
    required this.appDetails,
    required this.taskStartDate,
    this.onStatusChanged, // Add this
  });

  final String groupId;
  final String currentUid;
  final String currentUsername;
  final GroupMember member;
  final AppDetails appDetails;
  final DateTime taskStartDate;
  final void Function(ProofStatus status)? onStatusChanged; // Add this

  @override
  State<MandatoryTaskCard> createState() => _MandatoryTaskCardState();
}

class _MandatoryTaskCardState extends State<MandatoryTaskCard> {
  ProofStatus _status = ProofStatus.none;
  StreamSubscription<DocumentSnapshot>? _proofSub;

  // Pre-compute the day number once on mount — the card is re-created by
  // _UnifiedTaskList on every day rollover (via dayKey in the ValueKey),
  // so this value is always fresh.
  late final int _dayNumber =
      (DateTime.now().difference(widget.taskStartDate).inHours ~/ 24 + 1).clamp(
        1,
        14,
      );

  // The map key used in Firestore: submitterId_targetId
  late final String _taskKey = '${widget.currentUid}_${widget.member.uid}';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _subscribeToProofStatus();
  }

  @override
  void dispose() {
    _proofSub?.cancel();
    super.dispose();
  }

  // ── Real-time proof status ─────────────────────────────────────────────────

  void _subscribeToProofStatus() {
    _proofSub = FirebaseFirestore.instance
        .collection('group_tested')
        .doc(widget.groupId)
        .snapshots()
        .listen(_onSnapshot);
  }

  void _onSnapshot(DocumentSnapshot snap) {
    if (!mounted) return;

    ProofStatus status = ProofStatus.none;

    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      final dayMap = data['day-$_dayNumber'] as Map<String, dynamic>? ?? {};
      final entry = dayMap[_taskKey] as Map<String, dynamic>?;

      if (entry != null) {
        status = switch (entry['approvalStatus'] as String?) {
          'approved' => ProofStatus.approved,
          'retestRequired' => ProofStatus.retestRequired,
          'waitingApproval' => ProofStatus.waitingApproval,
          _ => ProofStatus.none,
        };
      }
    }

    // Only update and notify if status actually changed
    if (status != _status) {
      setState(() => _status = status);
      widget.onStatusChanged?.call(status); // Notify parent
    }
  }

  // ── Testing sheet ──────────────────────────────────────────────────────────

  // _checkProof satisfies the required onSubmitted param of showTestingSheet.
  // The Firestore stream already auto-updates _status, so this is just a
  // fast-path safety net for any slight stream delivery delay.
  Future<void> _checkProof() async {
    final status = await GroupService.instance.getTodayProofStatus(
      groupId: widget.groupId,
      uid: widget.currentUid,
      targetUserId: widget.member.uid,
      taskStartDate: widget.taskStartDate,
    );
    if (mounted) setState(() => _status = status);
  }

  void _openTestingSheet() {
    showTestingSheet(
      context,
      groupId: widget.groupId,
      uid: widget.currentUid,
      username: widget.currentUsername,
      targetUserId: widget.member.uid,
      targetName: widget.appDetails.developerName,
      appDetails: widget.appDetails,
      taskStartDate: widget.taskStartDate,
      onSubmitted: _checkProof, // stream also fires — harmless double-update
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        // ── App icon ──────────────────────────────────────────────────
        AppIcon(
          imageUrl: widget.appDetails.iconUrl,
          size: 48,
          borderRadius: 10,
        ),
        const SizedBox(width: 14),

        // ── App name + developer ──────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.appDetails.appName,
                style: tt.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '@${widget.member.username}',
                style: tt.bodySmall!.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // ── Action — switches smoothly as status changes ───────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_status) {
            ProofStatus.approved => const _StatusChip(
              key: ValueKey('approved'),
              label: 'Tested',
              icon: Icons.verified_rounded,
              color: _green,
            ),
            ProofStatus.waitingApproval => const _StatusChip(
              key: ValueKey('waiting'),
              label: 'In Review',
              icon: Icons.hourglass_top_rounded,
              color: _orange,
            ),
            ProofStatus.retestRequired => _RetestButton(
              key: const ValueKey('retest'),
              onOpenTesting: _openTestingSheet,
            ),
            ProofStatus.none => _SmartAppButton(
              key: const ValueKey('action'),
              packageName: widget.appDetails.packageName,
              onOpenTesting: _openTestingSheet,
            ),
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SmartAppButton  —  Install or Test Now depending on install state
// ─────────────────────────────────────────────────────────────────────────────

class _SmartAppButton extends StatefulWidget {
  const _SmartAppButton({
    super.key,
    required this.packageName,
    required this.onOpenTesting,
  });

  final String packageName;
  final VoidCallback onOpenTesting;

  @override
  State<_SmartAppButton> createState() => _SmartAppButtonState();
}

class _SmartAppButtonState extends State<_SmartAppButton>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final installed = await LaunchApp.isAppInstalled(
        androidPackageName: widget.packageName,
      );
      if (mounted && installed != _installed) {
        setState(() => _installed = installed);
      }
    } catch (_) {}
  }

  Future<void> _openPlayStore() async {
    final pkg = widget.packageName;
    final marketUri = Uri.parse('market://details?id=$pkg');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$pkg',
    );
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        _timer?.cancel();
        _timer = Timer.periodic(
          const Duration(seconds: 4),
          (_) => _checkStatus(),
        );
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch Play Store: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_installed) {
      return OutlinedButton.icon(
        onPressed: widget.onOpenTesting,
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: const Text('Test Now'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _blue,
          side: const BorderSide(color: _blue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _openPlayStore,
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text('Install'),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RetestButton
// ─────────────────────────────────────────────────────────────────────────────

class _RetestButton extends StatelessWidget {
  const _RetestButton({super.key, required this.onOpenTesting});
  final VoidCallback onOpenTesting;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onOpenTesting,
      icon: const Icon(Icons.replay_rounded, size: 16),
      label: const Text('Retest'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepOrange,
        side: const BorderSide(color: Colors.deepOrange, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusChip  —  read-only status pill (Approved / In Review)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
