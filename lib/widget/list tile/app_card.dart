import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/height_width.dart';
import '../../screen/open_testers/provider/publish_provider.dart';
import '../../screen/open_testers/publish_app/app_listing_screen.dart';
import '../../screen/profile/profile_statistics_screen.dart';
import '../../theme/colors.dart';
import '../../widget/button/custom_buttons.dart';
import '../../widget/dialog/confirm_dialog.dart';
import '../../widget/snackbar/custom_snackbar.dart';
import 'app_icon.dart';

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.docId,
    required this.iconUrl,
    required this.appName,
    required this.developer,
    required this.packageName,
    required this.description,
    required this.testerCount,
    required this.maxTesters,
    required this.isBoosted,
    required this.isFull,
    required this.createdAt,
    required this.ownerUid,
  });

  final String     docId;
  final String     iconUrl;
  final String     appName;
  final String     developer;
  final String     packageName;
  final String     description;
  final int        testerCount;
  final int        maxTesters;
  final bool       isBoosted;
  final bool       isFull;
  final Timestamp? createdAt;
  final String     ownerUid;


  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isDeleting = false;



  String _fmt(DateTime dt) => '${_kMonths[dt.month - 1]} ${dt.day}, ${dt.year}';

  void _seedProvider() {
    final p = context.read<PublishProvider>();
    p.reset();
    p.setStep3AppName(widget.appName);
    p.setStep3Developer(widget.developer);
    p.setStep3PackageName(widget.packageName);
    p.setStep3Description(widget.description);
    if (widget.iconUrl.isNotEmpty) p.setIconUrl(widget.iconUrl);
  }

  void _openEdit() {
    _seedProvider();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:  (_) => const AppListingScreen(mode: PublishFlowMode.edit),
        settings: RouteSettings(arguments: widget.docId),
      ),
    );
  }

  void _openRepublish() {
    _seedProvider();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:  (_) => const AppListingScreen(mode: PublishFlowMode.republish),
        settings: RouteSettings(arguments: widget.docId),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title:        'Delete App?',
      message:      'This will permanently remove "${widget.appName}".\n'
          'This action is permanent and coins will NOT be refunded.',
      confirmLabel: 'Delete',
      cancelLabel:  'Cancel',
      icon:         Icons.delete_rounded,
      iconColor:    Theme.of(context).colorScheme.error,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final appRef  = FirebaseFirestore.instance.collection('apps').doc(widget.docId);
        final appSnap = await txn.get(appRef);
        if (!appSnap.exists) return;
        txn.delete(appRef);
      });
      if (!mounted) return;
      CustomSnackbar.show(context,
          title:   'Deleted',
          message: '${widget.appName} deleted successfully.',
          type:    SnackBarType.success);
    } catch (_) {
      if (!mounted) return;
      CustomSnackbar.show(context,
          title:   'Error',
          message: 'Could not delete app. Try again.',
          type:    SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final tt  = Theme.of(context).textTheme;
    final pct = widget.maxTesters > 0
        ? (widget.testerCount / widget.maxTesters).clamp(0.0, 1.0)
        : 0.0;
    final dateStr = widget.createdAt != null
        ? _fmt(widget.createdAt!.toDate())
        : '';
    final isEffectivelyFull = widget.isFull || widget.testerCount >= widget.maxTesters;


    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outline,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App info row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileStatisticsScreen(
                    uid:    widget.ownerUid,
                    filterAppId: widget.docId,
                  ),
                ),
              ),
              child: Row(
                children: [
                  AppIcon(imageUrl: widget.iconUrl, size: 52, borderRadius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(widget.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.titleMedium),
                            ),
                            if (widget.isBoosted) ...[
                              const SizedBox(width: 6),
                              const _BoostedBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(widget.developer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:        cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border:       Border.all(color: cs.outline),
                          ),
                          child: Icon(Icons.bar_chart_rounded,
                              size: 16, color: cs.onSurface),
                        ),
                      const SizedBox(width: 6),
                      _StatusBadge(isFull: isEffectivelyFull),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: cs.outline,
          ),
          const SizedBox(height: 10),

          // ── Progress + actions ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Icon(Icons.people_outline_rounded,
                                size: 12, color: cs.onSurface),
                            const SizedBox(width: 4),
                            Text('Testers', style: tt.labelSmall),
                          ]),
                          Text('${widget.testerCount} / ${widget.maxTesters}',
                              style: tt.labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:           pct,
                          minHeight:       5,
                          backgroundColor: cs.outline,
                          color: widget.isFull
                              ? blue
                              : blue.withOpacity(0.5),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 11, color: cs.onSurface),
                          const SizedBox(width: 4),
                          Text(dateStr,
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.onSurfaceVariant)),
                        ]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                isEffectivelyFull
                    ? _FullActions(
                  isDeleting:  _isDeleting,
                  onRepublish: _openRepublish,
                  onDelete:    _delete,
                )
                    : _ActiveActions(
                  isDeleting: _isDeleting,
                  onEdit:     _openEdit,
                  onDelete:   _delete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action rows
// ─────────────────────────────────────────────────────────────────────────────

class _FullActions extends StatelessWidget {
  const _FullActions({
    required this.isDeleting,
    required this.onRepublish,
    required this.onDelete,
  });
  final bool         isDeleting;
  final VoidCallback onRepublish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomOutlineBtn(
        label:        'Republish',
        onPressed:    onRepublish,
        size:         BtnSize.small,
        borderRadius: 10,
        prefixIcon:   Icons.rocket_launch_rounded,
      ),
      const SizedBox(width: 8),
      CustomElevatedBtn(
        label:        isDeleting ? '...' : 'Delete',
        onPressed:    isDeleting ? null : onDelete,
        isLoading:    isDeleting,
        size:         BtnSize.small,
        borderRadius: 10,
        prefixIcon:   Icons.delete_rounded,
      ),
    ],
  );
}

class _ActiveActions extends StatelessWidget {
  const _ActiveActions({
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });
  final bool         isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomOutlineBtn(
          label:        'Edit',
          onPressed:    onEdit,
          size:         BtnSize.small,
          borderRadius: 10,
          prefixIcon:   Icons.edit_outlined,
        ),
        const SizedBox(width: 8),
        CustomOutlineBtn(
          label:           isDeleting ? 'Deleting..' : 'Delete',
          onPressed:       isDeleting ? null : onDelete,
          isLoading:       isDeleting,
          size:            BtnSize.small,
          borderRadius:    10,
          borderColor:     cs.error.withOpacity(0.5),
          foregroundColor: cs.error,
          prefixIcon:      Icons.delete_outline_rounded,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Badges
// ─────────────────────────────────────────────────────────────────────────────

class _BoostedBadge extends StatelessWidget {
  const _BoostedBadge();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: .all(4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: .circular(6),
        border: .all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded,
              size: 16, color: Colors.amber),
          Text('Boosted',style: tt.labelSmall!.copyWith(
            color: Colors.amber
          ),)
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isFull});
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    final tt    = Theme.of(context).textTheme;
    final color = isFull ? green : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isFull ? 'Completed' : 'Active',
        style: tt.labelSmall?.copyWith(
            color:      color,
            fontWeight: FontWeight.w700,
            fontSize:   11),
      ),
    );
  }
}