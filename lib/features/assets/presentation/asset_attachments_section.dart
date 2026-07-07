import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/storage_constants.dart';
import '../../../shared/models/asset_attachment.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../data/attachment_repository.dart';

class AssetAttachmentsSection extends ConsumerStatefulWidget {
  const AssetAttachmentsSection({
    super.key,
    required this.assetId,
    required this.householdId,
  });

  final String assetId;
  final String householdId;

  @override
  ConsumerState<AssetAttachmentsSection> createState() =>
      _AssetAttachmentsSectionState();
}

class _AssetAttachmentsSectionState extends ConsumerState<AssetAttachmentsSection> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  Future<void> _addPhoto() async {
    setState(() {
      _error = null;
    });

    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text(AppStrings.attachmentWarranty),
              onTap: () => Navigator.pop(context, AttachmentTypes.warranty),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text(AppStrings.attachmentReceipt),
              onTap: () => Navigator.pop(context, AttachmentTypes.receipt),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text(AppStrings.attachmentOther),
              onTap: () => Navigator.pop(context, AttachmentTypes.other),
            ),
          ],
        ),
      ),
    );
    if (type == null || !mounted) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.pickFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text(AppStrings.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1920,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
      await ref.read(attachmentRepositoryProvider).uploadAttachment(
            householdId: widget.householdId,
            assetId: widget.assetId,
            bytes: bytes,
            fileName: fileName,
            mimeType: _mimeForName(fileName),
            attachmentType: type,
          );
      ref.invalidate(assetAttachmentsProvider(widget.assetId));
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(AssetAttachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAttachment),
        content: const Text(AppStrings.deleteAttachmentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(attachmentRepositoryProvider).deleteAttachment(attachment);
      ref.invalidate(assetAttachmentsProvider(widget.assetId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiErrorFormatter.format(e))),
        );
      }
    }
  }

  String _mimeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync =
        ref.watch(assetAttachmentsProvider(widget.assetId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.photosAndReceipts,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: _uploading ? null : _addPhoto,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(_uploading ? AppStrings.uploading : AppStrings.addPhoto),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.photoUploadWarning,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        attachmentsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text(AppStrings.errorGeneric),
          data: (attachments) {
            if (attachments.isEmpty) {
              return Text(
                AppStrings.noAttachments,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              );
            }
            return SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  final canDelete = attachment.createdBy == currentUserId;
                  return _AttachmentTile(
                    attachment: attachment,
                    canDelete: canDelete,
                    onDelete: () => _delete(attachment),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.canDelete,
    required this.onDelete,
  });

  final AssetAttachment attachment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(attachmentSignedUrlProvider(attachment.storagePath));

    return urlAsync.when(
      loading: () => const SizedBox(
        width: 112,
        height: 112,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _TileFrame(
        child: const Icon(Icons.broken_image_outlined),
        label: attachment.fileName,
        canDelete: canDelete,
        onDelete: onDelete,
      ),
      data: (url) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullScreenImage(url: url, title: attachment.fileName),
          ),
        ),
        child: _TileFrame(
          child: attachment.isImage
              ? Image.network(url, fit: BoxFit.cover)
              : const Icon(Icons.picture_as_pdf_outlined, size: 40),
          label: AttachmentTypes.labelFor(attachment.attachmentType),
          canDelete: canDelete,
          onDelete: onDelete,
        ),
      ),
    );
  }
}

class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.child,
    required this.label,
    required this.canDelete,
    required this.onDelete,
  });

  final Widget child;
  final String label;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: child,
                  ),
                  if (canDelete)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url, required this.title});

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        child: Center(child: Image.network(url)),
      ),
    );
  }
}
