import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/utils/schedule_time_parser.dart';

void main() {
  test('parseScheduleTime accepts 24-hour format', () {
    final time = parseScheduleTime('08:30');
    expect(time, isNotNull);
    expect(time!.hour, 8);
    expect(time.minute, 30);
    expect(formatScheduleTime(time), '08:30');
  });

  test('parseScheduleTime accepts 12-hour format', () {
    final time = parseScheduleTime('8:00 PM');
    expect(time, isNotNull);
    expect(time!.hour, 20);
    expect(time.minute, 0);
  });

  test('parseScheduleTime rejects invalid values', () {
    expect(parseScheduleTime(''), isNull);
    expect(parseScheduleTime('25:00'), isNull);
    expect(parseScheduleTime('noon'), isNull);
  });
}
