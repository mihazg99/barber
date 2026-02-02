import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/onboarding/di.dart';
import 'package:barber/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:barber/features/onboarding/presentation/widgets/onboarding_actions.dart';
import 'package:barber/features/onboarding/presentation/widgets/onboarding_pagination_dots.dart';
import 'package:barber/features/onboarding/presentation/widgets/onboarding_slide.dart';

class OnboardingPage extends HookConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final isCompleting = useState(false);

    useEffect(() {
      Future.microtask(() {
        ref.read(onboardingNotifierProvider.notifier).load();
      });
      return null;
    }, []);

    ref.listen<BaseState<OnboardingData>>(onboardingNotifierProvider, (prev, next) {
      switch (next) {
        case BaseData():
          if (isCompleting.value) {
            isCompleting.value = false;
            ref.invalidate(onboardingHasCompletedProvider);
            context.go(AppRoute.home.path);
          }
        case BaseError():
          isCompleting.value = false;
        default:
          break;
      }
    });

    final onboardingState = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: SafeArea(
        child: switch (onboardingState) {
          BaseInitial() => const _OnboardingLoading(),
          BaseLoading() => const _OnboardingLoading(),
          BaseData(:final data) => _OnboardingContent(
              data: data,
              pageController: pageController,
              isCompleting: isCompleting.value,
              onCompletingChanged: (v) => isCompleting.value = v,
            ),
          BaseError(:final message) => _OnboardingError(message: message),
        },
      ),
    );
  }
}

class _OnboardingLoading extends StatelessWidget {
  const _OnboardingLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          context.appColors.primaryColor,
        ),
      ),
    );
  }
}

class _OnboardingContent extends ConsumerWidget {
  const _OnboardingContent({
    required this.data,
    required this.pageController,
    required this.isCompleting,
    required this.onCompletingChanged,
  });

  final OnboardingData data;
  final PageController pageController;
  final bool isCompleting;
  final void Function(bool) onCompletingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            itemCount: data.pages.length,
            onPageChanged: notifier.goToPage,
            itemBuilder: (context, index) {
              return OnboardingSlide(page: data.pages[index]);
            },
          ),
        ),
        Gap(context.appSizes.paddingLarge),
        OnboardingPaginationDots(
          count: data.pages.length,
          currentIndex: data.currentPageIndex,
        ),
        Gap(context.appSizes.paddingLarge),
        OnboardingActions(
          data: data,
          onSkip: () async {
            onCompletingChanged(true);
            await notifier.complete();
          },
          onNext: () {
            notifier.nextPage();
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          onGetStarted: () async {
            onCompletingChanged(true);
            await notifier.complete();
          },
          isCompleting: isCompleting,
        ),
        Gap(context.appSizes.paddingXxl),
      ],
    );
  }
}

class _OnboardingError extends ConsumerWidget {
  const _OnboardingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.appColors.errorColor,
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingMedium),
          TextButton.icon(
            onPressed: () => ref.read(onboardingNotifierProvider.notifier).load(),
            icon: Icon(Icons.refresh, color: context.appColors.primaryColor),
            label: Text(
              'Retry',
              style: TextStyle(color: context.appColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
