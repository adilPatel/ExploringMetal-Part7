//
//  Shaders.metal
//  ExploringMetal
//
//  Created by Adil Patel on 31/05/2018.
//  Copyright © 2018 Adil Patel. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// The uniforms... you can see a correspondence with the host side
typedef struct {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
} Uniforms;

// The layout in the vertex array
typedef struct {
    packed_float3 position;
    packed_float3 normal;
    packed_float2 texCoord;
} Vertex;

// The output of the vertex shader, which will be fed into the fragment shader
typedef struct {
    float4 position [[position]];
    half4 worldSpaceCoordinate;
    half4 normal;
    float2 texCoord;
} RasteriserData;

// Light and material data
constant half lightPower = 50.0h;
constant half shininess  = 50.0h;
constant half4 lightColour = half4(1.0h, 1.0h, 1.0h, 1.0h);
constant half4 ambientColour  = half4(0.1h, 0.0h, 0.0h, 1.0h);
constant half4 specularColour = half4(1.0h, 1.0h, 1.0h, 1.0h);
constant half3 lightPos  = half3(4.0h, 4.0h, 0.0h);

vertex RasteriserData helloVertexShader(uint vertexID [[vertex_id]],
                                        const device Vertex *vertices [[buffer(0)]],
                                        constant Uniforms &uniforms [[buffer(1)]]) {
    
    
    half3 position = half3(vertices[vertexID].position);
    half3 normal = half3(vertices[vertexID].normal);
    
    half4 transformedPos = half4(position, 1.0h);
    transformedPos = half4x4(uniforms.modelViewMatrix) * transformedPos;
    
    RasteriserData out;
    half4 projected = half4x4(uniforms.projectionMatrix) * transformedPos;
    normal = half3x3(uniforms.normalMatrix) * normal;
    
    out.position = float4(projected); // Conversions from halfs to floats are free! :D
    out.normal = half4(normal, 0.0h);
    out.worldSpaceCoordinate = transformedPos;
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

fragment half4 helloFragmentShader(RasteriserData in [[stage_in]],
                                   texture2d<float, access::sample> tex2d [[texture(0)]],
                                   sampler sampler2d [[sampler(0)]]) {
    
    // To start with, we need the light vector
    half3 pos = half3(in.worldSpaceCoordinate);
    half3 lightVec = lightPos - pos;
    half lightLength = length_squared(lightVec);
    lightVec = normalize(lightVec);
    
    half3 normal = normalize(half3(in.normal));
    
    half4 surfaceColour = half4(tex2d.sample(sampler2d, in.texCoord));
    
    // Now we calculate the Lambertian (diffuse) component
    half4 diffuse = saturate(dot(normal, lightVec)) * surfaceColour;
    
    // Then the specular component
    half3 viewVec = normalize(-pos);
    half3 halfVec = normalize(lightVec + viewVec);
    
    half specCosine = saturate(dot(halfVec, normal));
    half4 specular = pow(specCosine, shininess) * specularColour;
    
    half4 brightness = lightPower * (1.0h / lightLength) * lightColour;
    
    return ambientColour + (diffuse + specular) * brightness;
}
