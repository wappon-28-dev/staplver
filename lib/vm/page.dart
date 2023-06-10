import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/state.dart';

part 'page.g.dart';

@riverpod
class Page extends _$Page {
  @override
  PageState build() {
    return const PageState();
  }

  void updateNavbarIndex(int newNavbarIndex) {
    state = state.copyWith(navbarIndex: newNavbarIndex);
  }

  void updateProgress(double newProgress) {
    // debugPrint('newProgress => $newProgress');
    state = state.copyWith(progress: newProgress);
  }

  // ignore: avoid_positional_boolean_parameters
  void updateIsVisibleProgressBar(bool newIsVisibleProgressBar) {
    // debugPrint('newIsVisibleProgressBar => $newIsVisibleProgressBar');
    state = state.copyWith(isVisibleProgressBar: newIsVisibleProgressBar);
  }

  Future<void> resetProgress() async {
    updateIsVisibleProgressBar(false);
    updateProgress(0);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    updateIsVisibleProgressBar(true);
  }

  Future<void> hideProgress() async {
    updateIsVisibleProgressBar(false);
    updateProgress(0);
  }

  Future<void> completeProgress() async {
    updateProgress(1);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    updateIsVisibleProgressBar(false);
  }

  // ignore: avoid_positional_boolean_parameters
  void updateAskWhenClose(bool newAskWhenQuit) {
    debugPrint('newAskWhenQuit => $newAskWhenQuit');
    state = state.copyWith(askWhenQuit: newAskWhenQuit);
  }

  void updateWizardIndex(int newWizardIndex) {
    debugPrint('newWizardIndex => $newWizardIndex');
    state = state.copyWith(wizardIndex: newWizardIndex);
  }
}
