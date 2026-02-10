import 'package:barber/core/errors/failure.dart';

class BrandSelectionFailure extends Failure {
  const BrandSelectionFailure(super.message);
}

class BrandNotFoundFailure extends BrandSelectionFailure {
  const BrandNotFoundFailure() : super('Brand not found');
}

class BrandAlreadyJoinedFailure extends BrandSelectionFailure {
  const BrandAlreadyJoinedFailure()
    : super('You have already joined this brand');
}

class InvalidQrCodeFailure extends BrandSelectionFailure {
  const InvalidQrCodeFailure() : super('Invalid QR code');
}

class NoBrandsFoundFailure extends BrandSelectionFailure {
  const NoBrandsFoundFailure() : super('No brands found');
}
