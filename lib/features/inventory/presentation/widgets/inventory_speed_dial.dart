import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/core/router/app_routes.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/widgets/custom_bottom_sheet.dart';
import 'package:inventory/features/inventory/presentation/enums/speed_dial_bottom_sheet_type.dart';
import 'package:inventory/features/inventory/presentation/widgets/bottom_sheets/add_location_bottom_sheet.dart';
import 'package:inventory/features/inventory/presentation/widgets/bottom_sheets/add_box_bottom_sheet.dart';

class InventorySpeedDial extends StatefulWidget {
  const InventorySpeedDial({super.key});

  @override
  State<InventorySpeedDial> createState() => _InventorySpeedDialState();
}

class _InventorySpeedDialState extends State<InventorySpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _showAddSheet(SpeedDialBottomSheetType type) {
    switch (type) {
      case SpeedDialBottomSheetType.addLocation:
        AddLocationBottomSheet.show(context);
        break;
      case SpeedDialBottomSheetType.addBox:
        AddBoxBottomSheet.show(context);
        break;
    }
    _toggle();
  }

  @override
  Widget build(BuildContext context) {
    // Define intervals for staggered animation (bottom to top)
    final itemAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    final boxAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
    );
    final locationAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          _AnimatedSpeedDialAction(
            animation: locationAnim,
            child: _SpeedDialAction(
              icon: Icons.location_on,
              label: 'Add new location',
              onTap: () => _showAddSheet(SpeedDialBottomSheetType.addLocation),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedSpeedDialAction(
            animation: boxAnim,
            child: _SpeedDialAction(
              icon: Icons.add_box,
              label: 'Add new box',
              onTap: () => _showAddSheet(SpeedDialBottomSheetType.addBox),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedSpeedDialAction(
            animation: itemAnim,
            child: _SpeedDialAction(
              icon: Icons.add_shopping_cart,
              label: 'Add new item',
              onTap: () {
                _toggle();
                GoRouter.of(context).pushNamed(AppRoute.addNewItem.name);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: context.appColors.primaryColor,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.add, size: 32, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _SpeedDialAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  static const double _labelWidth = 150;

  const _SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                color: context.appColors.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: Colors.white, size: 24)),
            ),
          ),
          const Gap(8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              width: _labelWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.appColors.menuBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.18 * 255).toInt()),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(color: context.appColors.primaryTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSpeedDialAction extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedSpeedDialAction({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
