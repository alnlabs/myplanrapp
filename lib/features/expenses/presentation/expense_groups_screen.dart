import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/expense_groups_repository.dart';

class ExpenseGroupsScreen extends ConsumerWidget {
  const ExpenseGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(expenseGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.expenseGroupsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/groups/add'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addExpenseGroup),
      ),
      body: AsyncScreenBody(
        value: groupsAsync,
        onRetry: () => ref.invalidate(expenseGroupsProvider),
        isEmpty: (groups) => groups.isEmpty,
        emptyTitle: AppStrings.emptyExpenseGroups,
        emptySubtitle: AppStrings.emptyExpenseGroupsHint,
        emptyActionLabel: AppStrings.addExpenseGroup,
        onEmptyAction: () => context.push('/expenses/groups/add'),
        builder: (groups) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  group.isShared ? Icons.people_outline : Icons.folder_outlined,
                ),
                title: Text(group.name),
                subtitle: Text(
                  group.isShared
                      ? AppStrings.groupTypeShared
                      : AppStrings.groupTypeOrganizational,
                ),
                trailing: Text('${group.memberCount ?? 0}'),
                onTap: () => context.push('/expenses/groups/${group.id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
