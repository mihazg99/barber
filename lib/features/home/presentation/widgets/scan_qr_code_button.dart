import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/gen/assets.gen.dart';

class ScanQrCodeButton extends StatelessWidget {
  const ScanQrCodeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
      child: PrimaryButton.big(
        onPressed: () {},
        height: 64,
        icon: SvgPicture.asset(Assets.icons.qrCodeScanner),
        child: Text('Scan QR Code'),
      ),
    );
  }
}
