import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testers/screen/group_testers/service/group_model.dart';
import 'package:testers/screen/group_testers/service/group_service.dart';
import '../../../controllers/info.dart';
import '../../../controllers/height_width.dart';
import '../../../service/firebase/CoinTransaction/coin_transaction_service.dart';
import '../../../service/provider/auth_provider.dart';
import '../../../service/upload/image_upload.dart';
import '../../../widget/button/custom_buttons.dart';
import '../../../widget/container/icon_upload_box.dart';
import '../../../widget/snackbar/custom_snackbar.dart';
import '../../../widget/test field/custom_text_formField.dart';
import 'package:provider/provider.dart';

class GroupJoinScreen extends StatefulWidget {
  const GroupJoinScreen({
    super.key,
    required this.uid,
    required this.username,
    required this.photoURL,
    this.existingGroupId,
  });

  final String  uid;
  final String  username;
  final String  photoURL;
  final String? existingGroupId;

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _appNameCtrl   = TextEditingController();
  final _developerCtrl = TextEditingController();
  final _pkgCtrl       = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _redeemCtrl    = TextEditingController();

  final _uploadService = ImageUploadService();

  File?   _pickedImage;
  String? _uploadedIconUrl;
  bool    _isUploadingIcon = false;
  bool    _loading         = false;
  String  _appType         = 'App';
  String  _priceType       = 'Free';

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _developerCtrl.dispose();
    _pkgCtrl.dispose();
    _descCtrl.dispose();
    _redeemCtrl.dispose();
    _uploadService.dispose();
    super.dispose();
  }

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

      setState(() {
        _pickedImage     = File(picked.path);
        _isUploadingIcon = true;
        _uploadedIconUrl = null;
      });

      final result = await _uploadService.uploadImage(_pickedImage!);
      if (!mounted) return;

      if (result.success) {
        setState(() => _uploadedIconUrl = result.imageUrl);
      } else {
        setState(() => _pickedImage = null);
        CustomSnackbar.show(
          context,
          title:   'Upload Failed',
          message: result.errorMessage ?? 'Could not upload icon.',
          type:    SnackBarType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title:   'Picker Error',
        message: 'Could not open gallery. Check app permissions in Settings.',
        type:    SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isUploadingIcon = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_uploadedIconUrl == null || _uploadedIconUrl!.isEmpty) {
      CustomSnackbar.show(
        context,
        title:   'Icon Required',
        message: 'Please upload an app icon before joining.',
        type:    SnackBarType.error,
      );
      return;
    }

    setState(() => _loading = true);

    final coinError = await _deductCoins();
    if (coinError != null) {
      if (mounted) {
        setState(() => _loading = false);
        CustomSnackbar.show(
          context,
          title:   'Not Enough Coins',
          message: coinError,
          type:    SnackBarType.error,
        );
      }
      return;
    }

    final appDetails = AppDetails(
      appName:       _appNameCtrl.text.trim(),
      developerName: _developerCtrl.text.trim(),
      packageName:   _pkgCtrl.text.trim(),
      iconUrl:       _uploadedIconUrl!,
      description:   _descCtrl.text.trim(),
      appType:       _appType,
      priceType:     _priceType,
      redeemCode:    _priceType == 'Paid' ? _redeemCtrl.text.trim() : null,
    );

    String? error;

    if (widget.existingGroupId != null) {
      error = await GroupService.instance.joinGroup(
        groupId:    widget.existingGroupId!,
        uid:        widget.uid,
        username:   widget.username,
        appDetails: appDetails,
      );
    } else {
      error = await GroupService.instance.createGroup(
        uid:        widget.uid,
        username:   widget.username,
        appDetails: appDetails,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      CustomSnackbar.show(
        context,
        title:   'Failed',
        message: error,
        type:    SnackBarType.error,
      );
    } else {
      await CoinTransactionService.instance.logTransaction(
        userId:   widget.uid,
        username: widget.username,
        amount:   -PublishConstants.groupJoinCoinCost,
        type:     CoinTxType.joinGroup,
        note:     _appNameCtrl.text.trim(),
      );

      await context.read<AuthProvider>().refreshUserData();

      if (mounted) Navigator.pop(context);
      CustomSnackbar.show(
        context,
        title:   "You're in!",
        message: 'Your app has been added to the group.\n'
            'The 14-day testing cycle starts once all 15 slots are filled.',
        type:    SnackBarType.success,
      );
    }
  }

  Future<String?> _deductCoins() async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid);

      return await FirebaseFirestore.instance.runTransaction<String?>((tx) async {
        final snap         = await tx.get(userRef);
        final currentCoins = (snap.data()?['coins'] as num?)?.toInt() ?? 0;

        if (currentCoins < PublishConstants.groupJoinCoinCost) {
          return 'You need ${PublishConstants.groupJoinCoinCost} coins to join. '
              'You have $currentCoins coins.';
        }

        tx.update(userRef, {
          'coins': FieldValue.increment(-PublishConstants.groupJoinCoinCost),
        });
        return null;
      });
    } catch (e) {
      return 'Failed to process coins. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final isBusy = _loading || _isUploadingIcon;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor:  cs.surface,
        elevation:        0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon:      const Icon(Icons.chevron_left_rounded, size: 28),
          color:     cs.onSurface,
          onPressed: isBusy ? null : () => Navigator.pop(context),
        ),
        title: Text('Join Testing Group',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            baseScreenPadding,
            12,
            baseScreenPadding,
            40,
          ),
          children: [
            IconUploadBox(
              pickedImage: _pickedImage,
              uploadedUrl: _uploadedIconUrl,
              isUploading: _isUploadingIcon,
              onTap:       isBusy ? null : _pickImage,
            ),
            SizedBox(height: bottomPadding + 4),

            CustomTextFormField(
              label:              'App Name',
              hint:               'e.g. My Awesome App',
              controller:         _appNameCtrl,
              prefixIcon:         Icons.apps_rounded,
              textInputAction:    TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              enabled:            !isBusy,
              validators: [
                FieldValidator.required('App name is required'),
                FieldValidator.maxLength(60),
              ],
            ),
            SizedBox(height: bottomPadding),

            CustomTextFormField(
              label:           'Developer Name',
              hint:            'e.g. google',
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

            CustomTextFormField(
              label:           'Package Name',
              hint:            'com.example.myapp',
              controller:      _pkgCtrl,
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

            CustomTextFormField(
              label:              'Description (optional)',
              hint:               'Briefly describe what your app does...',
              controller:         _descCtrl,
              prefixIcon:         Icons.description_outlined,
              maxLines:           3,
              textInputAction:    TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enabled:            !isBusy,
              validate:           false,
            ),
            SizedBox(height: bottomPadding),

            Text('App Type',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: ['App', 'Game'].map((type) {
                final isSelected = _appType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: type == 'App' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _appType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.55)
                                : cs.outline,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type == 'App'
                                  ? Icons.grid_view_rounded
                                  : Icons.sports_esports_rounded,
                              size:  16,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(type,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: bottomPadding),

            Text('Price Type',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: ['Free', 'Paid'].map((type) {
                final isSelected = _priceType == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: type == 'Free' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _priceType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.55)
                                : cs.outline,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type == 'Free'
                                  ? Icons.money_off_rounded
                                  : Icons.attach_money_rounded,
                              size:  16,
                              color: isSelected ? cs.primary : cs.onSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(type,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_priceType == 'Paid') ...[
              SizedBox(height: bottomPadding),
              CustomTextFormField(
                label:           'Play Store Redeem Code',
                hint:            'Enter redeem code for testers',
                controller:      _redeemCtrl,
                prefixIcon:      Icons.card_giftcard_rounded,
                textInputAction: TextInputAction.next,
                enabled:         !isBusy,
                validators: [
                  FieldValidator.required(
                      'Redeem code is required for paid apps'),
                ],
              ),
            ],
            SizedBox(height: bottomPadding),

            CustomElevatedBtn(
              label:           'Join Group',
              onPressed:       isBusy ? null : _submit,
              prefixIcon:      Icons.rocket_launch_rounded,
              isFullWidth:     true,
              isLoading:       isBusy,
              size:            BtnSize.large,
              borderRadius:    textFromFieldBorderRadius,
              backgroundColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}