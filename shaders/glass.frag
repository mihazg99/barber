#version 320 es

// Ultra-Clean Crystal Glass Shader - Sapphire Architect Edition
// Creates perfectly transparent glass with subtle refraction and specular borders

precision highp float;

// Flutter uniforms
uniform vec2 uSize;         // Widget size
uniform float uTime;        // Time in seconds
uniform vec3 uBrandColor;   // Brand color (RGB 0-1)
uniform float uMorphProgress; // Morph progress 0.0 to 1.0

// Output
out vec4 fragColor;

// Constants for ultra-clean crystal
const float MAX_OPACITY = 0.05;      // Maximum opacity for ultra-transparency
const float BORDER_WIDTH = 0.02;     // 2% border width
const float HOTSPOT_RADIUS = 0.3;    // Hotspot influence radius

// Simple hash for subtle texture
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Very subtle noise for glass texture
float subtleNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / uSize;
    
    // Center coordinates
    vec2 center = uv - 0.5;
    float dist = length(center);
    
    // ULTRA-TRANSPARENT BASE
    // Start with pure white at very low opacity
    vec3 glassTint = vec3(1.0, 1.0, 1.0) * MAX_OPACITY;
    
    // Add extremely subtle texture (barely visible)
    float texture = subtleNoise(uv * 50.0 + uTime * 0.02) * 0.01;
    vec3 baseColor = glassTint + vec3(texture);
    
    // SUBTLE REFRACTION EFFECT
    // Very gentle warping based on distance and time
    float refraction = sin(uTime * 0.3 + dist * 6.28318) * 0.003;
    baseColor += vec3(refraction * 0.5);
    
    // SPECULAR BORDER WITH HOTSPOT
    // Calculate distance to nearest edge
    float edgeDistX = min(uv.x, 1.0 - uv.x);
    float edgeDistY = min(uv.y, 1.0 - uv.y);
    float edgeDist = min(edgeDistX, edgeDistY);
    
    // Create border mask (1.0 at border, 0.0 inside)
    float borderMask = 1.0 - smoothstep(0.0, BORDER_WIDTH, edgeDist);
    
    // Light hotspot at top-left corner
    vec2 hotspotPos = vec2(0.2, 0.2);
    float hotspotDist = length(uv - hotspotPos);
    float hotspot = 1.0 - smoothstep(0.0, HOTSPOT_RADIUS, hotspotDist);
    
    // Border color: white hotspot transitioning to brand color
    vec3 whiteHighlight = vec3(1.0, 1.0, 1.0) * 0.3;  // White at 0.3 alpha
    vec3 brandHighlight = uBrandColor * 0.15;          // Brand at 0.15 alpha
    
    // Mix based on hotspot influence
    vec3 borderColor = mix(brandHighlight, whiteHighlight, hotspot);
    
    // Animate border intensity with time (subtle pulse)
    float borderIntensity = 0.7 + sin(uTime * 0.4) * 0.3;
    borderColor *= borderIntensity;
    
    // Apply border
    vec3 finalColor = mix(baseColor, borderColor, borderMask);
    
    // BRIGHTNESS GRADIENT (top-left to bottom-right)
    // Simulates light hitting the glass
    vec2 lightDir = normalize(vec2(-1.0, -1.0));
    float lightInfluence = dot(normalize(center), lightDir) * 0.5 + 0.5;
    finalColor += vec3(lightInfluence * 0.02);
    
    // CENTER BRIGHTNESS (glass is slightly brighter in the center)
    float centerBrightness = (1.0 - smoothstep(0.0, 0.5, dist)) * 0.03;
    finalColor += vec3(centerBrightness);
    
    // MORPH EFFECT: Add subtle brand color influence during morph
    vec3 morphTint = uBrandColor * uMorphProgress * 0.05;
    finalColor += morphTint;
    
    // Output with full opacity (transparency comes from color values)
    fragColor = vec4(finalColor, 1.0);
}
