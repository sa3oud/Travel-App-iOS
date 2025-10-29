// MULTIPLE VISUAL EFFECTS - Full Screen Coverage
// Each effect is completely different

// Effect 1: FRACTAL ENTITIES (Full Screen)
let fractalEntityShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

// Full screen mandelbrot
float mandelbrot(float2 c) {
    float2 z = float2(0.0);
    for(int i = 0; i < 15; i++) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if(length(z) > 4.0) return float(i) / 15.0;
    }
    return 0.0;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    // Full screen coordinates
    float2 uv = in.texCoord;
    float2 center = (uv - 0.5) * 4.0; // Zoom out to see more fractals
    
    float angle = atan2(center.y, center.x);
    float radius = length(center);
    
    // Extreme full-screen vortex
    angle += radius * 0.8 * sin(u_time * 0.5);
    float2 warped = float2(radius * cos(angle), radius * sin(angle)) / 4.0 + 0.5;
    
    // Camera with extreme chromatic
    float shift = 0.04;
    float3 cam;
    cam.r = u_camera.sample(s, warped + shift).r;
    cam.g = u_camera.sample(s, warped).g;
    cam.b = u_camera.sample(s, warped - shift).b;
    
    // FULL SCREEN mandelbrot fractals
    float2 fractalSpace = (uv - 0.5) * 3.0 + float2(sin(u_time * 0.2), cos(u_time * 0.3));
    float frac = mandelbrot(fractalSpace);
    
    // Add fractals EVERYWHERE
    float3 fractalColor = float3(
        sin(frac * 6.28 + u_time),
        sin(frac * 6.28 + u_time + 2.0),
        sin(frac * 6.28 + u_time + 4.0)
    ) * 0.5 + 0.5;
    
    cam = mix(cam, fractalColor, 0.6); // 60% fractal overlay
    
    // Entity eyes everywhere
    float eyes = step(0.6, sin((uv.x + uv.y) * 20.0 + u_time * 2.0));
    cam += eyes * 0.4;
    
    // Extreme saturation
    float lum = dot(cam, float3(0.3, 0.6, 0.1));
    cam = mix(float3(lum), cam, 3.0);
    
    return float4(cam * (0.8 + 0.2 * sin(u_time * 4.0)), 1.0);
}
"""

// Effect 2: GEOMETRIC ALIENS
let geometricAlienShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.texCoord;
    float2 center = uv - 0.5;
    
    // Alien face geometry - multiple symmetry
    float angle = atan2(center.y, center.x);
    float radius = length(center * 2.0);
    
    // 8-fold symmetry (alien face structure)
    float symmetry = 8.0;
    float foldedAngle = mod(angle + u_time * 0.3, 6.28 / symmetry) * symmetry;
    
    // Geometric patterns
    float pattern1 = sin(foldedAngle * 3.0 + u_time) * sin(radius * 15.0 - u_time * 2.0);
    float pattern2 = cos(foldedAngle * 5.0 - u_time) * cos(radius * 20.0 + u_time * 3.0);
    
    // Camera sample
    float3 cam = u_camera.sample(s, uv).rgb;
    
    // Add alien geometry EVERYWHERE
    cam += float3(pattern1 * 0.5, pattern2 * 0.5, (pattern1 + pattern2) * 0.3);
    
    // "Eyes" in geometric pattern
    float eyes = step(0.7, sin(angle * 6.0 + u_time) * cos(radius * 12.0));
    cam += eyes * float3(0.8, 0.3, 1.0);
    
    // Hyperspace colors
    cam *= float3(
        1.0 + 0.5 * sin(u_time * 0.7),
        1.0 + 0.5 * sin(u_time * 0.8 + 2.0),
        1.0 + 0.5 * sin(u_time * 0.9 + 4.0)
    );
    
    return float4(cam, 1.0);
}
"""

// Effect 3: RAINBOW TUNNEL
let rainbowTunnelShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.texCoord;
    float2 center = uv - 0.5;
    
    float angle = atan2(center.y, center.x);
    float radius = length(center);
    
    // Infinite tunnel effect
    angle += u_time * 0.5;
    radius = mod(radius + u_time * 0.3, 1.0);
    
    float2 tunnelUV = float2(radius * cos(angle), radius * sin(angle)) + 0.5;
    float3 cam = u_camera.sample(s, tunnelUV).rgb;
    
    // Rainbow rings EVERYWHERE
    float rings = sin(radius * 30.0 - u_time * 5.0);
    cam += float3(
        sin(rings + 0.0) * 0.5,
        sin(rings + 2.0) * 0.5,
        sin(rings + 4.0) * 0.5
    );
    
    // Spiral arms
    float spiral = sin(angle * 5.0 + radius * 10.0 - u_time * 2.0);
    cam += spiral * 0.3;
    
    return float4(cam, 1.0);
}
"""

// Effect 4: LIQUID REALITY
let liquidRealityShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.texCoord;
    
    // Liquid distortion EVERYWHERE
    float2 warp = float2(
        sin(uv.y * 10.0 + u_time * 2.0) * 0.1,
        cos(uv.x * 10.0 - u_time * 2.0) * 0.1
    );
    
    float3 cam = u_camera.sample(s, uv + warp).rgb;
    
    // Flowing colors
    float flow = sin(uv.x * 5.0 + u_time) * cos(uv.y * 5.0 + u_time * 1.3);
    cam += flow * 0.4;
    
    // Dripping effect
    float drip = step(0.5, sin(uv.x * 20.0 + uv.y * 30.0 - u_time * 3.0));
    cam *= 1.0 + drip * 0.3;
    
    return float4(cam, 1.0);
}
"""

// Effect 5: KALEIDOSCOPE INFINITY
let kaleidoscopeShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.texCoord;
    float2 center = uv - 0.5;
    
    float angle = atan2(center.y, center.x);
    float radius = length(center);
    
    // 12-fold kaleidoscope
    float sections = 12.0;
    angle = mod(angle + u_time * 0.5, 6.28 / sections) * sections;
    
    // Mirror multiple times
    float2 kaleido = float2(radius * cos(angle), radius * sin(angle)) + 0.5;
    
    float3 cam = u_camera.sample(s, kaleido).rgb;
    
    // Add infinite reflections
    for(int i = 1; i < 4; i++) {
        float fi = float(i);
        float2 reflected = float2(
            radius * cos(angle * fi + u_time),
            radius * sin(angle * fi + u_time)
        ) + 0.5;
        cam += u_camera.sample(s, reflected).rgb * (0.3 / fi);
    }
    
    // Chromatic rings
    float rings = sin(radius * 25.0 - u_time * 4.0);
    cam += rings * 0.3;
    
    return float4(cam * 0.7, 1.0);
}
"""

// Effect 6: BREATHING COSMOS
let breathingCosmosShader = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexPass(uint vid [[vertex_id]]) {
    float2 positions[4] = {float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0)};
    float2 texCoords[4] = {float2(0.0, 0.0), float2(1.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0)};
    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 fragmentPass(
    VertexOut in [[stage_in]],
    texture2d<float, access::sample> u_camera [[texture(0)]],
    constant float &u_time [[buffer(0)]]
) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float2 uv = in.texCoord;
    float2 center = uv - 0.5;
    
    // Breathing expansion/contraction
    float breathe = 1.0 + 0.3 * sin(u_time * 0.7);
    float2 breathed = center * breathe + 0.5;
    
    float3 cam = u_camera.sample(s, breathed).rgb;
    
    // Stars/particles everywhere
    float stars = step(0.98, sin(uv.x * 100.0 + u_time) * cos(uv.y * 100.0 - u_time));
    cam += stars * float3(1.0, 0.9, 1.2);
    
    // Cosmic waves
    float waves = sin(length(center) * 15.0 - u_time * 3.0);
    cam += waves * 0.2;
    
    // Color shift
    cam *= float3(
        1.0 + 0.3 * sin(u_time * 0.5),
        1.0 + 0.3 * sin(u_time * 0.6 + 2.0),
        1.0 + 0.3 * sin(u_time * 0.7 + 4.0)
    );
    
    return float4(cam, 1.0);
}
"""
