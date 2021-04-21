
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

half _FresnalBias;
half _FresnalPower;
half _FresnalScale;

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
    half sh : TEXCOORD6;
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
    o.sh = saturate(normal.y *0.25+0.45);

    fixed3 atten = UNITY_LIGHTMODEL_AMBIENT.xyz;
    o.lightAdd.rgb = atten;
    return o;
}
fixed4 frag_fur (v2f i) : SV_Target
{
    half furStep = FURSTEP * _FurLength;
    half3 worldNormal = normalize(i.worldNormal);
    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
    
    half occlusion = saturate(pow(FURSTEP,_OcclusionPower));

    //环境光
    half3 shlight = lerp (_OcclusionColor*i.sh,i.sh,occlusion);

    occlusion +=0.04 ;
    half fresnal = saturate(min(1, _FresnalBias + _FresnalScale*pow(1-dot(viewDir,worldNormal),_FresnalPower)));
    half rimLight =fresnal * occlusion; //AO
    rimLight *= i.sh;//成环境因子
    shlight += rimLight;

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
    col.rgb *= shlight;
    // col.rgb = i.sh;
    return fixed4(shlight, furAlpha);
}