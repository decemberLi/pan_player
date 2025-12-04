//
//  Shaders.metal
#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float4 pos [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
};

vertex VertexOut mapTexture(VertexIn input [[stage_in]]) {
    VertexOut outVertex;
    outVertex.renderedCoordinate = input.pos;
    outVertex.textureCoordinate = input.uv;
    return outVertex;
}

vertex VertexOut mapSphereTexture(VertexIn input [[stage_in]], constant float4x4& uniforms [[ buffer(2) ]]) {
    VertexOut outVertex;
    outVertex.renderedCoordinate = uniforms * input.pos;
    outVertex.textureCoordinate = input.uv;
    return outVertex;
}

fragment half4 displayTexture(VertexOut mappingVertex [[ stage_in ]],
                              texture2d<half, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    return half4(texture.sample(s, mappingVertex.textureCoordinate));
}

fragment half4 displayYUVTexture(VertexOut in [[ stage_in ]],
                                  texture2d<half> yTexture [[ texture(0) ]],
                                  texture2d<half> uTexture [[ texture(1) ]],
                                  texture2d<half> vTexture [[ texture(2) ]],
                                  sampler textureSampler [[ sampler(0) ]],
                                  constant float3x3& yuvToBGRMatrix [[ buffer(0) ]],
                                  constant float3& colorOffset [[ buffer(1) ]],
                                  constant uchar3& leftShift [[ buffer(2) ]])
{
    half3 yuv;
    yuv.x = yTexture.sample(textureSampler, in.textureCoordinate).r;
    yuv.y = uTexture.sample(textureSampler, in.textureCoordinate).r;
    yuv.z = vTexture.sample(textureSampler, in.textureCoordinate).r;
    return half4(half3x3(yuvToBGRMatrix)*(yuv*half3(leftShift)+half3(colorOffset)), 1);
}


fragment half4 displayNV12Texture(VertexOut in [[ stage_in ]],
                                  texture2d<half> lumaTexture [[ texture(0) ]],
                                  texture2d<half> chromaTexture [[ texture(1) ]],
                                  sampler textureSampler [[ sampler(0) ]],
                                  constant float3x3& yuvToBGRMatrix [[ buffer(0) ]],
                                  constant float3& colorOffset [[ buffer(1) ]],
                                  constant uchar3& leftShift [[ buffer(2) ]])
{
    half3 yuv;
    yuv.x = lumaTexture.sample(textureSampler, in.textureCoordinate).r;
    yuv.yz = chromaTexture.sample(textureSampler, in.textureCoordinate).rg;
    return half4(half3x3(yuvToBGRMatrix)*(yuv*half3(leftShift)+half3(colorOffset)), 1);
}

half3 shaderLinearize(half3 rgb) {
    rgb = pow(max(rgb,0), half3(4096.0/(2523 * 128)));
    rgb = max(rgb - half3(3424./4096), 0.0) / (half3(2413./4096 * 32) - half3(2392./4096 * 32) * rgb);
    rgb = pow(rgb, half3(4096.0 * 4 / 2610));
    return rgb;
}

half3 shaderDeLinearize(half3 rgb) {
    rgb = pow(max(rgb,0), half3(2610./4096 / 4));
    rgb = (half3(3424./4096) - half3(2413./4096 * 32) * rgb) / (half3(1.0) + half3(2392./4096 * 32) * rgb);
    rgb = pow(rgb, half3(2523./4096 * 128));
    return rgb;
}

fragment half4 displayYCCTexture(VertexOut in [[ stage_in ]],
                                  texture2d<half> lumaTexture [[ texture(0) ]],
                                  texture2d<half> chromaTexture [[ texture(1) ]],
                                  sampler textureSampler [[ sampler(0) ]],
                                  constant float3x3& yuvToBGRMatrix [[ buffer(0) ]],
                                  constant float3& colorOffset [[ buffer(1) ]],
                                  constant uchar3& leftShift [[ buffer(2) ]])
{
    half3 ipt;
    ipt.x = lumaTexture.sample(textureSampler, in.textureCoordinate).r;
    ipt.yz = chromaTexture.sample(textureSampler, in.textureCoordinate).rg;
//    half3x3 ipt2lms = half3x3{{1, 0.1952, 0.4104}, {1, -0.2278, 0.2264}, {1, 0.0652, -1.3538}};
//    half3x3 lms2rgb = half3x3{{3.238998, -0.719461, -0.002862}, {-2.272734, 1.874998, -0.268066}, {0.086733, -0.158947, 1.074494}};
    half3x3 ipt2lms = half3x3{{1, 799/8192, 1681/8192}, {1, -933/8192, 1091/8192}, {1, 267/8192, -5545/8192}};
    half3x3 lms2rgb = half3x3{{3.43661, -0.79133, -0.0259499}, {-2.50645, 1.98360, -0.0989137}, {0.06984, -0.192271, 1.12486}};
    half3 lms = ipt2lms*ipt;
    lms = shaderLinearize(lms);
    half3 rgb = lms2rgb*lms;
    rgb = shaderDeLinearize(rgb);
    return half4(rgb, 1);
}

kernel void yuv420ToRGB(texture2d<float, access::read> y_inTexture [[ texture(0) ]],
                        texture2d<float, access::read> uv_inTexture [[ texture(1) ]],
                        constant uint2 &byteSize [[ buffer(2) ]],
                        texture2d<float, access::write> outTexture [[ texture(3) ]],
                        uint2 gid [[ thread_position_in_grid ]]) {
    /// 超出实际纹理宽高的网格不计算,直接返回
    if(gid.x > byteSize.x || gid.y > byteSize.y) return;
//    if(gid.x % 2 == 0 || gid.y % 2 == 0 || gid.x % 3 == 0 || gid.y % 3 == 0) {
//        outTexture.write(float4(0, 0, 0, 1.0), gid);
//        return;
//    }
    /// 获取y分量数据,由于在创建MetalTexture的时候在方法CVMetalTextureCacheCreateTextureFromImage
    /// 中指定了归一化的格式,所以这里得到的y值范围是[0, 1]
    float4 yFloat4 = y_inTexture.read(gid);

    /// Y与UV在YUV420P格式下的比例是4:1
    /// YUV420P垂直与水平分别是2:1的比例
    /// gid是包含X，Y坐标,所以这里gid/2实际上是缩小了4倍，符合YUV420P中Y与UV的比例
    /// 每4个Y共享一组UV
    float4 uvFloat4 = uv_inTexture.read(gid/2);
    float y = yFloat4.x;
    float cb = uvFloat4.x;
    float cr = uvFloat4.y;
    
    /// 按YCbCr转RGB的公式进行数据转换
    float r = y + 1.403 * (cr - 0.5);
    float g = y - 0.343 * (cb - 0.5) - 0.714 * (cr - 0.5);
    float b = y + 1.770 * (cb - 0.5);
    
    /// 限制颜色值在有效范围内
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    
    /// 增强颜色饱和度（使颜色更鲜艳）
    float gray = 0.299 * r + 0.587 * g + 0.114 * b;  // 计算灰度值
    float saturation = 1.0;  // 饱和度增强系数
    r = gray + (r - gray) * saturation;
    g = gray + (g - gray) * saturation;
    b = gray + (b - gray) * saturation;
    
    /// 增强对比度（使明暗对比更明显）
    float contrast = 1.3;  // 对比度增强系数
    r = ((r - 0.5) * contrast) + 0.5;
    g = ((g - 0.5) * contrast) + 0.5;
    b = ((b - 0.5) * contrast) + 0.5;
    
    /// 再次限制颜色值
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    
    outTexture.write(float4(r, g, b, 1.0), gid);
        
}

kernel void yuv420PToRGB(texture2d<float, access::read> y_inTexture [[ texture(0) ]],
                         texture2d<float, access::read> u_inTexture [[ texture(1) ]],
                         texture2d<float, access::read> v_inTexture [[ texture(2) ]],
                         constant uint2 &byteSize [[ buffer(2) ]],
                         texture2d<float, access::write> outTexture [[ texture(3) ]],
                         uint2 gid [[ thread_position_in_grid ]]) {
    if(gid.x > byteSize.x || gid.y > byteSize.y) return;

    float y = y_inTexture.read(gid).x;
    float u = u_inTexture.read(gid/2).x;
    float v = v_inTexture.read(gid/2).x;

    float r = y + 1.403 * (v - 0.5);
    float g = y - 0.343 * (u - 0.5) - 0.714 * (v - 0.5);
    float b = y + 1.770 * (u - 0.5);
    
    /// 限制颜色值在有效范围内
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    
    /// 增强颜色饱和度（使颜色更鲜艳）
    float gray = 0.299 * r + 0.587 * g + 0.114 * b;  // 计算灰度值
    float saturation = 1.0;  // 饱和度增强系数
    r = gray + (r - gray) * saturation;
    g = gray + (g - gray) * saturation;
    b = gray + (b - gray) * saturation;
    
    /// 增强对比度（使明暗对比更明显）
    float contrast = 1.3;  // 对比度增强系数
    r = ((r - 0.5) * contrast) + 0.5;
    g = ((g - 0.5) * contrast) + 0.5;
    b = ((b - 0.5) * contrast) + 0.5;
    
    /// 再次限制颜色值
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    
    outTexture.write(float4(r, g, b, 1.0), gid);
}