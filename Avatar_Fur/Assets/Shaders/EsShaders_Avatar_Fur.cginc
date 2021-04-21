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
};
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
half4 _UvOffset;


v2f vert_fur (appdata v)
{
    #ifndef FURSTEP
        #define FURSTEP 0
    #endif
    v2f o;
    v.vertex.xyz += normalize(v.normal) * FURSTEP*_FurLength;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);

    o.noise_uv.xy = TRANSFORM_TEX(v.uv, _NoiseTex);
    o.noise_uv.zw = TRANSFORM_TEX(v.uv, _SecondNoiseTex);
    half2 uvOffset = 0;

    uvOffset = FURSTEP*_FurLength*_UvOffset.xy*0.1;
    o.noise_uv.xy += uvOffset;
    uvOffset = FURSTEP*_FurLength*_UvOffset.zw*0.1;
    o.noise_uv.zw += uvOffset;

    fixed Occlusion = saturate(pow(FURSTEP*_FurRadius,_OcclusionPower) * 2.5);//FURSTEP不大于1
    // fixed Occlusion = saturate(pow(FURSTEP/0.6,_OcclusionPower));
    fixed3 furColor = lerp(_OcclusionColor,_FurColor, Occlusion);
    o.lightMul.rgb = furColor;

    return o;
}
fixed4 frag_fur (v2f i) : SV_Target
{
    // sample the texture
    fixed3 col = tex2D(_MainTex, i.uv).rgb;
    fixed3 noiseTex = tex2D(_NoiseTex, i.noise_uv.xy);
    fixed noiseAlpha =  noiseTex.r;
#ifdef ENABLE_SECOND_NOISE_TEX
    noiseTex = tex2D(_NoiseTex, i.noise_uv.zw);
    noiseAlpha += noiseTex.r;
    noiseAlpha *= 0.5;
#endif

    fixed furAlpha = saturate(noiseAlpha-FURSTEP*_FurRadius);
    // return noiseAlpha;
    col *= i.lightMul;
    return fixed4(col, furAlpha);
}