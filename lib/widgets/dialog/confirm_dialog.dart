import 'package:flutter/material.dart';
import 'package:testers/theme/colors.dart';
import 'package:testers/widgets/button/custom_buttons.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.icon,
    required this.iconColor,
    this.cancelLabel = 'Cancel',
    this.onConfirm,
  });

  final String     title;
  final String     message;
  final String     confirmLabel;
  final String     cancelLabel;
  final IconData   icon;
  final Color      iconColor;

  
  
  
  final VoidCallback? onConfirm;

  
  static Future<bool?> show(
      BuildContext context, {
        required String   title,
        required String   message,
        required String   confirmLabel,
        required IconData icon,
        required Color    iconColor,
        String            cancelLabel = 'Cancel',
        VoidCallback?     onConfirm,
      }) {
    return showDialog<bool>(
      context:            context,
      barrierDismissible: true,
      builder: (_) => ConfirmDialog(
        title:        title,
        message:      message,
        confirmLabel: confirmLabel,
        cancelLabel:  cancelLabel,
        icon:         icon,
        iconColor:    iconColor,
        onConfirm:    onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt     = Theme.of(context).textTheme;
    final cs     = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor:  isDark ? containerDark : bgLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side:         BorderSide(color: cs.outline),
      ),
      
      icon: Container(
        padding:    const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      
      title: Text(
        title,
        textAlign: TextAlign.center,
        style:     tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      
      content: Text(
        message,
        textAlign: TextAlign.center,
        style:     tt.bodyMedium?.copyWith(color: cs.onPrimary),
      ),
      
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding:   const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomOutlineBtn(
                label:       cancelLabel,
                isFullWidth: true,
                size:        BtnSize.medium,
                onPressed:   () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomElevatedBtn(
                label:           confirmLabel,
                isFullWidth:     true,
                size:            BtnSize.medium,
                backgroundColor: iconColor,
                onPressed: () {
                  Navigator.pop(context, true);
                  onConfirm?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}