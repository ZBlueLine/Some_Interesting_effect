
sampler2D _MainTex;
half4 _MainTex_ST;

sampler2D _NoiseTex;
half4 _NoiseTex_ST;

sampler2D _SecondNoiseTex;
half4 _SecondNoiseTex_ST;

fixed4 _FurColor;
half _FurLength;
half _FurRadius;

fixed4 _OcclusionColor;
half _OcclusionPower;
half4 _UVOffset;

half _FresnelPow;
half _FresnelScale;

struct appdata
{
    half4 vertex : POSITION;
    half3 normal : NORMAL;
    half2 uv : TEXCOORD0;
};
struct v2f
{
    half4 vertex : SV_POSITION;
    half2 uv : TEXCOORD0;
    half4 noise_uv : TEXCOORD1;
    half4 lightMul : TEXCOORD2;
    half4 lightAdd : TEXCOORD3;
    half3 worldNormal : TEXCOORD4;  
    half3 worldPos : TEXCOORD5;
    half3 sh : TEXCOORD6;
};

v2f vert_fur (appdata v)
{
    #ifndef FURSTEP
        #define FURSTEP 0
    #endif
    v2f o;
    // half furStep = sqrt(FURSTEP * _FurLength*0.1);
    half furStep = FURSTEP * _FurLength;

    v.vertex.xyz += normalize(v.normal) * furStep;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

    o.noise_uv.xy = TRANSFORM_TEX(v.uv, _NoiseTex);
    o.noise_uv.zw = TRANSFORM_TEX(v.uv, _SecondNoiseTex);
    half2 uvOffset = 0;

    uvOffset = furStep*_UVOffset.xy*0.1;
    o.noise_uv.xy += uvOffset;
    uvOffset = furStep*_UVOffset.zw*0.1;
    o.noise_uv.zw += uvOffset;

    float3 normal = normalize(mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz);
    o.sh = saturate(normal.y *0.25+0.55);

    fixed3 atten = UNITY_LIGHTMODEL_AMBIENT.xyz;
    o.lightAdd.rgb = atten;
    return o;
}
fixed4 frag_fur (v2f i) : SV_Target
{
    half furStep = FURSTEP * _FurLength;
    half3 worldNormal = normalize(i.worldNormal);
    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
    
    half occlusion = saturate(pow(FURSTEP,_OcclusionPower) * 2.5);
    half3 shlight = lerp (_OcclusionColor*i.sh,i.sh,occlusion);
    occlusion +=0.04 ;

    half fresnel = 1-max(0,dot(worldNormal, viewDir));//pow (1-max(0,dot(N,V)),2.2);
    fresnel = pow(fresnel, _FresnelPow) * _FresnelScale + (1 - _FresnelScale);
    half rimLight =fresnel * occlusion; //AO的深度剔除 很重要
    shlight += rimLight;

    fixed3 col = _FurColor.rgb;
    fixed3 noiseTex = tex2D(_NoiseTex, i.noise_uv.xy);
    fixed noiseAlpha =  noiseTex.r;
    //拟合毛发形状
    fixed furAlpha = saturate(noiseAlpha*2-(furStep * furStep + (furStep * _FurRadius)));

#ifdef ENABLE_SECOND_NOISE_TEX
    noiseTex = tex2D(_SecondNoiseTex, i.noise_uv.zw);
    noiseAlpha =  noiseTex.r;
    furAlpha += saturate(noiseAlpha-(furStep * furStep + (furStep * _FurRadius)));
    furAlpha *= 0.5;
    // dither *= 2;
    // furAlpha *= saturate(lerp(1, dither, furStep*10));
#endif
    
    if(furStep - 0.0 < 1e-3)
        furAlpha = 1;
    col.rgb *= shlight;
    // col.rgb += i.lightAdd;
    return fixed4(col, furAlpha);
}