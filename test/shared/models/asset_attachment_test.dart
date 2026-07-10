import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/asset_attachment.dart';

void main() {
  group('AssetAttachment', () {
    test('isImage detects image mime types', () {
      const image = AssetAttachment(
        id: 'a1',
        assetId: 'asset-1',
        householdId: 'hh',
        attachmentType: 'receipt',
        storagePath: 'path/img.jpg',
        fileName: 'img.jpg',
        mimeType: 'image/jpeg',
      );
      expect(image.isImage, isTrue);

      const pdf = AssetAttachment(
        id: 'a2',
        assetId: 'asset-1',
        householdId: 'hh',
        attachmentType: 'manual',
        storagePath: 'path/doc.pdf',
        fileName: 'doc.pdf',
        mimeType: 'application/pdf',
      );
      expect(pdf.isImage, isFalse);
    });

    test('fromJson parses attachment fields', () {
      final attachment = AssetAttachment.fromJson({
        'id': 'a1',
        'asset_id': 'asset-1',
        'household_id': 'hh',
        'attachment_type': 'warranty',
        'storage_path': 'files/warranty.pdf',
        'file_name': 'warranty.pdf',
        'mime_type': 'application/pdf',
        'file_size_bytes': 1024,
        'created_at': '2026-07-08T10:00:00Z',
      });
      expect(attachment.fileName, 'warranty.pdf');
      expect(attachment.fileSizeBytes, 1024);
      expect(attachment.createdAt, isNotNull);
    });
  });
}
