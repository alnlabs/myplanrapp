import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/providers/supabase_providers.dart';
import 'core/router/app_router.dart';
import 'core/strings/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/services/notification_service.dart';
import 'features/auth/data/auth_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BootstrapApp()));
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<void> _initFuture = _bootstrap();

  Future<void> _bootstrap() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    if (Env.isConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      await NotificationService.instance.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!Env.isConfigured) {
          return MaterialApp(
            theme: AppTheme.light,
            home: const MissingConfigScreen(),
          );
        }

        return const MyPlanrApp();
      },
    );
  }
}

class MyPlanrApp extends ConsumerWidget {
  const MyPlanrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final hadSession = previous?.valueOrNull?.session != null;
      final hasSession = next.valueOrNull?.session != null;
      if (!hadSession && hasSession) {
        ref.invalidate(userProfileProvider);
      }
      if (hadSession && !hasSession) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.missingConfigTitle)),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(AppStrings.missingConfigBody),
      ),
    );
  }
}
