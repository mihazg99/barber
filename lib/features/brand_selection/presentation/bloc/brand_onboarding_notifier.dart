import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/auth/domain/failures/auth_failure.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/brand_selection/domain/failures/brand_selection_failure.dart';
import 'package:barber/features/brand_selection/domain/repositories/user_brands_repository.dart';

class BrandOnboardingState {
  const BrandOnboardingState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedBrand,
    this.searchResult,
  });

  final bool isLoading;
  final String? errorMessage;
  final BrandEntity? selectedBrand;
  final BrandEntity? searchResult;

  BrandOnboardingState copyWith({
    bool? isLoading,
    String? errorMessage,
    BrandEntity? selectedBrand,
    BrandEntity? searchResult,
    bool clearSearchResult = false,
  }) {
    return BrandOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      searchResult:
          clearSearchResult ? null : (searchResult ?? this.searchResult),
    );
  }
}

class BrandOnboardingNotifier
    extends BaseNotifier<BrandOnboardingState, AuthFailure> {
  BrandOnboardingNotifier(
    this._brandRepository,
    this._userBrandsRepository,
  ) {
    setData(const BrandOnboardingState());
  }

  final BrandRepository _brandRepository;
  final UserBrandsRepository _userBrandsRepository;

  /// Handle QR code scan. Expected format: "brand:{brandId}"
  Future<void> handleQrCode(String qrCode, String userId) async {
    final current = data ?? const BrandOnboardingState();
    setData(current.copyWith(isLoading: true, errorMessage: null));

    // Parse QR code
    if (!qrCode.startsWith('brand:')) {
      setData(
        current.copyWith(
          isLoading: false,
          errorMessage: const InvalidQrCodeFailure().message,
        ),
      );
      return;
    }

    final brandId = qrCode.substring(6).trim();
    if (brandId.isEmpty) {
      setData(
        current.copyWith(
          isLoading: false,
          errorMessage: const InvalidQrCodeFailure().message,
        ),
      );
      return;
    }

    await _joinBrand(brandId, userId);
  }

  /// Join a brand by ID.
  Future<void> joinBrand(String brandId, String userId) async {
    final current = data ?? const BrandOnboardingState();
    setData(current.copyWith(isLoading: true, errorMessage: null));
    await _joinBrand(brandId, userId);
  }

  Future<void> _joinBrand(String brandId, String userId) async {
    final current = data ?? const BrandOnboardingState();

    // Verify brand exists
    final brandResult = await _brandRepository.getById(brandId);
    BrandEntity? brand;
    brandResult.fold(
      (failure) {
        setData(
          current.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
        return;
      },
      (b) {
        if (b == null) {
          setData(
            current.copyWith(
              isLoading: false,
              errorMessage: const BrandNotFoundFailure().message,
            ),
          );
          return;
        }
        brand = b;
      },
    );

    if (brand == null) return;

    // Join brand
    final joinResult = await _userBrandsRepository.joinBrand(userId, brandId);
    joinResult.fold(
      (failure) {
        setData(
          current.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
      },
      (_) {
        setData(
          current.copyWith(
            isLoading: false,
            selectedBrand: brand,
          ),
        );
      },
    );
  }

  /// Search for a brand by tag. Updates [searchResult].
  Future<void> searchByTag(String tag) async {
    final current = data ?? const BrandOnboardingState();

    // Clear previous search result & errors before starting
    setData(
      current.copyWith(
        isLoading: true,
        errorMessage: null,
        clearSearchResult: true,
      ),
    );

    final normalizedTag = tag
        .trim()
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('@', '');
    if (normalizedTag.isEmpty) {
      setData(current.copyWith(isLoading: false));
      return;
    }

    final result = await _brandRepository.getByTag(normalizedTag);

    result.fold(
      (failure) {
        setData(
          current.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          ),
        );
      },
      (brand) {
        if (brand == null) {
          setData(
            current.copyWith(
              isLoading: false,
              errorMessage:
                  const BrandNotFoundFailure()
                      .message, // Or custom 'Tag not found'
            ),
          );
        } else {
          setData(
            current.copyWith(
              isLoading: false,
              searchResult: brand,
            ),
          );
        }
      },
    );
  }

  void clearSearch() {
    final current = data ?? const BrandOnboardingState();
    setData(current.copyWith(clearSearchResult: true, errorMessage: null));
  }

  void reset() {
    setData(const BrandOnboardingState());
  }
}
