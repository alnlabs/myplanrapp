import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/plan_repository.dart';
import 'plan_detail_screen.dart';

enum PlansFilter { all, personal, family, meals }

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  PlansFilter _filter = PlansFilter.all;

  List<Plan> _filtered(List<Plan> plans) {
    return switch (_filter) {
      PlansFilter.all => plans.where((p) => p.isOpen).toList(),
      PlansFilter.personal =>
        plans.where((p) => p.isOpen && p.isPersonal).toList(),
      PlansFilter.family =>
        plans.where((p) => p.isOpen && !p.isPersonal).toList(),
      PlansFilter.meals =>
        plans.where((p) => p.isOpen && p.planType == PlanTypes.meal).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.plansTitle),
        actions: [
          IconButton(
            onPressed: () async {
              await context.push('/plans/add');
              ref.invalidate(plansProvider);
              ref.invalidate(openPlansProvider);
            },
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addPlan,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _FilterChip(
                  label: AppStrings.tabAllPlans,
                  selected: _filter == PlansFilter.all,
                  onTap: () => setState(() => _filter = PlansFilter.all),
                ),
                _FilterChip(
                  label: AppStrings.tabPersonalPlans,
                  selected: _filter == PlansFilter.personal,
                  onTap: () => setState(() => _filter = PlansFilter.personal),
                ),
                _FilterChip(
                  label: AppStrings.tabFamilyPlans,
                  selected: _filter == PlansFilter.family,
                  onTap: () => setState(() => _filter = PlansFilter.family),
                ),
                _FilterChip(
                  label: AppStrings.tabMealPlans,
                  selected: _filter == PlansFilter.meals,
                  onTap: () => setState(() => _filter = PlansFilter.meals),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(plansProvider);
                ref.invalidate(openPlansProvider);
              },
              child: AsyncScreenBody(
                value: plansAsync,
                onRetry: () => ref.invalidate(plansProvider),
                builder: (plans) {
                  final filtered = _filtered(plans);
                  if (filtered.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text(AppStrings.emptyPlans)),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final plan = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_iconFor(plan.planType)),
                          title: Text(plan.title),
                          subtitle: Text(
                            [
                              PlanTypes.labelFor(plan.planType),
                              if (plan.aboutMemberName != null)
                                'For ${plan.aboutMemberName}',
                              if (plan.dueAt != null)
                                Formatters.dateTime(plan.dueAt!),
                            ].join(' · '),
                          ),
                          trailing: plan.reminderEnabled
                              ? const Icon(Icons.notifications_active_outlined,
                                  size: 20)
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PlanDetailScreen(planId: plan.id),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        PlanTypes.purchase => Icons.shopping_bag_outlined,
        PlanTypes.meal => Icons.restaurant_outlined,
        PlanTypes.medicine => Icons.medication_outlined,
        PlanTypes.task => Icons.task_alt_outlined,
        _ => Icons.event_note_outlined,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
