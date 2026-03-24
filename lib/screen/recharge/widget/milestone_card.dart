import 'package:flutter/material.dart';

import '../../../controllers/icons.dart';

class MilestoneCard extends StatefulWidget {
  final String title;
  final int rewardCoins;
  final int totalAds;
  final int currentProgress;
  final bool isCompleted;
  final bool isCooldownActive;
  final int cooldownSecondsRemaining;
  final bool isAdPending;
  final VoidCallback onWatchAd;

  const MilestoneCard({
    super.key,
    required this.title,
    required this.rewardCoins,
    required this.totalAds,
    required this.currentProgress,
    required this.isCompleted,
    required this.isCooldownActive,
    required this.cooldownSecondsRemaining,
    required this.onWatchAd,
    this.isAdPending = false,
  });

  @override
  State<MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<MilestoneCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showProgress = widget.totalAds > 1;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    // Accent colour switches when completed
    final Color accent = widget.isCompleted
        ? const Color(0xFF4CAF50)
        : const Color(0xFF6C63FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface,
        border: Border.all(
          color: widget.isCompleted
              ? const Color(0xFF4CAF50).withOpacity(0.45)
              : cs.outline,
          width: 1.2,
        ),
        boxShadow: widget.isCompleted
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // ── Left ─────────────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coin icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withOpacity(0.45)),
                      color: accent.withOpacity(0.08),
                    ),
                    child: Image.asset(coinIcon, width: 20, height: 20),
                  ),

                  const SizedBox(width: 10),

                  // Title + reward + optional progress chip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.title,
                          style: tt.titleSmall?.copyWith(
                            color: widget.isCompleted ? accent : null,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // Reward + progress chip row
                        Row(
                          children: [
                            Text(
                              '+${widget.rewardCoins} Coins',
                              style: tt.bodySmall?.copyWith(
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.w600,
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

            const SizedBox(width: 10),

            // ── Right: action button ─────────────────────────────────────────
            Row(
              children: [
                // Progress chip — only for multi-ad milestones
                if (showProgress) ...[
                  _ProgressChip(
                    current: widget.isCompleted
                        ? widget.totalAds
                        : widget.currentProgress,
                    total: widget.totalAds,
                    isCompleted: widget.isCompleted,
                  ),
                ],
                const SizedBox(width: 6),

                _buildActionButton(cs),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Button states ─────────────────────────────────────────────────────────

  Widget _buildActionButton(ColorScheme cs) {
    // 1. Completed
    if (widget.isCompleted) {
      return _ActionChip(
        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
        borderColor: const Color(0xFF4CAF50).withOpacity(0.4),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Color(0xFF4CAF50), size: 16),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Ad loading / playing
    if (widget.isAdPending) {
      return _ActionChip(
        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
        borderColor: const Color(0xFF6C63FF).withOpacity(0.3),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF9E97FF),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Loading',
              style: TextStyle(
                color: Color(0xFF9E97FF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Cooldown countdown
    if (widget.isCooldownActive) {
      return _ActionChip(
        backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
        borderColor: const Color(0xFF6C63FF).withOpacity(0.2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_bottom_rounded,
              color: Color(0xFF9E97FF),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.cooldownSecondsRemaining}s',
              style: const TextStyle(
                color: Color(0xFF9E97FF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    // 4. Ready — pulsing Watch button
    return GestureDetector(
      onTap: widget.onWatchAd,
      child: _ActionChip(
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
            SizedBox(width: 5),
            Text(
              'Watch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionChip — reusable pill container for all button states
// ─────────────────────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Gradient? gradient;

  const _ActionChip({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressChip — `current/total` pill shown for multi-ad milestones
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressChip extends StatelessWidget {
  final int current;
  final int total;
  final bool isCompleted;

  const _ProgressChip({
    required this.current,
    required this.total,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isCompleted
        ? const Color(0xFF4CAF50)
        : const Color(0xFF9E97FF);
    final Color borderColor = color.withOpacity(0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$current/$total',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
