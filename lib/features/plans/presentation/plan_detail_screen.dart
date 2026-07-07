import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../auth/data/auth_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../data/plan_repository.dart';
import 'plan_form_screen.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planProvider(planId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.plansTitle),
        actions: [
          planAsync.whenOrNull(
            data: (plan) {
              if (plan == null || plan.createdBy != currentUserId) {
                return null;
              }
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanFormScreen(planId: plan.id),
                  ),
                ),
              );
            },
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: AsyncScreenBody(
        value: planAsync,
        onRetry: () => ref.invalidate(planProvider(planId)),
        builder: (plan) {
          if (plan == null) {
            return const Center(child: Text(AppStrings.errorGeneric));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                plan.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(PlanTypes.labelFor(plan.planType))),
                  Chip(
                    label: Text(
                      plan.isPersonal
                          ? AppStrings.tabPersonalPlans
                          : AppStrings.tabFamilyPlans,
                    ),
                  ),
                  if (plan.reminderEnabled)
                    const Chip(
                      avatar: Icon(Icons.notifications_active_outlined, size: 16),
                      label: Text(AppStrings.reminder),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (plan.description != null) Text(plan.description!),
              if (plan.aboutMemberName != null) ...[
                const SizedBox(height: 12),
                _Row(AppStrings.forMember, plan.aboutMemberName!),
              ],
              if (plan.assignedToName != null)
                _Row(AppStrings.assignedTo, plan.assignedToName!),
              if (plan.dueAt != null)
                _Row(AppStrings.dueDate, Formatters.dateTime(plan.dueAt!)),
              if (plan.reminderAt != null)
                _Row(AppStrings.reminderAt, Formatters.dateTime(plan.reminderAt!)),
              const SizedBox(height: 24),
              if (plan.isOpen) ...[
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(planRepositoryProvider).completePlan(plan.id);
                      ref.invalidate(plansProvider);
                      ref.invalidate(openPlansProvider);
                      ref.invalidate(planProvider(planId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(AppStrings.planCompleted)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ApiErrorFormatter.format(e))),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(AppStrings.completePlan),
                ),
                if (plan.planType == PlanTypes.purchase) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final profile =
                            await ref.read(userProfileProvider.future);
                        final householdId = profile?.activeHouseholdId;
                        if (householdId == null) return;
                        await ref.read(shoppingRepositoryProvider).addItem(
                              householdId: householdId,
                              name: plan.title,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.addedToShop),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ApiErrorFormatter.format(e))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text(AppStrings.addToShopList),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
