#include "Lighting.cginc"
sampler2D _MainTex;
half4 _MainTex_ST;

sampler2D _NoiseTex;
half4 _NoiseTex_ST;

// sampler2D _TangentOffsetTex;

sampler2D _SecondNoiseTex;
half4 _SecondNoiseTex_ST;

fixed4 _FurColor;
half _FurLength;
half _FurRadius;
half _FurDirLightExposure;

fixed4 _OcclusionColor;
half _OcclusionPower;
half _OcclusionRange;
half4 _UVOffset;
half _UVOffsetAtten;

fixed4 _FresnalColor;
half _FresnalBias;
half _FresnalPower;
half _FresnalScale;

half _LightFilter;

fixed4 _SpecColor1;
fixed4 _SpecColor2;

half _Spec1Power;
half _Spec1Offset;
half _Spec2Power;
half _Spec2Offset;

half _AnisotropicScale;

struct appdata
{
    half4 vertex : POSITION;
    half3 normal : NORMAL;
    half2 uv : TEXCOORD0;
    half4 tangent : TANGENT;
};
struct v2f
{
    half4 vertex : SV_POSITION;
    half2 uv : TEXCOORD0;
    half4 noise_uv : TEXCOORD1;
    half3 lightMul : TEXCOORD2;
    half4 lightAdd : TEXCOORD3;
};

half StrandSpecular(half3 tangent, half3 worldViewDir, half3 lightDir, half exponent)
{
    half3 halfDir = normalize(lightDir + worldViewDir);
    float hDott = dot(halfDir, tangent);
    float sinTH = sqrt(1-hDott*hDott);
    float cosTH = cos(hDott);
    float dirAtten = smoothstep(-1,0,hDott);
    float specular = dirAtten*pow(cosTH, exponent);
    return specular;
}
float3 ShiftTangent(float3 tangent, float3 normal, float shift)
{
    return tangent + normal*shift;
}

v2f vert_fur (appdata v)
{
    #ifndef FURSTEP
        #define FURSTEP 0
    #endif
    v2f o;
    half furStep = FURSTEP * _FurLength;
    v.vertex.xyz += normalize(v.normal) * furStep;
    o.vertex = UnityObjectToClipPos(v.vertex);
    half3 worldNormal = UnityObjectToWorldNormal(v.normal); 
    half3 worldPos = mul(unity_ObjectToWorld, v.vertex);
    half3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
    half3 normal = normalize(mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz);
    half3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
    half3 worldTangent = normalize(mul(unity_ObjectToWorld,v.tangent.xyz).xyz);
    half3 worldBitangent = normalize(cross(worldTangent, worldNormal));

    
    //AO
    half occlusion = saturate(pow(FURSTEP*_OcclusionRange,_OcclusionPower));
    occlusion +=0.04;
    half3 aoColor = lerp (_OcclusionColor,1, occlusion) ;
    //fresnal
    half fresnal = saturate(min(1, _FresnalBias + _FresnalScale*pow(1-dot(worldViewDir,worldNormal),_FresnalPower)));
    fresnal =fresnal * occlusion; 

    o.lightMul = aoColor;
    o.lightAdd.a = fresnal;

    //Dir Light
    half3 diff = max(0, dot(worldNormal, worldLightDir));
    diff = saturate(diff + _LightFilter + FURSTEP);
    diff *= _FurDirLightExposure*_LightColor0.rgb;
    o.lightMul.rgb *= diff;

    //Anisotropic Specular
    float3 shiftTangent1 = ShiftTangent(worldBitangent,worldNormal,_Spec1Offset*0.1);
    float3 shiftTangent2 = ShiftTangent(worldBitangent,worldNormal,_Spec2Offset*0.1);

    float anisoSpec1 = StrandSpecular(shiftTangent1,worldViewDir,worldLightDir,_Spec1Power*16) * _AnisotropicScale * FURSTEP* 2;
    float anisoSpec2 = StrandSpecular(shiftTangent2,worldViewDir,worldLightDir,_Spec2Power*16) * _AnisotropicScale * FURSTEP* 2;
    o.lightAdd.rgb = _SpecColor1.rgb*anisoSpec1+_SpecColor2.rgb*anisoSpec2;

    //Fur Noise
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.noise_uv.xy = TRANSFORM_TEX(v.uv, _NoiseTex);
    o.noise_uv.zw = TRANSFORM_TEX(v.uv, _SecondNoiseTex);
    half2 uvOffset = 0;

    uvOffset = furStep*_UVOffset.xy*0.1;
    o.noise_uv.xy += uvOffset;
    uvOffset = furStep*_UVOffset.zw*0.1;
    o.noise_uv.zw += uvOffset;
    return o;
}
fixed4 frag_fur (v2f i) : SV_Target
{
    // return i.lightAdd.a;
    half furStep = FURSTEP * _FurLength;
    fixed3 col = _FurColor.rgb;
    fixed3 noiseTex = tex2D(_NoiseTex, i.noise_uv.xy);
    fixed noiseAlpha =  noiseTex.r;
    //拟合毛发形状
    fixed furAlpha = saturate(noiseAlpha*2-(furStep * furStep + (furStep * _FurRadius)));

#ifdef ENABLE_SECOND_NOISE_TEX
    noiseTex = tex2D(_SecondNoiseTex, i.noise_uv.zw);
    noiseAlpha =  noiseTex.r;
    furAlpha += saturate(noiseAlpha*2-(furStep * furStep + (furStep * _FurRadius)));
    furAlpha *= 0.5;
#endif
    
    if(furStep - 0.0 < 1e-3)
        furAlpha = 1;
    col.rgb = col*i.lightMul;
    col.rgb += i.lightAdd.a * _FresnalColor + i.lightAdd.rgb*furAlpha*2;

    return fixed4(col.rgb, furAlpha);
}