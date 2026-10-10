import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/local/preferences/preferences_keys.dart';
import '../../../../core/data/local/preferences/preferences_service_provider.dart';

class TopicMiniDrawerState {
  final bool isEnabled;
  final bool isOpen;
  final bool hideCompleted;

  const TopicMiniDrawerState({
    required this.isEnabled,
    required this.isOpen,
    this.hideCompleted = false,
  });

  TopicMiniDrawerState copyWith({
    bool? isEnabled,
    bool? isOpen,
    bool? hideCompleted,
  }) {
    return TopicMiniDrawerState(
      isEnabled: isEnabled ?? this.isEnabled,
      isOpen: isOpen ?? this.isOpen,
      hideCompleted: hideCompleted ?? this.hideCompleted,
    );
  }
}

final topicMiniDrawerControllerProvider =
    NotifierProvider<TopicMiniDrawerController, TopicMiniDrawerState>(
  TopicMiniDrawerController.new,
);

class TopicMiniDrawerController extends Notifier<TopicMiniDrawerState> {
  @override
  TopicMiniDrawerState build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final isEnabled =
        prefs.getBool(PreferencesKeys.topicMiniDrawerEnabled) ?? true;
    final hideCompleted =
        prefs.getBool(PreferencesKeys.topicMiniDrawerHideCompleted) ?? false;
    return TopicMiniDrawerState(
      isEnabled: isEnabled,
      isOpen: false,
      hideCompleted: hideCompleted,
    );
  }

  void open() {
    if (!state.isOpen) {
      state = state.copyWith(isOpen: true);
    }
  }

  void close() {
    if (state.isOpen) {
      state = state.copyWith(isOpen: false);
    }
  }

  void toggle() {
    state = state.copyWith(isOpen: !state.isOpen);
  }

  void setEnabled(bool enabled) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setBool(PreferencesKeys.topicMiniDrawerEnabled, enabled);
    state = state.copyWith(
      isEnabled: enabled,
      isOpen: enabled ? state.isOpen : false,
    );
  }

  void toggleEnabled() {
    setEnabled(!state.isEnabled);
  }

  void setHideCompleted(bool hide) {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setBool(PreferencesKeys.topicMiniDrawerHideCompleted, hide);
    state = state.copyWith(hideCompleted: hide);
  }

  void toggleHideCompleted() {
    setHideCompleted(!state.hideCompleted);
  }
}
