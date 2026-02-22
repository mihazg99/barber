import 'package:flutter/material.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
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
        icon: Assets.icons.qrCodeScanner.svg(),
        child: Text(context.l10n.scanQrCode),
      ),
    );
  }
}
