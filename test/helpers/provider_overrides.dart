import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myplanr/core/providers/supabase_providers.dart';
import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/shared/providers/record_permissions.dart';

import 'stub_repositories.dart';
import 'test_fixtures.dart';

/// Riverpod overrides that avoid Supabase initialization in widget tests.
List<Override> get testAuthOverrides => [
      supabaseClientProvider.overrideWithValue(StubSupabaseClient()),
      userProfileProvider.overrideWith((ref) async => testUserProfile),
      currentUserIdProvider.overrideWith((ref) => testUserId),
      isHouseholdOwnerProvider.overrideWith((ref) => false),
    ];
