import 'package:flutter/material.dart';

import 'package:testers/theme/colors.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    this.imageUrl,
    this.size = _AppIconDefaults.size,
    this.borderRadius = _AppIconDefaults.borderRadius,
    this.isFeatured = false,
  });

  final String? imageUrl;
  final double size;
  final double borderRadius;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.35,
                      height: size * 0.35,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                        color: blue,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _DefaultIcon(size: size, cs: cs),
              )
            : _DefaultIcon(size: size, cs: cs),
      ),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon({required this.size, required this.cs});

  final double size;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer,
      child: Icon(
        Icons.grid_view_rounded,
        size: size * 0.50,
        color: cs.onSurface,
      ),
    );
  }
}

abstract class _AppIconDefaults {
  static const double size = 58.0;
  static const double borderRadius = 14.0;
}
