#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_turbulence;       // Agency
uniform float u_spikes;           // Structure
uniform float u_inner_glow;       // Care
uniform float u_hole_radius;      // Nihilism
uniform float u_color_shift_speed;// Curiosity
uniform float u_saturation;       // Aesthetic
uniform float u_aura_intensity;   // Transcendence
uniform vec2 u_mouse;             // Manual Rotation (x: yaw, y: pitch)

out vec4 fragColor;

// --- Noise Functions ---
vec3 hash33(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yxz + 19.19);
    return fract((p.xxy + p.yxx) * p.zyx);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(dot(hash33(i + vec3(0, 0, 0)), f - vec3(0, 0, 0)),
                       dot(hash33(i + vec3(1, 0, 0)), f - vec3(1, 0, 0)), f.x),
                   mix(dot(hash33(i + vec3(0, 1, 0)), f - vec3(0, 1, 0)),
                       dot(hash33(i + vec3(1, 1, 0)), f - vec3(1, 1, 0)), f.x), f.y),
               mix(mix(dot(hash33(i + vec3(0, 0, 1)), f - vec3(0, 0, 1)),
                       dot(hash33(i + vec3(1, 0, 1)), f - vec3(1, 0, 1)), f.x),
                   mix(dot(hash33(i + vec3(0, 1, 1)), f - vec3(0, 1, 1)),
                       dot(hash33(i + vec3(1, 1, 1)), f - vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- SDF Functions ---
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

// --- Scene Mapping ---
float map(vec3 p) {
    // 1. Agency (Turbulence)
    float displacement = 0.0;
    if (u_turbulence > 0.01) {
        displacement = fbm(p * 2.0 + vec3(0.0, u_time * 0.5, 0.0)) * u_turbulence * 0.4;
    }

    // 2. Structure (Spikes/Shape)
    // Mix between a sphere and an octahedron based on u_spikes
    float sphere = sdSphere(p, 1.0);
    float octa = sdOctahedron(p, 1.3); // Slightly larger to match volume
    float baseShape = mix(sphere, octa, u_spikes);

    float d = baseShape + displacement;

    // 3. Nihilism (Hollow Core)
    // Subtract an inner sphere
    if (u_hole_radius > 0.01) {
        float inner = sdSphere(p, u_hole_radius);
        d = max(d, -inner);
    }

    return d;
}

// --- Color Palette (Cosine based) ---
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

// --- Rotation ---
mat2 rot2D(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    // Simplified UV calculation
    // Use local coordinates normalized to 0..1
    vec2 uv_norm = FlutterFragCoord().xy / u_resolution.xy;
    
    // Map to -1..1
    vec2 uv = uv_norm * 2.0 - 1.0;
    
    // Fix aspect ratio
    if (u_resolution.x > u_resolution.y) {
        uv.x *= u_resolution.x / u_resolution.y;
    } else {
        uv.y *= u_resolution.y / u_resolution.x;
    }

    // Camera setup
    // Move camera back a bit to fit the object if needed
    vec3 ro = vec3(0.0, 0.0, -3.0); // Reset to -3.0
    vec3 rd = normalize(vec3(uv, 1.5)); // Ray direction

    // Levitation (Breathing effect)
    ro.y += sin(u_time * 0.8) * 0.1;

    // Rotation Logic
    // Base auto-rotation speed
    float autoYaw = u_time * 0.3;
    float autoPitch = sin(u_time * 0.2) * 0.1;

    // Manual rotation (from mouse/touch)
    // u_mouse.x controls yaw, u_mouse.y controls pitch
    float totalYaw = autoYaw + u_mouse.x * 4.0; 
    float totalPitch = autoPitch + u_mouse.y * 4.0;

    // Apply rotation (Y-axis first for Yaw)
    mat2 rotY = rot2D(totalYaw);
    ro.xz *= rotY;
    rd.xz *= rotY;
    
    // Apply rotation (X-axis for Pitch)
    mat2 rotX = rot2D(totalPitch);
    ro.yz *= rotX;
    rd.yz *= rotX;

    // Raymarching
    float t = 0.0;
    float d = 0.0;
    int i;
    for (i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        d = map(p);
        if (d < 0.001 || t > 10.0) break;
        t += d;
    }

    vec3 col = vec3(0.0);

    if (t < 10.0) {
        // Hit object
        vec3 p = ro + rd * t;
        
        // Normal calculation
        vec2 e = vec2(0.001, 0.0);
        vec3 n = normalize(vec3(
            map(p + e.xyy) - map(p - e.xyy),
            map(p + e.yxy) - map(p - e.yxy),
            map(p + e.yyx) - map(p - e.yyx)
        ));

        // Lighting
        vec3 lightPos = vec3(2.0, 2.0, -2.0);
        vec3 l = normalize(lightPos - p);
        float diff = max(dot(n, l), 0.0);
        float amb = 0.1;

        // 4. Curiosity (Color Shift)
        // Base color varies with position and time
        float colorT = length(p) * 0.5 + u_time * u_color_shift_speed * 0.2;
        vec3 baseColor = palette(colorT);

        // 5. Care (Inner Glow / SSS approximation)
        // Use the iteration count or normal-view angle to fake SSS
        float fresnel = pow(1.0 + dot(rd, n), 3.0);
        vec3 glowColor = vec3(1.0, 0.6, 0.3); // Warm orange
        vec3 finalColor = baseColor * (diff + amb);
        
        // Mix in inner glow based on u_inner_glow
        finalColor += glowColor * fresnel * u_inner_glow * 2.0;

        col = finalColor;
    } else {
        // Background
        col = vec3(0.05, 0.05, 0.08); // Dark void
    }

    // 6. Transcendence (Aura)
    // Add glow based on distance to center in 2D screen space
    float dist2Center = length(uv);
    // Simple ring glow
    float aura = 0.0;
    if (u_aura_intensity > 0.01) {
        // A ring around radius 1.0 (approx sphere size)
        float ring = 1.0 - smoothstep(0.0, 0.5, abs(dist2Center - 0.9));
        // Rising particles effect (simulated by noise)
        float particles = fbm(vec3(uv * 3.0, u_time)) * step(0.0, uv.y); 
        
        aura = ring * 0.5 + particles * 0.5;
        col += vec3(0.6, 0.8, 1.0) * aura * u_aura_intensity;
    }

    // 7. Aesthetic (Saturation)
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, 0.5 + u_saturation * 0.5); // Base saturation 0.5, up to 1.0+

    // Gamma correction
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
