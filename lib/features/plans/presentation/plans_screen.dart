import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../../../shared/widgets/filter_menu_button.dart';
import '../data/plan_repository.dart';
import 'plan_detail_screen.dart';

enum PlansFilter { all, meals }

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
          FilterMenuButton<PlansFilter>(
            value: _filter,
            onSelected: (value) => setState(() => _filter = value),
            options: const [
              FilterMenuOption(
                value: PlansFilter.all,
                label: AppStrings.tabAllPlans,
                icon: Icons.event_note_outlined,
              ),
              FilterMenuOption(
                value: PlansFilter.meals,
                label: AppStrings.tabMealPlans,
                icon: Icons.restaurant_outlined,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/plans/add');
          ref.invalidate(plansProvider);
          ref.invalidate(openPlansProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addPlan),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider);
          ref.invalidate(openPlansProvider);
          await ref.read(plansProvider.future);
        },
        child: AsyncScreenBody(
          value: plansAsync,
          onRetry: () => ref.invalidate(plansProvider),
          isEmpty: (plans) => _filtered(plans).isEmpty,
          emptyIcon: Icons.event_note_outlined,
          emptyTitle: AppStrings.emptyPlans,
          emptyActionLabel: AppStrings.addPlan,
          onEmptyAction: () => context.push('/plans/add'),
          builder: (plans) => _GroupedPlansList(plans: _filtered(plans)),
        ),
      ),
    );
  }
}

class _GroupedPlansList extends StatelessWidget {
  const _GroupedPlansList({required this.plans});

  final List<Plan> plans;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final overdue = <Plan>[];
    final dueToday = <Plan>[];
    final upcoming = <Plan>[];
    final someday = <Plan>[];

    for (final plan in plans) {
      final due = plan.dueAt;
      if (due == null) {
        someday.add(plan);
      } else if (due.isBefore(today)) {
        overdue.add(plan);
      } else if (due.isBefore(tomorrow)) {
        dueToday.add(plan);
      } else {
        upcoming.add(plan);
      }
    }

    final sections = <_PlanSection>[
      if (overdue.isNotEmpty)
        _PlanSection('Overdue', overdue, Colors.red.shade700),
      if (dueToday.isNotEmpty)
        _PlanSection(AppStrings.todayOverview, dueToday, Colors.orange.shade800),
      if (upcoming.isNotEmpty)
        _PlanSection('Upcoming', upcoming, Colors.blue.shade700),
      if (someday.isNotEmpty)
        _PlanSection('No date', someday, Colors.grey.shade600),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: section.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${section.plans.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          ...section.plans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlanTile(plan: plan, accent: section.color),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanSection {
  const _PlanSection(this.title, this.plans, this.color);
  final String title;
  final List<Plan> plans;
  final Color color;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.accent});

  final Plan plan;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withOpacity(0.14),
          child: Icon(_iconFor(plan.planType), color: accent),
        ),
        title: Text(plan.title),
        subtitle: Text(
          [
            PlanTypes.labelFor(plan.planType),
            if (plan.aboutMemberName != null) 'For ${plan.aboutMemberName}',
            if (plan.dueAt != null) Formatters.dateTime(plan.dueAt!),
          ].join(' · '),
        ),
        trailing: plan.reminderEnabled
            ? Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlanDetailScreen(planId: plan.id),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        PlanTypes.purchase => Icons.shopping_bag_outlined,
        PlanTypes.meal => Icons.restaurant_outlined,
        PlanTypes.medicine => Icons.medication_outlined,
        PlanTypes.task => Icons.task_alt_outlined,
        PlanTypes.bill => Icons.receipt_long_outlined,
        PlanTypes.appointment => Icons.event_available_outlined,
        PlanTypes.event => Icons.celebration_outlined,
        PlanTypes.travel => Icons.flight_takeoff_outlined,
        PlanTypes.chore => Icons.cleaning_services_outlined,
        PlanTypes.maintenance => Icons.build_outlined,
        PlanTypes.birthday => Icons.cake_outlined,
        PlanTypes.school => Icons.school_outlined,
        PlanTypes.pet => Icons.pets_outlined,
        PlanTypes.childcare => Icons.child_care_outlined,
        PlanTypes.outing => Icons.park_outlined,
        _ => Icons.event_note_outlined,
      };
}
