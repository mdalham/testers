import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../controllers/height_width.dart';
import '../../../service/upload/image_upload.dart';
import '../../../widget/container/icon_upload_box.dart';
import '../../../widget/snackbar/custom_snackbar.dart';
import '../../../widget/test field/custom_text_formField.dart';
import '../provider/publish_provider.dart';


class Step3AppDetails extends StatefulWidget {
  const Step3AppDetails({super.key});

  @override
  State<Step3AppDetails> createState() => _Step3AppDetailsState();
}

class _Step3AppDetailsState extends State<Step3AppDetails> {
  final _formKey       = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _developerCtrl;
  late final TextEditingController _packageCtrl;
  late final TextEditingController _descCtrl;

  final _uploadService = ImageUploadService();
  bool _isUploadingIcon = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<PublishProvider>();

    _nameCtrl      = TextEditingController(text: p.step3AppName);
    _developerCtrl = TextEditingController(text: p.step3Developer);
    _packageCtrl   = TextEditingController(text: p.step3PackageName);
    _descCtrl      = TextEditingController(text: p.step3Description);

    _nameCtrl.addListener(
            () => context.read<PublishProvider>().setStep3AppName(_nameCtrl.text));
    _developerCtrl.addListener(
            () => context.read<PublishProvider>().setStep3Developer(_developerCtrl.text));
    _packageCtrl.addListener(
            () => context.read<PublishProvider>().setStep3PackageName(_packageCtrl.text));
    _descCtrl.addListener(
            () => context.read<PublishProvider>().setStep3Description(_descCtrl.text));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _developerCtrl.dispose();
    _packageCtrl.dispose();
    _descCtrl.dispose();
    _uploadService.dispose();
    super.dispose();
  }

  // ── Icon pick & upload ─────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    try {
      final XFile? picked = await ImagePicker().pickImage(
        source:       ImageSource.gallery,
        imageQuality: 85,
        maxWidth:     512,
        maxHeight:    512,
      );
      if (picked == null || !mounted) return;

      final file = File(picked.path);
      context.read<PublishProvider>()
        ..setStep3PickedIcon(file)
        ..clearIconUrl();

      setState(() => _isUploadingIcon = true);

      final result = await _uploadService.uploadImage(file);
      if (!mounted) return;

      if (result.success) {
        context.read<PublishProvider>().setIconUrl(result.imageUrl!);
      } else {
        context.read<PublishProvider>().setStep3PickedIcon(null);
        CustomSnackbar.show(context,
            title:   'Upload Failed',
            message: result.errorMessage ?? 'Could not upload icon.',
            type:    SnackBarType.error);
      }
    } catch (_) {
      if (!mounted) return;
      CustomSnackbar.show(context,
          title:   'Picker Error',
          message: 'Could not open gallery. Check app permissions.',
          type:    SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isUploadingIcon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p     = context.watch<PublishProvider>();
    final isBusy = _isUploadingIcon;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(baseScreenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── App Icon ─────────────────────────────────────────────────────
            _SectionLabel(icon: Icons.image_rounded, title: 'App Icon'),
            const SizedBox(height: 12),
            IconUploadBox(
              pickedImage: p.step3PickedIcon,
              uploadedUrl: p.uploadedIconUrl,
              isUploading: _isUploadingIcon,
              onTap:       isBusy ? null : _pickImage,
            ),

            SizedBox(height: bottomPadding),

            // ── App Name ─────────────────────────────────────────────────────
            CustomTextFormField(
              label:              'App Name',
              hint:               'e.g. My Awesome App',
              controller:         _nameCtrl,
              prefixIcon:         Icons.apps_rounded,
              textInputAction:    TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              enabled:            !isBusy,
              validators: [
                FieldValidator.required('App name is required'),
                FieldValidator.maxLength(50),
              ],
            ),

            SizedBox(height: bottomPadding),

            // ── Developer Name ────────────────────────────────────────────────
            CustomTextFormField(
              label:           'Developer Name',
              hint:            'Your name or studio name',
              controller:      _developerCtrl,
              prefixIcon:      Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              enabled:         !isBusy,
              validators: [
                FieldValidator.required('Developer name is required'),
                FieldValidator.maxLength(50),
              ],
            ),

            SizedBox(height: bottomPadding),

            // ── Package Name ──────────────────────────────────────────────────
            CustomTextFormField(
              label:           'Package Name',
              hint:            'com.example.myapp',
              controller:      _packageCtrl,
              prefixIcon:      Icons.inventory_2_outlined,
              keyboardType:    TextInputType.url,
              textInputAction: TextInputAction.next,
              enabled:         !isBusy,
              validators: [
                FieldValidator.required('Package name is required'),
                FieldValidator.pattern(
                  RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){1,}$'),
                  'Use format: com.example.app',
                ),
              ],
            ),

            SizedBox(height: bottomPadding),

            // ── Description (optional) ────────────────────────────────────────
            CustomTextFormField(
              label:              'Description (optional)',
              hint:               'What should testers know about your app?',
              controller:         _descCtrl,
              prefixIcon:         Icons.description_outlined,
              maxLines:           4,
              textInputAction:    TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enabled:            !isBusy,
              validate:           false,
            ),

            SizedBox(height: bottomPadding + 8),
          ],
        ),
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title});
  final IconData icon;
  final String   title;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface),
        const SizedBox(width: 8),
        Text(title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}