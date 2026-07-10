import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/expense_group.dart';
import 'package:myplanr/shared/models/family_member.dart';
import 'package:myplanr/shared/models/home_asset.dart';
import 'package:myplanr/shared/models/household.dart';
import 'package:myplanr/shared/models/medicine_schedule.dart';
import 'package:myplanr/shared/models/pantry_item.dart';
import 'package:myplanr/shared/models/plan.dart';
import 'package:myplanr/shared/models/recurring_money_rule.dart';
import 'package:myplanr/shared/models/shopping_list_item.dart';
import 'package:myplanr/shared/models/subscription.dart';
import 'package:myplanr/shared/models/user_profile.dart';

const testHouseholdId = 'hh-test-1';
const testUserId = 'user-test-1';

const testUserProfile = UserProfile(
  id: testUserId,
  displayName: 'Test User',
  activeHouseholdId: testHouseholdId,
);

const testExpenseCategories = [
  ExpenseCategory(id: 'cat-food', name: 'Groceries', categoryKind: 'expense'),
  ExpenseCategory(id: 'cat-misc', name: 'Misc', categoryKind: 'expense'),
];

const testIncomeCategories = [
  ExpenseCategory(id: 'cat-salary', name: 'Salary', categoryKind: 'income'),
  ExpenseCategory(id: 'cat-bonus', name: 'Bonus', categoryKind: 'income'),
];

final testFamilyMembers = [
  const FamilyMember(
    id: 'member-1',
    householdId: testHouseholdId,
    displayName: 'Alex',
    relationship: 'self',
    memberType: 'app',
    profileDisplayName: 'Alex Parent',
  ),
  const FamilyMember(
    id: 'member-2',
    householdId: testHouseholdId,
    displayName: 'Sam',
    relationship: 'spouse',
    memberType: 'roster',
  ),
];

final testPantryItem = PantryItem(
  id: 'pantry-1',
  householdId: testHouseholdId,
  name: 'Rice',
  quantity: 2,
  unit: 'kg',
  updatedAt: DateTime(2025, 1, 1),
);

final testStockEvent = StockEvent(
  id: 'event-1',
  itemId: 'pantry-1',
  delta: 1,
  reason: 'restocked',
  note: 'Weekly shop',
  createdAt: DateTime(2025, 6, 1, 10, 30),
);

final testSubscription = Subscription(
  id: 'sub-1',
  householdId: testHouseholdId,
  name: 'Netflix',
  amount: 499,
  billingCycle: 'monthly',
  dueDay: 1,
);

final testRecurringExpenseRule = RecurringMoneyRule(
  id: 'rule-rent',
  householdId: testHouseholdId,
  entryType: 'expense',
  title: 'Rent',
  amount: 15000,
  categoryId: 'cat-rent',
  frequency: 'monthly',
  intervalCount: 1,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 7, 1),
  autoLog: true,
);

final testRecurringIncomeRule = RecurringMoneyRule(
  id: 'rule-salary',
  householdId: testHouseholdId,
  entryType: 'income',
  title: 'Salary',
  incomeSource: 'Acme Corp',
  familyMemberId: 'member-1',
  amount: 75000,
  categoryId: 'cat-salary',
  frequency: 'monthly',
  intervalCount: 1,
  startDate: DateTime(2025, 1, 1),
  nextDueDate: DateTime(2025, 7, 1),
  dayOfMonth: 1,
);

const testSharedExpenseGroup = ExpenseGroup(
  id: 'group-shared-1',
  householdId: testHouseholdId,
  name: 'Trip to Goa',
  groupType: 'shared',
  memberCount: 2,
);

const testOrgExpenseGroup = ExpenseGroup(
  id: 'group-org-1',
  householdId: testHouseholdId,
  name: 'Home repairs',
  groupType: 'organizational',
  memberCount: 1,
);

const testHousehold = Household(
  id: testHouseholdId,
  name: 'Test Home',
  ownerId: testUserId,
);

const testMoneySummary = MoneySummary(
  totalSpent: 5000,
  totalEarned: 80000,
  netAmount: 75000,
);

const testExpenseSummaryRows = [
  ExpenseSummaryRow(
    categoryId: 'cat-food',
    categoryName: 'Groceries',
    totalAmount: 3000,
  ),
  ExpenseSummaryRow(
    categoryId: 'cat-misc',
    categoryName: 'Misc',
    totalAmount: 2000,
  ),
];

final testHomeAsset = HomeAsset(
  id: 'asset-1',
  householdId: testHouseholdId,
  name: 'Refrigerator',
  category: 'appliance',
  itemKind: 'appliance',
  status: 'active',
  createdBy: testUserId,
);

const testFamilyMemberDetails = FamilyMemberDetails(
  familyMemberId: 'member-1',
  householdId: testHouseholdId,
  userId: testUserId,
  phone: '9876543210',
  bloodGroup: 'O+',
);

final testGroupExpense = Expense(
  id: 'exp-group-1',
  householdId: testHouseholdId,
  categoryId: 'cat-food',
  amount: 1200,
  title: 'Dinner',
  expenseDate: DateTime(2025, 7, 5),
  paidByMemberName: 'Alex',
);

const testShoppingListItem = ShoppingListItem(
  id: 'shop-1',
  householdId: testHouseholdId,
  name: 'Milk',
  quantity: 2,
  unit: 'L',
  source: 'manual',
);

final testLowStockPantryItem = PantryItem(
  id: 'pantry-low-1',
  householdId: testHouseholdId,
  name: 'Olive oil',
  quantity: 0.2,
  unit: 'L',
  lowStockThreshold: 0.5,
  updatedAt: DateTime(2025, 1, 1),
);

final testPlan = Plan(
  id: 'plan-1',
  householdId: testHouseholdId,
  createdBy: testUserId,
  scope: 'household',
  planType: 'task',
  title: 'Buy groceries',
  status: 'open',
  reminderEnabled: false,
);

const testMedicineSchedule = MedicineSchedule(
  id: 'med-1',
  familyMemberId: 'member-1',
  householdId: testHouseholdId,
  medicineFor: 'Blood pressure',
  medicineName: 'Amlodipine',
  dosage: '5mg',
  timesPerDay: ['08:00', '20:00'],
);

const testSettlementBalances = [
  ExpenseGroupBalance(
    groupMemberId: 'gm-a',
    displayName: 'Alice',
    paidTotal: 100,
    owedTotal: 50,
    settledIn: 0,
    settledOut: 0,
    netBalance: 50,
  ),
  ExpenseGroupBalance(
    groupMemberId: 'gm-b',
    displayName: 'Bob',
    paidTotal: 0,
    owedTotal: 50,
    settledIn: 0,
    settledOut: 0,
    netBalance: -50,
  ),
];
