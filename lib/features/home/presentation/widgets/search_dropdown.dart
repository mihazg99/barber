import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

class SearchDropdown extends HookConsumerWidget {
  const SearchDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final showDropdown = useState(false);
    final searchQuery = useState('');
    final debouncedQuery = useState('');
    final fieldKey = useMemoized(() => GlobalKey(), []);
    final overlayEntry = useRef<OverlayEntry?>(null);

    // Listen to focus changes
    useEffect(() {
      void listener() {
        showDropdown.value = focusNode.hasFocus && controller.text.isNotEmpty;
      }

      focusNode.addListener(listener);
      return () => focusNode.removeListener(listener);
    }, [focusNode]);

    // Debounce searchQuery into debouncedQuery
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedQuery.value = searchQuery.value;
      });
      return () => timer.cancel();
    }, [searchQuery.value]);

    // Trigger search when debouncedQuery changes
    useEffect(() {
      final itemState = ref.read(itemNotifierProvider);
      if (debouncedQuery.value.isNotEmpty) {
        Future.microtask(() {
          ref
              .read(itemNotifierProvider.notifier)
              .searchItemsByName(debouncedQuery.value);
          showDropdown.value = true;
          overlayEntry.value?.markNeedsBuild();
        });
      } else {
        // Only call getAllItems if not already loading or loaded
        if (itemState is! BaseLoading && itemState is! BaseData) {
          Future.microtask(() {
            ref.read(itemNotifierProvider.notifier).getAllItems();
            showDropdown.value = false;
            overlayEntry.value?.markNeedsBuild();
          });
        }
      }
    }, [debouncedQuery.value]);

    // Overlay logic
    void removeDropdown() {
      overlayEntry.value?.remove();
      overlayEntry.value = null;
    }

    useEffect(() {
      if (showDropdown.value &&
          focusNode.hasFocus &&
          overlayEntry.value == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final RenderBox? box =
              fieldKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final Offset position = box.localToGlobal(Offset.zero);
          final double margin = context.appSizes.paddingMedium;
          final double width = box.size.width - 2 * margin;
          final double left = position.dx + margin;
          final double top =
              position.dy + box.size.height + context.appSizes.paddingSmall;
          final entry = OverlayEntry(
            builder: (context) {
              final itemState = ref.watch(itemNotifierProvider);
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        showDropdown.value = false;
                        focusNode.unfocus();
                      },
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: width,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(
                        context.appSizes.borderRadius,
                      ),
                      color: context.appColors.menuBackgroundColor,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: switch (itemState) {
                          BaseLoading() => Center(
                            child: Padding(
                              padding: EdgeInsets.all(
                                context.appSizes.paddingMedium,
                              ),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          BaseError(:final message) => Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.appSizes.paddingMedium,
                              horizontal: context.appSizes.paddingMedium,
                            ),
                            child: Text(
                              'Error: $message',
                              style: TextStyle(
                                color: context.appColors.errorColor,
                              ),
                            ),
                          ),
                          BaseData(:final data) when data.isEmpty => Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.appSizes.paddingMedium,
                              horizontal: context.appSizes.paddingMedium,
                            ),
                            child: Text(
                              'No items found',
                              style: TextStyle(
                                color: context.appColors.secondaryTextColor,
                              ),
                            ),
                          ),
                          BaseData(:final data) => ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.appSizes.paddingSmall,
                            ),
                            shrinkWrap: true,
                            itemCount: data.length,
                            separatorBuilder:
                                (_, __) => Divider(
                                  height: 0.5,
                                  thickness: 0.5,
                                  color: context.appColors.borderColor,
                                ),
                            itemBuilder: (context, idx) {
                              final item = data[idx];
                              return InkWell(
                                onTap: () {
                                  controller.text = item.name;
                                  showDropdown.value = false;
                                  focusNode.unfocus();
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: context.appSizes.paddingMedium,
                                    horizontal: context.appSizes.paddingSmall,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(
                                            color:
                                                context
                                                    .appColors
                                                    .primaryTextColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          color:
                                              context
                                                  .appColors
                                                  .secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
          Overlay.of(context, rootOverlay: true).insert(entry);
          overlayEntry.value = entry;
        });
      } else if ((!showDropdown.value || !focusNode.hasFocus) &&
          overlayEntry.value != null) {
        removeDropdown();
      }
      return () {
        removeDropdown();
      };
    }, [showDropdown.value, focusNode.hasFocus]);

    // Clean up overlay on widget dispose
    useEffect(() {
      return () {
        removeDropdown();
      };
    }, []);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
      child: CustomTextField.search(
        key: fieldKey,
        enabled: true,
        onChanged: (val) {
          searchQuery.value = val;
          showDropdown.value = focusNode.hasFocus && val.isNotEmpty;
        },
        controller: controller,
        focusNode: focusNode,
      ),
    );
  }
}
