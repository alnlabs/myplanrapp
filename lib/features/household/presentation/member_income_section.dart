import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/formatters.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/add_income_screen.dart';

class MemberIncomeSection extends ConsumerWidget {
  const MemberIncomeSection({
    super.key,
    required this.familyMemberId,
    required this.canEdit,
  });

  final String familyMemberId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesAsync =
        ref.watch(memberIncomeSourceSummaryProvider(familyMemberId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.memberIncomeTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => AddIncomeScreen(
                            initialFamilyMemberId: familyMemberId,
                          ),
                        ),
                      );
                      if (updated == true) {
                        ref.invalidate(
                          memberIncomeSourceSummaryProvider(familyMemberId),
                        );
                        ref.invalidate(memberIncomeSummaryProvider);
                        ref.invalidate(moneySummaryProvider);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.logIncome),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            sourcesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(AppStrings.errorGeneric),
              data: (rows) {
                if (rows.isEmpty) {
                  return Text(
                    AppStrings.emptyIncome,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.memberIncomeSources,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    ...rows.map(
                      (row) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(row.incomeSource),
                        trailing: Text(
                          Formatters.currency(row.earnedTotal),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        onTap: canEdit
                            ? () async {
                                final updated =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => AddIncomeScreen(
                                      initialFamilyMemberId: familyMemberId,
                                      initialIncomeSource: row.incomeSource,
                                    ),
                                  ),
                                );
                                if (updated == true) {
                                  ref.invalidate(
                                    memberIncomeSourceSummaryProvider(
                                      familyMemberId,
                                    ),
                                  );
                                  ref.invalidate(memberIncomeSummaryProvider);
                                  ref.invalidate(moneySummaryProvider);
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
