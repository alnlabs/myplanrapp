import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/widgets/myplanr_logo.dart';
import '../../../shared/widgets/secret_tap.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      useLogo: true,
      title: AppStrings.onboardingSlide1Title,
      body: AppStrings.onboardingSlide1Body,
    ),
    _Slide(
      icon: Icons.inventory_2_outlined,
      title: AppStrings.onboardingSlide2Title,
      body: AppStrings.onboardingSlide2Body,
    ),
    _Slide(
      icon: Icons.event_note_outlined,
      title: AppStrings.onboardingSlide3Title,
      body: AppStrings.onboardingSlide3Body,
    ),
    _Slide(
      icon: Icons.rocket_launch_outlined,
      title: AppStrings.onboardingSlide4Title,
      body: AppStrings.onboardingSlide4Body,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({required bool register}) async {
    await setOnboardingCompleted();
    ref.invalidate(onboardingCompletedProvider);
    if (!mounted) return;
    context.go(register ? '/register' : '/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _complete(register: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _complete(register: true),
                child: const Text(AppStrings.skip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (slide.useLogo)
                          const SecretTap(
                            child: MyPlanrLogo(height: 96, showWordmark: true),
                          )
                        else
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              slide.icon,
                              size: 40,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        const SizedBox(height: 28),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _next,
                    child: Text(isLast ? AppStrings.getStarted : AppStrings.next),
                  ),
                  if (isLast) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _complete(register: false),
                      child: const Text(AppStrings.signIn),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    this.icon,
    this.useLogo = false,
    required this.title,
    required this.body,
  });

  final IconData? icon;
  final bool useLogo;
  final String title;
  final String body;
}
