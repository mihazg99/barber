/// Normalized destination for deep links (Universal/App Links and FCM data).
/// Used by [DeepLinkNotifier] and GoRouter to drive navigation.
///
/// [path] is the route path (e.g. `/manage_booking/abc123`).
/// [queryParams] are decoded query parameters.
/// [brandId] when set must be applied (e.g. [lockedBrandIdProvider]) before
/// navigating so Auth Guard and Brand Locking are respected.
typedef AppPath = ({
  String path,
  Map<String, String> queryParams,
  String? brandId,
});

extension AppPathX on AppPath {
  /// Full location string for GoRouter (path + query string).
  String get location {
    if (queryParams.isEmpty) return path;
    final query = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$path?$query';
  }
}
