import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/subscription_constants.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/async_screen_body.dart';
import '../data/subscription_repository.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
        ),
        title: const Text(AppStrings.subscriptionsTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/subscriptions/add'),
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addSubscription,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsProvider);
          ref.invalidate(subscriptionsDueSoonProvider);
          await ref.read(subscriptionsProvider.future);
        },
        child: AsyncScreenBody(
          value: subsAsync,
          onRetry: () => ref.invalidate(subscriptionsProvider),
          isEmpty: (items) => items.isEmpty,
          emptyTitle: AppStrings.emptySubscriptions,
          emptySubtitle: AppStrings.emptySubscriptionsHint,
          emptyActionLabel: AppStrings.addSubscription,
          onEmptyAction: () => context.push('/subscriptions/add'),
          builder: (subs) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sub = subs[index];
              return _SubscriptionTile(
                subscription: sub,
                onTap: () => context.push('/subscriptions/edit?id=${sub.id}'),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/subscriptions/add'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addSubscription),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({required this.subscription, required this.onTap});

  final Subscription subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueLabel = subscription.daysUntilDue == 0
        ? AppStrings.dueToday
        : subscription.daysUntilDue == 1
            ? AppStrings.dueTomorrow
            : AppStrings.dueInDays(subscription.daysUntilDue);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            subscription.billingCycle == BillingCycles.monthly
                ? Icons.repeat
                : Icons.event_repeat_outlined,
          ),
        ),
        title: Text(subscription.name),
        subtitle: Text(
          [
            if (subscription.amount != null)
              '${Formatters.currency(subscription.amount!)} · ${BillingCycles.labelFor(subscription.billingCycle)}',
            dueLabel,
          ].join('\n'),
        ),
        trailing: subscription.isDueSoon
            ? Chip(
                label: Text(dueLabel),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
