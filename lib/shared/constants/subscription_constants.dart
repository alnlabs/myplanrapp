import 'package:flutter/material.dart';

class BillingCycles {
  BillingCycles._();

  static const monthly = 'monthly';
  static const yearly = 'yearly';

  static const all = [
    (value: monthly, label: 'Monthly'),
    (value: yearly, label: 'Yearly'),
  ];

  static String labelFor(String value) {
    for (final c in all) {
      if (c.value == value) return c.label;
    }
    return value;
  }
}

class ReminderDaysBefore {
  ReminderDaysBefore._();

  static const options = [1, 3, 7];
}

class PaymentMethods {
  PaymentMethods._();

  static const upi = 'upi';
  static const creditCard = 'credit_card';
  static const debitCard = 'debit_card';
  static const netBanking = 'net_banking';
  static const wallet = 'wallet';
  static const cash = 'cash';
  static const other = 'other';

  static const all = [
    (value: upi, label: 'UPI'),
    (value: creditCard, label: 'Credit card'),
    (value: debitCard, label: 'Debit card'),
    (value: netBanking, label: 'Net banking'),
    (value: wallet, label: 'Wallet'),
    (value: cash, label: 'Cash'),
    (value: other, label: 'Other'),
  ];

  static String labelFor(String value) {
    for (final method in all) {
      if (method.value == value) return method.label;
    }
    return value;
  }

  static String detailHintFor(String? method) {
    return switch (method) {
      upi => 'e.g. name@oksbi or 98xxxxxx12',
      creditCard => 'e.g. HDFC Visa ****1234',
      debitCard => 'e.g. SBI Debit ****5678',
      netBanking => 'e.g. ICICI NetBanking',
      wallet => 'e.g. PhonePe, Paytm, Amazon Pay',
      cash => 'Optional note',
      other => 'Describe how you pay',
      _ => 'Bank, card, UPI ID, or wallet name',
    };
  }

  static IconData iconFor(String? method) {
    return switch (method) {
      upi => Icons.qr_code_2_outlined,
      creditCard => Icons.credit_card_outlined,
      debitCard => Icons.account_balance_outlined,
      netBanking => Icons.language_outlined,
      wallet => Icons.account_balance_wallet_outlined,
      cash => Icons.payments_outlined,
      other => Icons.payment_outlined,
      _ => Icons.payment_outlined,
    };
  }
}
