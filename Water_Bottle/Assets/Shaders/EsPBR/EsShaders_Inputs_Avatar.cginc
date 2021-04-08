struct appdata
{
	fixed4 color : COLOR;
	float4 vertex : POSITION;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 texcoord : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
};


struct v2fBase_Avatar
{
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float4 texcoord : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
	float4 ambientOrLightmapUV : TEXCOORD5;
	float4 screenPos : TEXCOORD6;
	UNITY_LIGHTING_COORDS(7, 8)
#if _REFLECTION_MATCAP
	float2 NtoV : TEXCOORD9;
#endif
};


struct v2fAdd_Avatar
{
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float4 texcoord : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
	float4 screenPos : TEXCOORD5;
	UNITY_LIGHTING_COORDS(6, 7)
};


fixed4 _Color;
fixed4 _EmissionColor;

fixed _Cutoff;
sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainWorldUVTilling;
sampler2D _PBRMap;
sampler2D _BumpMap;
sampler2D _Matcap_Reflection;

float _BumpScale;
float _Smoothness;
float _Occlusion;
float _Metallic;



sampler2D _SkinBRDFLut; 
sampler2D _SkinSSSTex;	//R:thickness G:curvature
half _SkinCurvatureScale;
half _SkinThicknessScale;
half3 _SkinSubColor;
half  _SkinPower;
half  _SkinDistortion;

