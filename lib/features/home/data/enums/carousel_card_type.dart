enum CarouselCardType {
  upgrade(
    text: 'Upgrade your plan and enjoy unlimited QR codes and AI assistant.',
    isFirst: true,
  ),
  qrCodes(
    text: 'Use QR codes on boxes to easily check whats in the box. Generate QR code now.',
    isFirst: false,
  ),
  recent(
    text: 'Statistics can help you see what is the real deal with your inventory.',
    isFirst: false,
  );

  final String text;
  final bool isFirst;

  const CarouselCardType({
    required this.text,
    required this.isFirst,
  });
} 