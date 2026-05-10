import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/navigation_provider.dart';

/// Global keys for the guided tour targets
class TourKeys {
  static final homeCard = GlobalKey();
  static final fab = GlobalKey();
  static final navPill = GlobalKey();
  static final searchIcon = GlobalKey();
  static final profileCard = GlobalKey();
}

class TourStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final int tabIndex;

  const TourStep({
    required this.title,
    required this.description,
    required this.targetKey,
    required this.tabIndex,
  });
}

final tourSteps = [
  TourStep(
    title: 'Welcome to Secura',
    description: 'This is your secure dashboard where you can see your recent activity and manage your vault.',
    targetKey: TourKeys.homeCard,
    tabIndex: 0,
  ),
  TourStep(
    title: 'Quick Add',
    description: 'Tap this button to instantly import and encrypt files from your device.',
    targetKey: TourKeys.fab,
    tabIndex: 0,
  ),
  TourStep(
    title: 'Unified Navigation',
    description: 'Switch between your Home dashboard, full Locker, and App Settings seamlessly.',
    targetKey: TourKeys.navPill,
    tabIndex: 0,
  ),
  TourStep(
    title: 'Robust Search',
    description: 'Quickly find any file in your locker by name. Your filenames are securely obfuscated.',
    targetKey: TourKeys.searchIcon,
    tabIndex: 1,
  ),
  TourStep(
    title: 'Profile & Security',
    description: 'Customize your vault identity, change your PIN, and manage advanced security protocols.',
    targetKey: TourKeys.profileCard,
    tabIndex: 2,
  ),
];

class TourState {
  final bool isVisible;
  final int currentStep;
  final bool isCompleted;

  TourState({
    this.isVisible = false,
    this.currentStep = 0,
    this.isCompleted = false,
  });

  TourState copyWith({bool? isVisible, int? currentStep, bool? isCompleted}) {
    return TourState(
      isVisible: isVisible ?? this.isVisible,
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TourNotifier extends Notifier<TourState> {
  final _storage = StorageService();

  @override
  TourState build() {
    _init();
    return TourState();
  }

  Future<void> _init() async {
    final completed = await _storage.getTourCompleted();
    state = state.copyWith(isCompleted: completed);
    
    // Auto-start for first-time users after a short delay
    if (!completed) {
      Future.delayed(const Duration(seconds: 2), () => startTour());
    }
  }

  void startTour() {
    state = state.copyWith(isVisible: true, currentStep: 0);
  }

  Future<void> nextStep() async {
    if (state.currentStep < tourSteps.length - 1) {
      final nextIdx = state.currentStep + 1;
      await _navigateToTabForStep(nextIdx);
      state = state.copyWith(currentStep: nextIdx);
    } else {
      finishTour();
    }
  }

  Future<void> prevStep() async {
    if (state.currentStep > 0) {
      final prevIdx = state.currentStep - 1;
      await _navigateToTabForStep(prevIdx);
      state = state.copyWith(currentStep: prevIdx);
    }
  }

  Future<void> _navigateToTabForStep(int stepIdx) async {
    final step = tourSteps[stepIdx];
    final currentTab = ref.read(navigationProvider);
    if (currentTab != step.tabIndex) {
      ref.read(navigationProvider.notifier).setIndex(step.tabIndex);
      // Wait for page transition animation
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  void skipTour() {
    state = state.copyWith(isVisible: false);
    _markCompleted();
  }

  void finishTour() {
    state = state.copyWith(isVisible: false);
    _markCompleted();
  }

  void restartTour() {
    _storage.setTourCompleted(false);
    state = state.copyWith(isCompleted: false);
    startTour();
  }

  Future<void> _markCompleted() async {
    await _storage.setTourCompleted(true);
    state = state.copyWith(isCompleted: true);
  }
}

final tourProvider = NotifierProvider<TourNotifier, TourState>(TourNotifier.new);
