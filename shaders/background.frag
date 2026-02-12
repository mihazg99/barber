#version 320 es

// Liquid Sapphire Background Shader - Premium Heavy Liquid Edition
// Deep blue ink undulating in darkness with zero color drift

precision highp float;

// Flutter provides these uniforms
uniform vec2 uSize;        // Resolution (width, height)
uniform float uTime;       // Time in seconds

// Output
out vec4 fragColor;

// SAPPHIRE INDIGO PALETTE - Brand Colors Only (ZERO WHITE)
const vec3 SAPPHIRE_DEEP = vec3(0.018, 0.030, 0.075);      // Almost black valleys
const vec3 SAPPHIRE_BASE = vec3(0.059, 0.090, 0.165);      // #0F172A - Base brand color
const vec3 SAPPHIRE_MID = vec3(0.078, 0.110, 0.220);       // Mid sapphire
const vec3 INDIGO_ACCENT = vec3(0.110, 0.120, 0.290);      // #4F46E5 darker (no white)

const float PI = 3.14159265359;
const float LOOP_DURATION = 60.0; // Natural seamless loop

// High-quality noise function
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.13);
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth noise with quintic interpolation for sharper liquid edges
float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Quintic interpolation for sharper features
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 5-octave FBM - optimized for performance while keeping liquid feel
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.6;
    float frequency = 1.8;
    float lacunarity = 2.4;
    float gain = 0.48;
    
    // Reduced to 5 octaves for better performance
    for (int i = 0; i < 5; i++) {
        value += amplitude * smoothNoise(p * frequency);
        amplitude *= gain;
        frequency *= lacunarity;
    }
    
    return value;
}

// Ultra-smooth seamless time loop - multiple frequency circles for natural feel
vec2 seamlessTimeOffset(float time) {
    float loopTime = mod(time, LOOP_DURATION);
    float angle = (loopTime / LOOP_DURATION) * 2.0 * PI;
    
    // Primary circular motion
    vec2 circle1 = vec2(cos(angle), sin(angle)) * 0.5;
    
    // Secondary slower circle for added complexity (makes loop less obvious)
    float angle2 = angle * 0.618034; // Golden ratio for natural feel
    vec2 circle2 = vec2(cos(angle2), sin(angle2)) * 0.3;
    
    // Combine for ultra-natural seamless loop
    return circle1 + circle2;
}

// Heavy liquid undulation - clearly visible viscous movement
float liquidEnergy(vec2 uv, float time) {
    vec2 timeOffset = seamlessTimeOffset(time);
    
    // Create seamless circular motion for all layers
    float loopAngle = (time / LOOP_DURATION) * 2.0 * PI;
    
    // Layer 1: Deep, slow-moving base liquid - MUCH FASTER
    vec2 p1 = uv * 2.2 + timeOffset * 0.8;
    float layer1 = fbm(p1);
    
    // Layer 2: Counter-rotating medium flow - MUCH FASTER
    vec2 p2 = uv * 1.8 - timeOffset * 0.65;
    vec2 circleOffset = vec2(sin(loopAngle * 0.8) * 0.6, cos(loopAngle * 0.8) * 0.6);
    p2 += circleOffset;
    float layer2 = fbm(p2);
    
    // Layer 3: Fine surface tension details - MUCH FASTER
    vec2 p3 = uv * 3.5;
    vec2 circleOffset2 = vec2(sin(loopAngle * 0.5) * 0.5, cos(loopAngle * 0.5) * 0.5);
    p3 += circleOffset2 + timeOffset * 0.4;
    float layer3 = fbm(p3);
    
    // Combine with weighted liquid "mass"
    return layer1 * 0.5 + layer2 * 0.35 + layer3 * 0.15;
}

// Domain warping for thick, ink-like distortion with seamless loop
vec2 domainWarp(vec2 uv, float time) {
    vec2 timeOffset = seamlessTimeOffset(time);
    
    // Use circular motion for seamless warp - FASTER
    float loopAngle = (time / LOOP_DURATION) * 2.0 * PI;
    vec2 warpOffset = vec2(sin(loopAngle * 1.2), cos(loopAngle * 1.2)) * 0.2;
    
    float warp1 = fbm(uv * 2.0 + timeOffset * 0.5 + warpOffset);
    float warp2 = fbm(uv * 2.0 - timeOffset * 0.5 + vec2(5.2, 1.3) - warpOffset);
    
    return uv + vec2(warp1, warp2) * 0.15; // Heavy distortion
}

void main() {
    // Normalize coordinates
    vec2 uv = gl_FragCoord.xy / uSize;
    
    // Apply domain warping for thick liquid feel
    vec2 warpedUV = domainWarp(uv, uTime);
    
    // Generate heavy liquid energy pattern
    float liquid = liquidEnergy(warpedUV, uTime);
    
    // Create deep valleys and bright peaks (simplified for performance)
    liquid = liquid * liquid * 1.2; // Squared for contrast, faster than pow()
    
    // Calculate distance from center for depth
    vec2 center = uv - 0.5;
    float dist = length(center);
    float radialDepth = 1.0 - smoothstep(0.0, 0.8, dist);
    
    // SAPPHIRE INDIGO COLOR MAPPING - Brand colors only, no white
    vec3 color;
    
    if (liquid < 0.35) {
        // Deep valleys - almost black to base
        float t = smoothstep(0.0, 0.35, liquid);
        color = mix(SAPPHIRE_DEEP, SAPPHIRE_BASE, t);
    } else if (liquid < 0.70) {
        // Mid-range - base to mid sapphire
        float t = smoothstep(0.35, 0.70, liquid);
        color = mix(SAPPHIRE_BASE, SAPPHIRE_MID, t);
    } else {
        // Bright peaks - darker indigo only (NO BRIGHT SPOTS)
        float t = smoothstep(0.70, 1.0, liquid);
        color = mix(SAPPHIRE_MID, INDIGO_ACCENT, t * 0.6); // Reduced to prevent white
    }
    
    // Apply radial depth (darker at edges for glass card contrast)
    color = mix(color * 0.55, color, radialDepth);
    
    // Seamless animated brightness pulse using circular motion
    float pulseAngle = (uTime / LOOP_DURATION) * 2.0 * PI;
    float pulse = sin(pulseAngle * 0.5) * 0.04 + 0.96;
    color *= pulse;
    
    // Strong vignette to prevent edge brightness
    float vignette = smoothstep(0.95, 0.15, dist);
    color *= 0.60 + vignette * 0.40;
    
    // AGGRESSIVE COLOR CLAMP - Absolutely NO WHITE allowed
    color.r = clamp(color.r, 0.015, 0.120);  // Red: extremely limited
    color.g = clamp(color.g, 0.025, 0.130);  // Green: extremely limited
    color.b = clamp(color.b, 0.070, 0.300);  // Blue: capped low to prevent white
    
    // Ensure minimum depth
    color = max(color, SAPPHIRE_DEEP);
    
    fragColor = vec4(color, 1.0);
}
