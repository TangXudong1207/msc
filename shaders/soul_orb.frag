// #version 460 core // Removed for Web compatibility

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
uniform float u_mouse_x;          // Manual Rotation X
uniform float u_mouse_y;          // Manual Rotation Y
uniform float u_render_style;     // 0: Legacy, 1: Crystal, 2: Nebula

out vec4 fragColor;

// --- Helper Functions ---
// Smooth Minimum (Polynominal)
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * (1.0 / 4.0);
}

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

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// --- Rotation ---
mat2 rot2D(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// --- Scene Mapping (Mega Bio-Structure) ---
float map_solid(vec3 p) {
    vec3 p_orig = p;

    // 7. Aesthetic (Golden Twist)
    // 整个坐标系的扭曲，影响所有形状
    if (u_saturation > 0.1) {
        float twistAmount = u_saturation * 1.5; // Starts earlier, gets stronger
        float c = cos(twistAmount * p.y);
        float s = sin(twistAmount * p.y);
        mat2 m = mat2(c, -s, s, c);
        p = vec3(m * p.xz, p.y).xzy;
    }

    // 1. Agency (Core Energy / Internal Flow)
    // 这是一个只影响内部的形变，为了体现“流体核心”，我们在表面加一点高频但低幅度的流动
    float coreFlow = 0.0;
    if (u_turbulence > 0.1) {
        // Fast moving noise
        coreFlow = fbm(p * 3.0 + vec3(0.0, -u_time * 2.0 * u_turbulence, 0.0)) * 0.1 * u_turbulence;
    }

    // 2. Coherence (Crystal Structure)
    // 从球体生长出的晶体
    float sphere = sdSphere(p, 0.9); // Base core
    
    // Octahedron representing Crystal Armor
    // Rotation gives it a more dynamic "grown" look
    mat2 rotArmor = rot2D(u_time * 0.1); 
    vec3 p_armor = p;
    p_armor.xz *= rotArmor;
    float crystal = sdOctahedron(p_armor, 1.2 + u_spikes * 0.5); // size grows with coherence
    
    // Box for ultimate structure
    float block = sdBox(p, vec3(0.8));

    // Mixing Logic:
    // Low Coherence -> Liquid Sphere
    // High Coherence -> Sharp Crystal
    float baseShape;
    if (u_spikes < 0.5) {
        // Sphere -> Crystal
        float t = u_spikes * 2.0;
        baseShape = smin(sphere, crystal, 0.5 - t * 0.3); // Starts soft, gets harder
    } else {
        // Crystal -> Block Architecture
        float t = (u_spikes - 0.5) * 2.0;
        baseShape = mix(crystal, block, t);
    }
    
    // Add Agency Flow to the surface
    baseShape -= coreFlow;

    // 3. Care (Bio-Luminescence / Fur)
    // Instead of simple inflation, we modulate the surface detail to look specific
    // High Care = Smooth + "Fuzzy" (Micro noise)
    if (u_inner_glow > 0.1) {
        float fuzz = noise(p * 20.0) * 0.02 * u_inner_glow; // Micro texture
        float inflation = u_inner_glow * 0.15;
        baseShape -= (inflation + fuzz);
    }

    float d = baseShape;

    // 4. Transcendence (Levitation / Fragmentation)
    // Anti-gravity disintegration: Erosion + Floating Debris
    if (u_aura_intensity > 0.05) {
        // --- 1. Erosion (Breaking apart) ---
        // Create jagged slices that move UP
        vec3 p_erode = p + fbm(p * 3.0) * 0.2; // Distort coordinates for organic breaks
        float lift = u_time * 0.3;
        // Waves of "Nothingness" rising up
        float voidWave = sin(p_erode.y * 6.0 - lift * 2.0 + p.x*2.0); 
        
        // Threshold: How much to cut? 
        // At low intensity, threshold is high (cut nothing). 
        // At high intensity, threshold is low (cut almost everything).
        float cutThreshold = 0.8 - u_aura_intensity * 1.5; 
        
        if (voidWave > cutThreshold) {
            // Calculate distance to the "edge" of the void
            // This effectively carves out the chunks
            float cutDist = (voidWave - cutThreshold) * 0.3;
            d = max(d, -cutDist); // Subtraction
        }

        // --- 2. Floating Debris (Anti-Gravity Particles) ---
        // Add small chunks that float upwards around the core
        // Grid-based particle system
        vec3 q = p * 2.0; 
        q.y -= u_time * 0.8; // Particles move UP faster than erosion
        
        // Domain repetition
        vec3 id = floor(q);
        vec3 local = fract(q) - 0.5;
        
        // Randomize size presence
        float r = noise(id * 13.5); // 0..1
        
        // Only show some particles, more if intensity is high
        if (r > (0.9 - u_aura_intensity * 0.6)) {
             float debrisSize = 0.1 * u_aura_intensity * r; // Variable size
             float debris = length(local) - debrisSize;
             
             // Smooth union to make them feel like droplets separating
             d = smin(d, debris, 0.2); 
        }
    }

    // 6. Nihilism (Hollow Core - retained as part of Transcendence/Void)
    if (u_hole_radius > 0.1) {
        float inner = sdSphere(p, u_hole_radius * 1.0);
        d = max(d, -inner);
    }

    // Global Rounding (always a little bit to look nice)
    d -= 0.02;

    return d;
}

// Loop removed. Use map_solid instead.
// float map_nebula(vec3 p) { ... } removed to avoid unused function warning/error


// --- Color Palette (Hyper-Spectral shim) ---
vec3 palette(float t) {
    // A richer, more mystique palette
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

// --- Iridescence (Thin Film Interference Approx) ---
vec3 iridescence(float t) {
    // Returns a spectral color based on viewing angle
    return 0.5 + 0.5 * cos(6.28318 * (vec3(1.0) * t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    // Standard UV normalization
    vec2 uv_norm = FlutterFragCoord().xy / u_resolution.xy;
    vec2 uv = uv_norm * 2.0 - 1.0;
    if (u_resolution.x > u_resolution.y) {
        uv.x *= u_resolution.x / u_resolution.y;
    } else {
        uv.y *= u_resolution.y / u_resolution.x;
    }

    // Camera setup
    vec3 ro = vec3(0.0, 0.0, -3.2); // Further back
    vec3 rd = normalize(vec3(uv, 1.5)); // Field of view

    // Levitation (Breath) - subtle vertical movement
    ro.y += sin(u_time * 0.5 + 4.0) * 0.05;

    // --- Interaction (Rotation) ---
    float autoYaw = u_time * 0.15;
    float autoPitch = sin(u_time * 0.1) * 0.05;
    float totalYaw = autoYaw + u_mouse_x * 4.0; 
    float totalPitch = autoPitch + u_mouse_y * 4.0;

    mat2 rotY = rot2D(totalYaw);
    ro.xz *= rotY;
    rd.xz *= rotY;
    
    mat2 rotX = rot2D(totalPitch);
    ro.yz *= rotX;
    rd.yz *= rotX;

    // --- Raymarching ---
    float t = 0.0;
    float d = 0.0;
    bool hit = false;
    vec3 p = vec3(0.0);
    
    int steps_taken = 0;
    const int MAX_STEPS = 64; 
    
    for (int i = 0; i < MAX_STEPS; i++) {
        p = ro + rd * t;
        d = map_solid(p);
        
        t += d * 0.6; // Higher precision step (slower)
        
        if (d < 0.002) {
            hit = true;
            break; 
        }
        if (t > 10.0) break;
        steps_taken = i;
    }

    vec3 col = vec3(0.0);
    vec3 bgCol = vec3(0.02, 0.02, 0.03);

    if (hit) {
        // --- Geometry Surface Logic ---
        vec2 e = vec2(0.002, 0.0);
        vec3 n = normalize(vec3(
            map_solid(p + e.xyy) - map_solid(p - e.xyy),
            map_solid(p + e.yxy) - map_solid(p - e.yxy),
            map_solid(p + e.yyx) - map_solid(p - e.yyx)
        ));

        // Lighting Vectors
        vec3 lightPos = vec3(2.0, 2.0, -3.0);
        vec3 l = normalize(lightPos - p);
        vec3 v = normalize(ro - p);
        vec3 h = normalize(l + v);
        vec3 ref = reflect(rd, n);

        // --- 7 Laws Visual Implementation ---

        // 5. Curiosity (Iridescence / Spectral Color)
        // Base color derived from position + time + palette
        float colorT = length(p) * 0.4 - u_time * 0.1 * u_color_shift_speed;
        vec3 baseColor = palette(colorT);
        
        // Iridescent coat based on viewing angle (Fresnel-like)
        float ndotv = max(dot(n, v), 0.0);
        vec3 iridescent = iridescence(ndotv * 2.0 + u_time * 0.1);

        // Mix base with iridescence based on user "saturation" (mapped to Aesthetic/Curiosity split)
        baseColor = mix(baseColor, iridescent, 0.5 * u_color_shift_speed); 


        // 6. Reflection (Deep Refraction / Ghosting)
        // Fake environment map
        vec3 skyCol = vec3(0.1, 0.3, 0.6);
        vec3 groundCol = vec3(0.1, 0.1, 0.1);
        vec3 envCol = mix(groundCol, skyCol, smoothstep(-0.2, 0.2, ref.y));
        
        // Crystal style handling
        float fresnel = pow(1.0 - ndotv, 3.0);
        float specSharp = pow(max(dot(n, h), 0.0), 64.0); // Sharp spec

        // 1. Agency (Internal Magma/Fire)
        // If we have high turbulence, we want emission (light coming from inside)
        vec3 emission = vec3(0.0);
        if (u_turbulence > 0.01) {
            // Noise based on surface position to simulate magma under crust
            float magma = fbm(p * 4.0 - vec3(0.0, u_time*2.0, 0.0));
            // Only show in crevices (AO-like) or pattern
            magma = smoothstep(0.4, 0.8, magma); 
            emission = vec3(1.0, 0.3, 0.1) * magma * u_turbulence * 2.5;
        }

        // 2. Coherence (Crystal Armor)
        // High Coherence = High Reflectivity, Sharp edges
        float reflectivity = u_spikes; // 0..1
        vec3 reflection = envCol * reflectivity * fresnel;
        
        // 3. Care (Bio / Subsurface)
        // Simulating SSS (Subsurface Scattering) cheaply
        // Light passing through the object
        float sss = pow(max(0.0, dot(l, -rd)), 4.0) * u_inner_glow;
        vec3 careGlow = vec3(0.2, 0.8, 0.6) * sss * 1.5; 

        // Combine Lighting Terms
        float diff = max(dot(n, l), 0.0);
        float amb = 0.1;

        // Composite
        col = baseColor * (diff + amb);
        col += reflection;             // Surface reflection
        col += specSharp * reflectivity; // Crystal sharpness
        col += emission;               // Internal Fire (Agency)
        col += careGlow;               // Inner warmth (Care)
        
        // Darken crevices (AO approximation based on step count)
        float ao = 1.0 - (float(steps_taken) / float(MAX_STEPS));
        col *= ao;

    } else {
        // Skybox logic (Simple gradient)
        col = bgCol;
    }

    // --- Post-Process Volumetrics ---
    
    // 4. Transcendence (Aura / particles)
    // Add additive glow based on proximity to center + noise
    if (u_aura_intensity > 0.1) {
       float dist = length(uv);
       // Outer glow aura
       float glow = 1.0 / (dist * dist * 4.0 + 0.1) * u_aura_intensity * 0.2;
       col += vec3(0.4, 0.1, 0.8) * glow;
       
       // Rising particles visual (cheap 2D effect over 3D)
       float partNoise = fbm(vec3(uv * 5.0, u_time * 0.5));
       if (partNoise > 0.6) {
           float fade = smoothstep(0.6, 1.0, partNoise);
           col += vec3(0.8, 0.8, 1.0) * fade * u_aura_intensity * 0.3;
       }
    }
    
    // 3. Care (Tendrils/Fur - Visual fluff)
    // If user wants bio-feel, add a soft rim light in screen space or volume
    if (u_inner_glow > 0.5) {
         // Soft halo
         float halo = exp(-length(uv) * 2.0);
         col += vec3(0.2, 0.6, 0.4) * halo * (u_inner_glow - 0.5) * 0.2;
    }

    // Gamma correction
    col = pow(col, vec3(0.4545));
    
    fragColor = vec4(col, 1.0);
}
