import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selection keys used across list screens so each list keeps its own state.
class MultiSelectKeys {
  MultiSelectKeys._();

  static const shopping = 'shopping';
  static const receipts = 'receipts';
  static const pantry = 'pantry';
  static const assets = 'assets';
}

class MultiSelectState {
  const MultiSelectState({this.active = false, this.ids = const <String>{}});

  final bool active;
  final Set<String> ids;

  bool get isEmpty => ids.isEmpty;
  int get count => ids.length;
  bool contains(String id) => ids.contains(id);
}

/// Generic, per-list multi-select controller. Keyed by a list identifier so the
/// pantry, assets, shopping and receipts lists each track their own selection.
class MultiSelectNotifier
    extends AutoDisposeFamilyNotifier<MultiSelectState, String> {
  @override
  MultiSelectState build(String arg) => const MultiSelectState();

  /// Enter selection mode with [id] selected.
  void enter(String id) =>
      state = MultiSelectState(active: true, ids: {id});

  void toggle(String id) {
    final next = {...state.ids};
    if (!next.remove(id)) next.add(id);
    // Leaving zero selected keeps the mode active so the bar stays visible.
    state = MultiSelectState(active: true, ids: next);
  }

  void selectAll(Iterable<String> ids) =>
      state = MultiSelectState(active: true, ids: ids.toSet());

  void clear() => state = const MultiSelectState();
}

final multiSelectProvider = NotifierProvider.autoDispose
    .family<MultiSelectNotifier, MultiSelectState, String>(
  MultiSelectNotifier.new,
);
