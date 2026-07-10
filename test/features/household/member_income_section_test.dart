import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/household/presentation/member_income_section.dart';
import 'package:myplanr/shared/models/expense.dart';

import '../../helpers/pump_app.dart';

void main() {
  const memberId = 'member-1';

  group('MemberIncomeSection widget', () {
    testWidgets('renders income sources with totals', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          memberIncomeSourceSummaryProvider(memberId).overrideWith(
            (ref) async => const [
              MemberIncomeSourceSummary(
                incomeSource: 'Acme Corp',
                earnedTotal: 75000,
              ),
              MemberIncomeSourceSummary(
                incomeSource: 'Freelance',
                earnedTotal: 12000,
              ),
            ],
          ),
        ],
        child: const Scaffold(
          body: MemberIncomeSection(
            familyMemberId: memberId,
            canEdit: true,
          ),
        ),
      );

      expect(find.text(AppStrings.memberIncomeTitle), findsOneWidget);
      expect(find.text(AppStrings.memberIncomeSources), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Freelance'), findsOneWidget);
      expect(find.textContaining('75,000'), findsOneWidget);
      expect(find.textContaining('12,000'), findsOneWidget);
      expect(find.text(AppStrings.logIncome), findsOneWidget);
    });

    testWidgets('shows empty state when no income', (tester) async {
      await pumpTestApp(
        tester,
        overrides: [
          memberIncomeSourceSummaryProvider(memberId)
              .overrideWith((ref) async => []),
        ],
        child: const Scaffold(
          body: MemberIncomeSection(
            familyMemberId: memberId,
            canEdit: false,
          ),
        ),
      );

      expect(find.text(AppStrings.emptyIncome), findsOneWidget);
      expect(find.text(AppStrings.logIncome), findsNothing);
    });
  });
}
