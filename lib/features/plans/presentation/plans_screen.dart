import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/meal_slots.dart';
import '../../../shared/constants/plan_constants.dart';
import '../../../shared/models/plan.dart';
import '../../../shared/models/app_reminder_item.dart';
import '../../../shared/widgets/compact_grid_card.dart';
import '../../../shared/widgets/list_grid_layout.dart';
import '../../../shared/providers/list_display_mode_provider.dart';
import '../../../shared/providers/paginated_list_state.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/utils/app_bottom_sheet.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/widgets/filter_menu_button.dart';
import '../../../shared/widgets/list_display_mode_toggle.dart';
import '../../../shared/widgets/paginated_list_footer.dart';
import '../../home/presentation/app_drawer.dart';
import '../../household/data/medicine_schedule_repository.dart';
import '../../reminders/data/reminder_repository.dart';
import '../../reminders/presentation/medicine_reminder_form_screen.dart';
import '../../reminders/presentation/reminder_form_screen.dart';
import '../data/plans_list_provider.dart';
import '../data/todo_reminders_filter.dart';
import 'plan_detail_screen.dart';
import 'reminder_list_views.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key, this.initialFilter = TodoRemindersFilter.all});

  final TodoRemindersFilter initialFilter;

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  late TodoRemindersFilter _filter;

  static const _filterOptions = [
    FilterMenuOption(
      value: TodoRemindersFilter.all,
      label: AppStrings.tabAllPlans,
      icon: Icons.dashboard_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.plans,
      label: AppStrings.filterTodos,
      icon: Icons.event_note_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.meals,
      label: AppStrings.tabMealPlans,
      icon: Icons.restaurant_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.reminders,
      label: AppStrings.filterReminders,
      icon: Icons.notifications_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.medicine,
      label: AppStrings.filterMedicine,
      icon: Icons.medication_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.subscriptions,
      label: AppStrings.filterSubscriptions,
      icon: Icons.subscriptions_outlined,
    ),
    FilterMenuOption(
      value: TodoRemindersFilter.custom,
      label: AppStrings.filterCustomReminders,
      icon: Icons.edit_notifications_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPlansFilter());
  }

  void _applyPlansFilter() {
    final plansFilter = _filter.plansListFilter;
    if (plansFilter != null) {
      ref.read(plansListProvider.notifier).setFilter(plansFilter);
    }
  }

  Future<void> _refresh() async {
    if (_filter.showsPlans) {
      await refreshPlansData(ref);
    }
    if (_filter.showsReminders) {
      ref.invalidate(appRemindersProvider);
      await ref.read(appRemindersProvider.future);
    }
  }

  void _onFilterSelected(TodoRemindersFilter value) {
    setState(() => _filter = value);
    final plansFilter = value.plansListFilter;
    if (plansFilter != null) {
      ref.read(plansListProvider.notifier).setFilter(plansFilter);
    }
  }

  Future<void> _showAddMenu() async {
    final choice = await showAppBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note_outlined),
              title: const Text(AppStrings.addPlan),
              onTap: () => Navigator.pop(context, _AddChoice.plan),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(AppStrings.addReminder),
              onTap: () => Navigator.pop(context, _AddChoice.reminder),
            ),
            ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: const Text(AppStrings.addMedicine),
              onTap: () => Navigator.pop(context, _AddChoice.medicine),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    switch (choice) {
      case _AddChoice.plan:
        await context.push('/plans/add');
        await _refresh();
      case _AddChoice.reminder:
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const ReminderFormScreen(),
          ),
        );
        if (saved == true) await _refresh();
      case _AddChoice.medicine:
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => const MedicineReminderFormScreen(),
          ),
        );
        if (saved == true) await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(plansListProvider);
    final remindersAsync = ref.watch(appRemindersProvider);
    final viewMode =
        ref.watch(listDisplayModeProvider(ListDisplayModeKeys.plans));

    return Scaffold(
      appBar: FeatureScreenAppBar.forShellRoute(
        context,
        title: AppStrings.plansTitle,
        subtitle: AppStrings.plansSubtitle,
        leading: const DrawerMenuButton(),
        actions: [
          const ListDisplayModeToggle(screenKey: ListDisplayModeKeys.plans),
          FilterMenuButton<TodoRemindersFilter>(
            value: _filter,
            onSelected: _onFilterSelected,
            options: _filterOptions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addPlan),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, listState, remindersAsync, viewMode),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PaginatedListState<Plan> listState,
    AsyncValue<List<AppReminderItem>> remindersAsync,
    ListDisplayMode viewMode,
  ) {
    if (_filter.showsPlans && listState.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filter.showsPlans && listState.hasError) {
      return ErrorView(
        error: listState.error!,
        message: ApiErrorFormatter.format(listState.error!),
        onRetry: () => ref.read(plansListProvider.notifier).refresh(),
      );
    }
    if (_filter.showsReminders && !_filter.showsPlans) {
      return remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          error: error,
          message: ApiErrorFormatter.format(error),
          onRetry: () => ref.invalidate(appRemindersProvider),
        ),
        data: (items) => _buildRemindersBody(
          _filter.filterReminders(items),
          viewMode,
        ),
      );
    }

    if (_filter == TodoRemindersFilter.all) {
      return remindersAsync.when(
        loading: () {
          if (listState.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCombinedBody(
            listState: listState,
            reminders: const [],
            viewMode: viewMode,
          );
        },
        error: (_, __) => _buildCombinedBody(
          listState: listState,
          reminders: const [],
          viewMode: viewMode,
        ),
        data: (items) => _buildCombinedBody(
          listState: listState,
          reminders: _filter.filterReminders(items),
          viewMode: viewMode,
        ),
      );
    }

    if (listState.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.event_note_outlined,
            title: AppStrings.emptyFilteredTodos,
            actionLabel: AppStrings.addPlan,
            onAction: () => context.push('/plans/add'),
          ),
        ],
      );
    }

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(plansListProvider.notifier).loadMore(),
      child: viewMode == ListDisplayMode.list
          ? _GroupedPlansList(
              plans: listState.items,
              footer: PaginatedListFooter(
                state: listState,
                onRetryLoadMore: () =>
                    ref.read(plansListProvider.notifier).loadMore(),
              ),
            )
          : _PlansGrid(
              plans: listState.items,
              footer: PaginatedListFooter(
                state: listState,
                onRetryLoadMore: () =>
                    ref.read(plansListProvider.notifier).loadMore(),
              ),
            ),
    );
  }

  Widget _buildRemindersBody(
    List<AppReminderItem> items,
    ListDisplayMode viewMode,
  ) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.notifications_outlined,
            title: AppStrings.emptyFilteredReminders,
            subtitle: AppStrings.emptyRemindersHint,
            actionLabel: AppStrings.addReminder,
            onAction: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => const ReminderFormScreen(),
                ),
              );
              if (saved == true) await _refresh();
            },
          ),
        ],
      );
    }

    return viewMode == ListDisplayMode.list
        ? GroupedRemindersList(
            items: items,
            onEdit: (item) => _editReminder(item),
            onDelete: (item) => _deleteReminder(item),
          )
        : RemindersGrid(
            items: items,
            onEdit: (item) => _editReminder(item),
          );
  }

  Widget _buildCombinedBody({
    required PaginatedListState<Plan> listState,
    required List<AppReminderItem> reminders,
    required ListDisplayMode viewMode,
  }) {
    final hasPlans = listState.items.isNotEmpty;
    final hasReminders = reminders.isNotEmpty;

    if (!hasPlans && !hasReminders) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.event_note_outlined,
            title: AppStrings.emptyTodoRemindersAll,
            subtitle: AppStrings.emptyRemindersHint,
            actionLabel: AppStrings.addPlan,
            onAction: _showAddMenu,
          ),
        ],
      );
    }

    if (viewMode == ListDisplayMode.grid) {
      return _buildCombinedGrid(listState, reminders);
    }

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(plansListProvider.notifier).loadMore(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (hasPlans) ...[
            ..._GroupedPlansList.sectionWidgets(
              context,
              listState.items,
            ),
            PaginatedListFooter(
              state: listState,
              idleHeight: 0,
              onRetryLoadMore: () =>
                  ref.read(plansListProvider.notifier).loadMore(),
            ),
          ],
          if (hasReminders) ...[
            if (hasPlans) const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                AppStrings.otherRemindersSection,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ReminderListSections(
              items: reminders,
              onEdit: _editReminder,
              onDelete: _deleteReminder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedGrid(
    PaginatedListState<Plan> listState,
    List<AppReminderItem> reminders,
  ) {
    final cards = <Widget>[
      ...listState.items.map((plan) => _PlanGridCard(plan: plan)),
      ...reminders.map(
        (item) => ReminderGridCard(
          item: item,
          onTap: () => _editReminder(item),
        ),
      ),
    ];

    return PaginatedScrollListener(
      onLoadMore: () => ref.read(plansListProvider.notifier).loadMore(),
      child: GridView.builder(
        padding: ListGridLayout.padding,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: ListGridLayout.gridDelegate,
        itemCount: cards.length + 1,
        itemBuilder: (context, index) {
          if (index >= cards.length) {
            return SizedBox(
              height: 48,
              child: Center(
                child: PaginatedListFooter(
                  state: listState,
                  onRetryLoadMore: () =>
                      ref.read(plansListProvider.notifier).loadMore(),
                ),
              ),
            );
          }
          return cards[index];
        },
      ),
    );
  }

  Future<void> _editReminder(AppReminderItem item) async {
    if (item.isStandalone) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => ReminderFormScreen(standaloneId: item.sourceId),
        ),
      );
      if (saved == true) await _refresh();
      return;
    }

    if (item.sourceType == ReminderSourceType.medicine) {
      final schedule = await ref
          .read(medicineScheduleRepositoryProvider)
          .fetchScheduleById(item.sourceId);
      if (!mounted || schedule == null) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => MedicineReminderFormScreen(existing: schedule),
        ),
      );
      if (saved == true) await _refresh();
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReminderFormScreen(linkedItem: item),
      ),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _deleteReminder(AppReminderItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.reminderDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(reminderRepositoryProvider).removeLinkedReminder(item);
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.reminderDeleted)),
      );
    }
  }
}

enum _AddChoice { plan, reminder, medicine }

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({required this.plans, required this.footer});

  final List<Plan> plans;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: ListGridLayout.padding,
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: ListGridLayout.gridDelegate,
      itemCount: plans.length + 1,
      itemBuilder: (context, index) {
        if (index >= plans.length) {
          return SizedBox(
            height: 48,
            child: Center(child: footer),
          );
        }
        final plan = plans[index];
        return _PlanGridCard(plan: plan);
      },
    );
  }
}

class _PlanGridCard extends StatelessWidget {
  const _PlanGridCard({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(plan);

    return CompactGridCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlanDetailScreen(planId: plan.id),
        ),
      ),
      leading: CompactGridIcon(
        icon: _iconFor(plan.planType),
        color: accent,
      ),
      title: plan.title,
      subtitle: [
        PlanTypes.labelFor(plan.planType),
        if (plan.dueAt != null) Formatters.date(plan.dueAt!),
      ].join(' · '),
    );
  }

  Color _accentFor(Plan plan) {
    final due = plan.dueAt;
    if (due == null) return Colors.grey.shade600;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (due.isBefore(day)) return Colors.red.shade700;
    if (due.isBefore(day.add(const Duration(days: 1)))) {
      return Colors.orange.shade800;
    }
    return Colors.blue.shade700;
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

class _GroupedPlansList extends StatelessWidget {
  const _GroupedPlansList({
    required this.plans,
    required this.footer,
  });

  final List<Plan> plans;
  final Widget footer;

  static List<Widget> sectionWidgets(BuildContext context, List<Plan> plans) {
    final sections = _buildSections(plans);
    return [
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
    ];
  }

  static List<_PlanSection> _buildSections(List<Plan> plans) {
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

    return [
      if (overdue.isNotEmpty)
        _PlanSection('Overdue', overdue, Colors.red.shade700),
      if (dueToday.isNotEmpty)
        _PlanSection(AppStrings.todayOverview, dueToday, Colors.orange.shade800),
      if (upcoming.isNotEmpty)
        _PlanSection('Upcoming', upcoming, Colors.blue.shade700),
      if (someday.isNotEmpty)
        _PlanSection('No date', someday, Colors.grey.shade600),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...sectionWidgets(context, plans),
        footer,
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
            if (plan.planType == PlanTypes.meal && plan.mealSlot != null)
              MealSlots.labelFor(plan.mealSlot!),
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
