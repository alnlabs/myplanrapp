import 'package:myplanr/features/auth/data/auth_repository.dart';
import 'package:myplanr/features/expenses/data/expense_groups_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/expenses/data/recurring_money_rule_repository.dart';
import 'package:myplanr/features/feedback/data/feedback_repository.dart';
import 'package:myplanr/features/household/data/family_repository.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/family_member.dart';
import 'package:myplanr/shared/models/household.dart';
import 'package:myplanr/shared/models/user_profile.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StubSupabaseClient implements SupabaseClient {
  @override
  GoTrueClient get auth => _StubGoTrueClient();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubAuthRepository implements AuthRepository {
  StubAuthRepository({
    this.profile,
    this.onSignIn,
    this.onSignUp,
    this.onResetPassword,
  });

  final UserProfile? profile;
  final Future<void> Function()? onSignIn;
  final Future<void> Function()? onSignUp;
  final Future<void> Function()? onResetPassword;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #signIn) {
      return onSignIn?.call() ?? Future.value(AuthResponse());
    }
    if (invocation.memberName == #signUp) {
      return onSignUp?.call() ?? Future.value(AuthResponse());
    }
    if (invocation.memberName == #resetPassword) {
      return onResetPassword?.call() ?? Future<void>.value();
    }
    if (invocation.memberName == #fetchProfileAfterAuth ||
        invocation.memberName == #fetchProfile) {
      return Future<UserProfile?>.value(profile);
    }
    if (invocation.memberName == #signOut ||
        invocation.memberName == #restoreAccount ||
        invocation.memberName == #requestAccountDeletion ||
        invocation.memberName == #updateDisplayName) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class StubRecurringMoneyRuleRepository implements RecurringMoneyRuleRepository {
  StubRecurringMoneyRuleRepository({this.autoLogCount = 0});

  final int autoLogCount;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #processAutoLogDueExpenses) {
      return Future<int>.value(autoLogCount);
    }
    return super.noSuchMethod(invocation);
  }
}

class StubFeedbackRepository implements FeedbackRepository {
  bool submitted = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submit) {
      submitted = true;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class StubFamilyRepository implements FamilyRepository {
  FamilyMemberDetails? lastUpsertedDetails;
  String? lastUpsertedMemberId;
  String? lastAddedMemberName;
  String? lastAddedRelationship;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #upsertDetails) {
      lastUpsertedMemberId = invocation.positionalArguments[0] as String;
      lastUpsertedDetails =
          invocation.positionalArguments[1] as FamilyMemberDetails;
      return Future<void>.value();
    }
    if (invocation.memberName == #addRosterMember) {
      final named = invocation.namedArguments;
      lastAddedMemberName = named[#displayName] as String;
      lastAddedRelationship = named[#relationship] as String;
      return Future<String>.value('member-new');
    }
    return super.noSuchMethod(invocation);
  }
}

class StubExpenseRepository implements ExpenseRepository {
  Expense? lastCreated;
  String? lastCreatedTitle;
  double? lastCreatedAmount;
  String? lastCreatedCategoryId;
  String? lastCreatedNote;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createExpense) {
      final named = invocation.namedArguments;
      lastCreatedTitle = named[#title] as String;
      lastCreatedAmount = named[#amount] as double;
      lastCreatedCategoryId = named[#categoryId] as String;
      lastCreatedNote = named[#note] as String?;
      lastCreated = Expense(
        id: 'exp-new',
        householdId: named[#householdId] as String,
        categoryId: lastCreatedCategoryId!,
        amount: lastCreatedAmount!,
        title: lastCreatedTitle!,
        expenseDate: named[#expenseDate] as DateTime,
        note: lastCreatedNote,
      );
      return Future<Expense>.value(lastCreated!);
    }
    return super.noSuchMethod(invocation);
  }
}

class StubExpenseGroupsRepository implements ExpenseGroupsRepository {
  String? lastGroupId;
  String? lastFromMemberId;
  String? lastToMemberId;
  double? lastAmount;
  String? lastNote;
  var recordSettlementCalls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #recordSettlement) {
      recordSettlementCalls++;
      final named = invocation.namedArguments;
      lastGroupId = named[#groupId] as String;
      lastFromMemberId = named[#fromMemberId] as String;
      lastToMemberId = named[#toMemberId] as String;
      lastAmount = named[#amount] as double;
      lastNote = named[#note] as String?;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class StubHouseholdRepository implements HouseholdRepository {
  StubHouseholdRepository({
    this.pendingInvites = const [],
    this.createdHouseholdId = 'hh-new',
  });

  final List<Map<String, dynamic>> pendingInvites;
  final String createdHouseholdId;
  String? lastCreatedName;
  String? lastAcceptedHouseholdId;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetchPendingInvitesForUser) {
      return Future<List<Map<String, dynamic>>>.value(pendingInvites);
    }
    if (invocation.memberName == #createHousehold) {
      lastCreatedName = invocation.positionalArguments.first as String;
      return Future<String>.value(createdHouseholdId);
    }
    if (invocation.memberName == #acceptInvite) {
      lastAcceptedHouseholdId = invocation.positionalArguments.first as String;
      return Future<void>.value();
    }
    if (invocation.memberName == #fetchActiveHousehold) {
      return Future<Household?>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class StubHouseholdSettingsRepository implements HouseholdSettingsRepository {
  StubHouseholdSettingsRepository({this.lastUpdatedModules});

  List<String>? lastUpdatedModules;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateEnabledModules) {
      lastUpdatedModules = (invocation.positionalArguments[1] as List).cast();
      return Future<void>.value();
    }
    if (invocation.memberName == #fetchSettings) {
      return Future<HouseholdSettings?>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class StubDevicePermissionsService implements DevicePermissionsService {
  StubDevicePermissionsService({
    this.permissions = const [],
    this.requestResults = const {},
  });

  final List<AppPermissionInfo> permissions;
  final Map<AppPermissionKind, bool> requestResults;
  AppPermissionKind? lastRequested;
  var settingsOpened = false;

  @override
  Future<List<AppPermissionInfo>> load() async => permissions;

  @override
  Future<bool> request(AppPermissionKind kind) async {
    lastRequested = kind;
    return requestResults[kind] ?? true;
  }

  @override
  Future<void> openSettings() async {
    settingsOpened = true;
  }
}

List<AppPermissionInfo> testDevicePermissions({
  PermissionStatus notifications = PermissionStatus.denied,
  PermissionStatus camera = PermissionStatus.granted,
}) {
  return [
    AppPermissionInfo(
      kind: AppPermissionKind.notifications,
      title: 'Notifications',
      reason: 'Needed for reminders',
      status: notifications,
    ),
    AppPermissionInfo(
      kind: AppPermissionKind.camera,
      title: 'Camera',
      reason: 'Needed for photos',
      status: camera,
    ),
  ];
}
