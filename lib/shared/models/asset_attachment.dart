class AssetAttachment {
  const AssetAttachment({
    required this.id,
    required this.assetId,
    required this.householdId,
    required this.attachmentType,
    required this.storagePath,
    required this.fileName,
    this.createdBy,
    this.mimeType,
    this.fileSizeBytes,
    this.createdAt,
  });

  final String id;
  final String assetId;
  final String householdId;
  final String? createdBy;
  final String attachmentType;
  final String storagePath;
  final String fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final DateTime? createdAt;

  bool get isImage {
    final mime = mimeType?.toLowerCase() ?? '';
    return mime.startsWith('image/');
  }

  factory AssetAttachment.fromJson(Map<String, dynamic> json) {
    return AssetAttachment(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String?,
      attachmentType: json['attachment_type'] as String,
      storagePath: json['storage_path'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
