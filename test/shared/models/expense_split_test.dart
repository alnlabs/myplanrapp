import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/expense_split.dart';

void main() {
  group('ExpenseSplit.fromJson', () {
    test('parses all fields with nested member name', () {
      final split = ExpenseSplit.fromJson({
        'id': 's1',
        'expense_id': 'e1',
        'group_member_id': 'gm1',
        'share_type': 'percent',
        'share_value': 50,
        'owed_amount': 25,
        'expense_group_members': {'display_name': 'Alex'},
      });
      expect(split.id, 's1');
      expect(split.expenseId, 'e1');
      expect(split.groupMemberId, 'gm1');
      expect(split.shareType, 'percent');
      expect(split.shareValue, 50);
      expect(split.owedAmount, 25);
      expect(split.memberName, 'Alex');
    });

    test('allows null share_value', () {
      final split = ExpenseSplit.fromJson({
        'id': 's1',
        'expense_id': 'e1',
        'group_member_id': 'gm1',
        'share_type': 'equal',
        'owed_amount': 33.33,
      });
      expect(split.shareValue, isNull);
      expect(split.memberName, isNull);
    });
  });

  group('ExpenseSplit.toRpcJson', () {
    test('includes share_value even when null', () {
      const split = ExpenseSplit(
        id: 's1',
        expenseId: 'e1',
        groupMemberId: 'gm1',
        shareType: 'equal',
        owedAmount: 10,
      );
      expect(split.toRpcJson(), {
        'group_member_id': 'gm1',
        'share_type': 'equal',
        'share_value': null,
        'owed_amount': 10,
      });
    });

    test('includes share_value when set', () {
      const split = ExpenseSplit(
        id: 's1',
        expenseId: 'e1',
        groupMemberId: 'gm1',
        shareType: 'exact',
        shareValue: 42,
        owedAmount: 42,
      );
      expect(split.toRpcJson()['share_value'], 42);
    });
  });

  group('ExpenseSplitInput.toRpcJson', () {
    test('omits share_value key when null', () {
      const input = ExpenseSplitInput(
        groupMemberId: 'gm1',
        shareType: 'equal',
        owedAmount: 10,
      );
      final json = input.toRpcJson();
      expect(json.containsKey('share_value'), isFalse);
      expect(json['group_member_id'], 'gm1');
      expect(json['share_type'], 'equal');
      expect(json['owed_amount'], 10);
    });

    test('includes share_value when set', () {
      const input = ExpenseSplitInput(
        groupMemberId: 'gm1',
        shareType: 'percent',
        shareValue: 25,
        owedAmount: 25,
      );
      expect(input.toRpcJson()['share_value'], 25);
    });
  });
}
