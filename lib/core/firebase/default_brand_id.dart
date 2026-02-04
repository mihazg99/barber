/// Fallback brand ID when config has no default_brand_id.
const String fallbackBrandId = 'default';

/// Returns [configBrandId] if non-empty, else [fallbackBrandId].
String effectiveBrandId(String configBrandId) =>
    configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
