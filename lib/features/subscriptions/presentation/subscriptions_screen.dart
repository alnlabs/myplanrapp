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
        title: const Text(AppStrings.subscriptionsTitle),
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
          emptyIcon: Icons.subscriptions_outlined,
          emptyTitle: AppStrings.emptySubscriptions,
          emptySubtitle: AppStrings.emptySubscriptionsHint,
          emptyActionLabel: AppStrings.addSubscription,
          onEmptyAction: () => context.push('/subscriptions/add'),
          builder: (subs) {
            final sorted = [...subs]
              ..sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _SummaryHeader(subscriptions: subs),
                const SizedBox(height: 20),
                ...sorted.map(
                  (sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SubscriptionTile(
                      subscription: sub,
                      onTap: () =>
                          context.push('/subscriptions/edit?id=${sub.id}'),
                    ),
                  ),
                ),
              ],
            );
          },
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.subscriptions});

  final List<Subscription> subscriptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var monthly = 0.0;
    for (final sub in subscriptions) {
      final amount = sub.amount;
      if (amount == null) continue;
      monthly += sub.billingCycle == BillingCycles.monthly
          ? amount
          : amount / 12;
    }
    final yearly = monthly * 12;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _Metric(
            label: AppStrings.subsMonthlyTotal,
            value: Formatters.currency(monthly),
          ),
          _divider(theme),
          _Metric(
            label: AppStrings.subsYearlyTotal,
            value: Formatters.currency(yearly),
          ),
          _divider(theme),
          _Metric(
            label: AppStrings.subsActiveCount,
            value: '${subscriptions.length}',
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) => Container(
        width: 1,
        height: 36,
        color: theme.colorScheme.onPrimary.withOpacity(0.24),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    final days = subscription.daysUntilDue;
    final dueLabel = days == 0
        ? AppStrings.dueToday
        : days == 1
            ? AppStrings.dueTomorrow
            : AppStrings.dueInDays(days);

    final Color dueColor;
    if (days <= 1) {
      dueColor = theme.colorScheme.error;
    } else if (days <= 7) {
      dueColor = Colors.orange.shade800;
    } else {
      dueColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  subscription.billingCycle == BillingCycles.monthly
                      ? Icons.repeat
                      : Icons.event_repeat_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      BillingCycles.labelFor(subscription.billingCycle),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 13, color: dueColor),
                        const SizedBox(width: 4),
                        Text(
                          dueLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: dueColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (subscription.amount != null)
                    Text(
                      Formatters.currency(subscription.amount!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
