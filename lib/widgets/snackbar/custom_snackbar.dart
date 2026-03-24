import 'package:flutter/material.dart';




enum SnackBarType { success, error, info }




class CustomSnackbar {
  CustomSnackbar._();

  static void show(
      BuildContext context, {
        required String message,
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 3),
        String? title,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;
    _insert(overlay,
        message: message,
        type: type,
        duration: duration,
        title: title,
        actionLabel: actionLabel,
        onAction: onAction);
  }

  
  
  static void showOnOverlay(
      OverlayState overlay, {
        required String message,
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 3),
        String? title,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    _insert(overlay,
        message: message,
        type: type,
        duration: duration,
        title: title,
        actionLabel: actionLabel,
        onAction: onAction);
  }

  static void _insert(
      OverlayState overlay, {
        required String message,
        required SnackBarType type,
        required Duration duration,
        String? title,
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnackbarOverlay(
        message: message,
        type: type,
        duration: duration,
        title: title,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}




class _SnackbarOverlay extends StatefulWidget {
  const _SnackbarOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SnackBarType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_SnackbarOverlay> createState() => _SnackbarOverlayState();
}

class _SnackbarOverlayState extends State<_SnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _SnackConfig _config(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (widget.type) {
      SnackBarType.success => _SnackConfig(
          bg: const Color(0xFF1E7E34),
          icon: Icons.check_circle_outline_rounded),
      SnackBarType.error =>
          _SnackConfig(bg: cs.error, icon: Icons.error_outline_rounded),
      SnackBarType.info =>
          _SnackConfig(bg: cs.primary, icon: Icons.info_outline_rounded),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _config(context);
    final mq = MediaQuery.of(context);

    return Positioned(
      top: mq.padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cfg.bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(cfg.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null) ...[
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: Colors.white
                                .withOpacity(widget.title != null ? 0.9 : 1),
                            fontSize: widget.title != null ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null &&
                      widget.onAction != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        widget.onAction!();
                        _dismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackConfig {
  const _SnackConfig({required this.bg, required this.icon});
  final Color bg;
  final IconData icon;
}