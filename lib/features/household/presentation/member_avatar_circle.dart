import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/member_avatar_repository.dart';

class MemberAvatarCircle extends ConsumerWidget {
  const MemberAvatarCircle({
    super.key,
    required this.displayName,
    this.avatarPath,
    this.radius = 20,
  });

  final String displayName;
  final String? avatarPath;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final path = avatarPath;

    if (path == null || path.isEmpty) {
      return CircleAvatar(radius: radius, child: Text(initial));
    }

    final urlAsync = ref.watch(memberAvatarUrlProvider(path));

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: urlAsync.valueOrNull != null
          ? NetworkImage(urlAsync.valueOrNull!)
          : null,
      child: urlAsync.isLoading
          ? SizedBox(
              width: radius,
              height: radius,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : urlAsync.valueOrNull == null
              ? Text(initial)
              : null,
    );
  }
}
