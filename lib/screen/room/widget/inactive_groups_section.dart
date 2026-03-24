import 'package:flutter/material.dart';
import '../../../models/room_model.dart';
import '../../../services/room_service.dart';

const _deepBlue = Color(0xFF1A237E);
const _green = Color(0xFF2E7D32);

class InactiveGroupsSection extends StatelessWidget {
  const InactiveGroupsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: RoomService.instance.watchAllGroups(),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final active = all.where((g) => g.status == RoomStatus.active).toList();
        final completed = all
            .where((g) => g.status == RoomStatus.completed)
            .toList();

        if (active.isEmpty && completed.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active.isNotEmpty) ...[
              _GroupListSection(
                title: 'Active Rooms',
                icon: Icons.groups_rounded,
                color: _deepBlue,
                groups: active,
              ),
            ],
            if (active.isNotEmpty && completed.isNotEmpty)
              const SizedBox(height: 24),
            if (completed.isNotEmpty) ...[
              _GroupListSection(
                title: 'Completed Groups',
                icon: Icons.verified_rounded,
                color: _green,
                groups: completed,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GroupListSection extends StatelessWidget {
  const _GroupListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.groups,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<RoomModel> groups;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${groups.length}',
                  style: tt.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: groups.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withOpacity(0.4),
          ),
          itemBuilder: (_, i) =>
              _GroupTile(group: groups[i], accentColor: color),
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.accentColor});

  final RoomModel group;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isComplete = group.status == RoomStatus.completed;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Center(
          child: Icon(
            isComplete ? Icons.check_circle_rounded : Icons.group_rounded,
            size: 22,
            color: accentColor,
          ),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 15, color: Colors.amber),
          SizedBox(width: 2),
          Text(
            group.uniqueId,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      subtitle: Text(
        '${group.members.length} / ${group.maxMembers} members',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: _StatusBadge(group: group, color: accentColor),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.group, required this.color});

  final RoomModel group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isCompleted = group.status == RoomStatus.completed;

    final label = isCompleted ? 'Completed' : 'Active';
    final icon = isCompleted
        ? Icons.verified_rounded
        : Icons.play_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
