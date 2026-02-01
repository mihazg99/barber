import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'carousel_card.dart';
import '../../data/enums/carousel_card_type.dart';
import 'package:inventory/core/theme/app_sizes.dart';

class CarouselSliderSection extends StatelessWidget {
  const CarouselSliderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 90,
          enlargeCenterPage: false,
          viewportFraction: 0.7,
          enableInfiniteScroll: false,
          autoPlay: true,
          padEnds: false,
        ),
        items: CarouselCardType.values.asMap().entries.map((entry) {
          final index = entry.key;
          final cardType = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              right: index == CarouselCardType.values.length - 1 
                ? 0 
                : context.appSizes.paddingMedium,
            ),
            child: CarouselCard(
              text: cardType.text,
              isFirst: cardType.isFirst,
            ),
          );
        }).toList(),
      ),
    );
  }
} 