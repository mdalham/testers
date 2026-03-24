import 'dart:io';
import 'package:flutter/material.dart';
import '../../../controllers/height_width.dart';


class IconUploadBox extends StatelessWidget {
  const IconUploadBox({
    super.key,
    required this.pickedImage,
    required this.uploadedUrl,
    required this.isUploading,
    required this.onTap,
    this.height = 180,
    this.borderRadius,
    this.thumbnailSize = 80,
  });

  /// A locally picked [File] (shown immediately after picking).
  final File? pickedImage;

  /// The remote URL returned after a successful upload.
  final String? uploadedUrl;

  /// While `true` the uploading spinner is shown and [onTap] is ignored.
  final bool isUploading;

  /// Called when the user taps the box. Pass `null` to disable taps.
  final VoidCallback? onTap;

  /// Overall height of the box. Defaults to `180`.
  final double height;

  /// Corner radius. Defaults to [textFromFieldBorderRadius].
  final double? borderRadius;

  /// Width/height of the thumbnail when an icon is ready. Defaults to `80`.
  final double thumbnailSize;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;
    final hasFile  = pickedImage != null;
    final isReady  = uploadedUrl != null && uploadedUrl!.isNotEmpty;
    final radius   = borderRadius ?? textFromFieldBorderRadius.toDouble();

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: AnimatedContainer(
        duration:   const Duration(milliseconds: 250),
        width:      double.infinity,
        height:     height,
        decoration: BoxDecoration(
          color:        cs.primaryContainer,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isReady ? cs.primary : cs.outline,
            width: isReady ? 2 : 1.5,
          ),
        ),
        child: isUploading
            ? _UploadingState(tt: tt, cs: cs)
            : isReady
            ? _ReadyState(
          pickedImage:   pickedImage,
          uploadedUrl:   uploadedUrl!,
          hasFile:       hasFile,
          thumbnailSize: thumbnailSize,
          radius:        radius,
          tt:            tt,
          cs:            cs,
        )
            : _EmptyState(tt: tt, cs: cs),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  State sub-widgets (private)
// ─────────────────────────────────────────────────────────────────────────────

class _UploadingState extends StatelessWidget {
  const _UploadingState({required this.tt, required this.cs});
  final TextTheme   tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue),
        ),
        const SizedBox(height: 10),
        Text('Uploading icon...', style: tt.labelMedium),
      ],
    );
  }
}

class _ReadyState extends StatelessWidget {
  const _ReadyState({
    required this.pickedImage,
    required this.uploadedUrl,
    required this.hasFile,
    required this.thumbnailSize,
    required this.radius,
    required this.tt,
    required this.cs,
  });
  final File?       pickedImage;
  final String      uploadedUrl;
  final bool        hasFile;
  final double      thumbnailSize;
  final double      radius;
  final TextTheme   tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: hasFile
              ? Image.file(pickedImage!,
              width: thumbnailSize, height: thumbnailSize, fit: BoxFit.cover)
              : Image.network(
            uploadedUrl,
            width:        thumbnailSize,
            height:       thumbnailSize,
            fit:          BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width:  thumbnailSize,
              height: thumbnailSize,
              color:  cs.primaryContainer,
              child:  Icon(Icons.broken_image_outlined, color: cs.primary),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:  MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Icon uploaded',
                    style: tt.labelLarge?.copyWith(
                      color:      cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Tap to change',
                  style: tt.labelSmall?.copyWith(color: cs.onPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tt, required this.cs});
  final TextTheme   tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color:        cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Icon(Icons.add_photo_alternate_outlined,
              size: 24, color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        Text(
          'Upload App Icon',
          style: tt.titleSmall
              ?.copyWith(color: cs.primary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text('Tap to choose from gallery',
            style: tt.labelSmall?.copyWith(color: cs.onPrimary)),
      ],
    );
  }
}