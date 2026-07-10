-- Link subscriptions to how they are paid (UPI, card, bank, etc.)

alter table public.subscriptions
  add column if not exists payment_method text check (
    payment_method is null
    or payment_method in (
      'upi',
      'credit_card',
      'debit_card',
      'net_banking',
      'wallet',
      'cash',
      'other'
    )
  ),
  add column if not exists payment_detail text;
