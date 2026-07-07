import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/strings/app_strings.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Column(
      children: [
        if (!online)
          MaterialBanner(
            content: const Text(AppStrings.offlineBanner),
            leading: const Icon(Icons.wifi_off_outlined),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            actions: const [SizedBox.shrink()],
          ),
        Expanded(child: child),
      ],
    );
  }
}
