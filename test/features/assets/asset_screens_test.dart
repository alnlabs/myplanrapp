import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/assets/data/asset_repository.dart';
import 'package:myplanr/features/assets/presentation/asset_attachments_section.dart';
import 'package:myplanr/features/assets/presentation/asset_detail_screen.dart';
import 'package:myplanr/features/assets/presentation/assets_list_tab.dart';
import 'package:myplanr/features/assets/data/attachment_repository.dart';

import '../../helpers/provider_overrides.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  const assetId = 'asset-1';

  group('AssetDetailScreen widget', () {
    testWidgets('renders asset details and service records section', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          homeAssetProvider(assetId).overrideWith((ref) async => testHomeAsset),
          assetServiceRecordsProvider(assetId).overrideWith((ref) async => []),
        ],
        child: const AssetDetailScreen(assetId: assetId),
      );

      expect(find.text('Refrigerator'), findsWidgets);
      expect(find.text(AppStrings.logRepair), findsOneWidget);
    });
  });

  group('AssetsListTab widget', () {
    testWidgets('renders assets list', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          homeAssetsProvider.overrideWith((ref) async => [testHomeAsset]),
        ],
        child: const Scaffold(body: AssetsListTab(query: '')),
      );

      expect(find.text('Refrigerator'), findsOneWidget);
    });
  });

  group('AssetAttachmentsSection widget', () {
    testWidgets('renders empty attachments state', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          ...testAuthOverrides,
          assetAttachmentsProvider(assetId).overrideWith((ref) async => []),
        ],
        child: const Scaffold(
          body: AssetAttachmentsSection(
            assetId: assetId,
            householdId: testHouseholdId,
          ),
        ),
      );

      expect(find.text(AppStrings.photosAndReceipts), findsOneWidget);
      expect(find.text(AppStrings.addPhoto), findsOneWidget);
    });
  });
}
