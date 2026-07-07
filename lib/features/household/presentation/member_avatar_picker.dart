import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/family_member.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../data/family_repository.dart';
import '../data/member_avatar_repository.dart';

class MemberAvatarPicker extends ConsumerStatefulWidget {
  const MemberAvatarPicker({
    super.key,
    required this.familyMemberId,
    required this.householdId,
    required this.displayName,
    this.avatarPath,
    required this.canEdit,
    this.existingDetails,
  });

  final String familyMemberId;
  final String householdId;
  final String displayName;
  final String? avatarPath;
  final bool canEdit;
  final FamilyMemberDetails? existingDetails;

  @override
  ConsumerState<MemberAvatarPicker> createState() => _MemberAvatarPickerState();
}

class _MemberAvatarPickerState extends ConsumerState<MemberAvatarPicker> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _localPath;

  @override
  Widget build(BuildContext context) {
    final path = _localPath ?? widget.avatarPath;
    final urlAsync = path != null
        ? ref.watch(memberAvatarUrlProvider(path))
        : const AsyncValue<String?>.data(null);

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: urlAsync.valueOrNull != null
                    ? NetworkImage(urlAsync.valueOrNull!)
                    : null,
                child: urlAsync.isLoading || _uploading
                    ? const CircularProgressIndicator()
                    : urlAsync.valueOrNull == null
                        ? Text(
                            widget.displayName.isNotEmpty
                                ? widget.displayName[0].toUpperCase()
                                : '?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          )
                        : null,
              ),
              if (widget.canEdit)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: _uploading ? null : _pickPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.canEdit && path != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _uploading ? null : _removePhoto,
              child: const Text(AppStrings.removePhoto),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final mime = file.mimeType ?? 'image/jpeg';
      final storagePath = await ref
          .read(memberAvatarRepositoryProvider)
          .uploadAvatar(
            householdId: widget.householdId,
            familyMemberId: widget.familyMemberId,
            bytes: bytes,
            mimeType: mime,
            previousPath: widget.avatarPath,
          );

      final existing = widget.existingDetails;
      if (existing != null) {
        await ref.read(familyRepositoryProvider).upsertDetails(
              widget.familyMemberId,
              existing.copyWith(avatarUrl: storagePath),
            );
      }

      ref.invalidate(familyMemberDetailsProvider(widget.familyMemberId));
      ref.invalidate(memberAvatarUrlProvider(storagePath));
      if (mounted) {
        setState(() {
          _localPath = storagePath;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  Future<void> _removePhoto() async {
    final existing = widget.existingDetails;
    if (existing == null) return;

    setState(() => _uploading = true);
    try {
      await ref.read(familyRepositoryProvider).upsertDetails(
            widget.familyMemberId,
            existing.copyWith(avatarUrl: ''),
          );
      ref.invalidate(familyMemberDetailsProvider(widget.familyMemberId));
      if (mounted) {
        setState(() {
          _localPath = null;
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }
}
