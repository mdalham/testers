import 'package:flutter/material.dart';

class LastUpdated extends StatelessWidget {
  final String text;
  const LastUpdated({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurface),
          const SizedBox(width: 8),
          Text(
            text,
            style: tt.labelSmall?.copyWith(color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}