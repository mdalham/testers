import 'dart:io';
import 'package:flutter/material.dart';

const _blue  = Color(0xFF1565C0);
const _green = Color(0xFF2E7D32);

class ScreenshotUpload extends StatefulWidget {
  const ScreenshotUpload({
    super.key,
    required this.onTap,
    this.file,
    this.uploading = false,
    this.uploaded  = false,
    this.uploadError,
  });

  final File?          file;
  final bool           uploading;
  final bool           uploaded;
  final String?        uploadError;
  final VoidCallback   onTap;

  @override
  State<ScreenshotUpload> createState() => _ScreenshotUploadState();
}

class _ScreenshotUploadState extends State<ScreenshotUpload> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasError   = widget.uploadError != null && !widget.uploading && !widget.uploaded;
    final hasPreview = widget.file != null;

    Color borderColor = cs.outlineVariant.withOpacity(0.5);
    if (widget.uploaded)   borderColor = _green;
    if (hasError)   borderColor = Colors.red.withOpacity(0.6);
    if (widget.uploading)  borderColor = _blue.withOpacity(0.4);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width:    double.infinity,
        decoration: BoxDecoration(
          color:        cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: borderColor, width: widget.uploaded ? 1.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildBody(context, cs, hasError, hasPreview),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      ColorScheme  cs,
      bool         hasError,
      bool         hasPreview,
      ) {
    final tt = Theme.of(context).textTheme;

    // ── Uploading ────────────────────────────────────────────────────────────
    if (widget.uploading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56, height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth:     3,
                    color:           _blue,
                    backgroundColor: _blue.withOpacity(0.12),
                  ),
                ),
                Icon(Icons.cloud_upload_rounded, size: 22, color: _blue),
              ],
            ),
            const SizedBox(height: 12),
            Text('Uploading screenshot…',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Please wait',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    // ── Preview ──────────────────────────────────────────────────────────────
    if (hasPreview) {
      return Stack(
        children: [
          SizedBox(
            width:  double.infinity,
            height: 200,
            child:  Image.file(widget.file!, fit: BoxFit.cover),
          ),

          // gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:  Alignment.topCenter,
                  end:    Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // status badge (top-right)
          Positioned(
            top: 10, right: 10,
            child: _StatusBadge(uploaded: widget.uploaded),
          ),

          // bottom row
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: Row(
              children: [
                Icon(
                  widget.uploaded
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  size:  14,
                  color: widget.uploaded ? Colors.greenAccent : Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.uploaded
                        ? 'Screenshot uploaded successfully'
                        : 'Processing upload…',
                    style: TextStyle(
                      fontSize:   11,
                      color:      widget.uploaded ? Colors.greenAccent : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:        Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 10, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('Change',
                          style: tt.bodySmall?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color:  Colors.red.withOpacity(0.1),
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 26, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Text('Upload Failed',
                style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: Colors.red)),
            const SizedBox(height: 4),
            Text(
              widget.uploadError!,
              style:      tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign:  TextAlign.center,
              maxLines:   2,
              overflow:   TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:        Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded,
                      size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Text('Tap to retry',
                      style: tt.labelMedium?.copyWith(
                          color:      Colors.red,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Empty / default ──────────────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color:  _blue.withOpacity(0.07),
              shape:  BoxShape.circle,
              border: Border.all(
                  color: _blue.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(Icons.add_photo_alternate_rounded,
                size: 30, color: _blue.withOpacity(0.7)),
          ),
          const SizedBox(height: 14),
          Text('Tap to upload screenshot',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('PNG or JPG',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _HintPill(icon: Icons.image_rounded,         label: 'Gallery'),
              SizedBox(width: 8),
              _HintPill(icon: Icons.cloud_upload_outlined, label: 'Auto-upload'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Private helpers
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.uploaded});
  final bool uploaded;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: uploaded
          ? _green.withOpacity(0.85)
          : Colors.black.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          uploaded ? Icons.check_circle_rounded : Icons.pending_rounded,
          size:  12,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          uploaded ? 'Uploaded' : 'Uploading…',
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize:   11,
                  color:      cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}