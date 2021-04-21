
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
    half3 lightMul : TEXCOORD2;
    half3 lightAdd : TEXCOORD3;
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

    half3 worldNormal = UnityObjectToWorldNormal(v.normal);
    half3 worldPos = mul(unity_ObjectToWorld, v.vertex);
    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
    half3 normal = normalize(mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz);
    half sh = saturate(normal.y *0.25+0.45);

    half occlusion = saturate(pow(FURSTEP,_OcclusionPower));
    occlusion +=0.04 ;
    
    //计算AO
    half3 shlight = lerp (_OcclusionColor*sh,sh, occlusion) ;
    half fresnal = saturate(min(1, _FresnalBias + _FresnalScale*pow(1-dot(viewDir,worldNormal),_FresnalPower)));
    half rimLight =fresnal * occlusion; //AO
    rimLight *= sh;//成环境因子
    shlight += rimLight;

    o.lightMul = shlight;

    fixed3 atten = UNITY_LIGHTMODEL_AMBIENT.xyz;
    //环境光
    o.lightAdd.rgb = atten;

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
    col.rgb *= i.lightMul;
    // col.rgb = i.sh;
    return fixed4(col.rgb, furAlpha);
}