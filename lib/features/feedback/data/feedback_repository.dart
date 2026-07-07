import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../auth/data/auth_repository.dart';

enum FeedbackType { feature, bug, other }

extension FeedbackTypeValue on FeedbackType {
  String get value => switch (this) {
        FeedbackType.feature => 'feature',
        FeedbackType.bug => 'bug',
        FeedbackType.other => 'other',
      };
}

class FeedbackRepository {
  FeedbackRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<void> submit({
    required FeedbackType type,
    required String message,
    String? contactEmail,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final profile = await _ref.read(userProfileProvider.future);

    await _client.from('feedback').insert({
      'user_id': userId,
      'household_id': profile?.activeHouseholdId,
      'type': type.value,
      'message': message.trim(),
      'contact_email': contactEmail?.trim().isEmpty ?? true
          ? null
          : contactEmail!.trim(),
      'app_version': AppStrings.appVersion,
    });
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(supabaseClientProvider), ref);
});
