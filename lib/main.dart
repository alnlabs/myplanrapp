import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'core/providers/supabase_providers.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/strings/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/services/notification_service.dart';
import 'features/app_updates/services/app_review_service.dart';
import 'features/app_updates/services/app_update_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/household/data/medicine_schedule_repository.dart';
import 'features/plans/data/plan_repository.dart';
import 'features/reminders/data/reminder_repository.dart';
import 'features/subscriptions/data/subscription_repository.dart';
import 'shared/widgets/myplanr_logo.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      GoogleFonts.config.allowRuntimeFetching = false;
      await AppLogger.instance.init();
      AppLogger.instance.info('App starting');

      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        AppLogger.instance.error(
          'FlutterError: ${details.exceptionAsString()}',
          details.exception,
          details.stack,
        );
        previousOnError?.call(details);
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        AppLogger.instance.error('Platform error', error, stack);
        return false;
      };

      runApp(const ProviderScope(child: BootstrapApp()));
    },
    (error, stack) {
      AppLogger.instance.error('Uncaught error', error, stack);
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        AppLogger.instance.debug(line);
        parent.print(zone, line);
      },
    ),
  );
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
      AppLogger.instance.info('Loaded .env');
    } catch (e, s) {
      AppLogger.instance.warning('Failed to load .env', e, s);
    }

    if (Env.isConfigured) {
      try {
        await Supabase.initialize(
          url: Env.supabaseUrl,
          publishableKey: Env.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        AppLogger.instance.info('Supabase initialized');
        await NotificationService.instance.initialize();
        AppLogger.instance.info('Notifications initialized');
      } catch (e, s) {
        AppLogger.instance.error('Bootstrap failed', e, s);
        rethrow;
      }
    } else {
      AppLogger.instance.warning('Supabase not configured (missing .env)');
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
              body: Center(child: MyPlanrLogo(height: 64)),
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

class MyPlanrApp extends ConsumerStatefulWidget {
  const MyPlanrApp({super.key});

  @override
  ConsumerState<MyPlanrApp> createState() => _MyPlanrAppState();
}

class _MyPlanrAppState extends ConsumerState<MyPlanrApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleReminders();
      AppUpdateService.instance.checkOnStartup();
      AppReviewService.instance.registerLaunchAndMaybeAsk();
    });
  }

  Future<void> _rescheduleReminders() async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      final householdId = profile?.activeHouseholdId;
      if (householdId == null) return;
      await Future.wait([
        ref.read(planRepositoryProvider).rescheduleAllReminders(householdId),
        ref.read(subscriptionRepositoryProvider).rescheduleAllReminders(householdId),
        ref.read(medicineScheduleRepositoryProvider).rescheduleAllReminders(householdId),
        ref.read(reminderRepositoryProvider).rescheduleAllReminders(householdId),
      ]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final hadSession = previous?.valueOrNull?.session != null;
      final hasSession = next.valueOrNull?.session != null;
      final event = next.valueOrNull?.event;
      if (event != null) {
        AppLogger.instance.info('Auth event: ${event.name}');
      }
      if (!hadSession && hasSession) {
        ref.invalidate(userProfileProvider);
        _rescheduleReminders();
      }
      if (hadSession && !hasSession) {
        router.go('/login');
      }
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scaffoldMessengerKey: AppUpdateService.scaffoldMessengerKey,
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
