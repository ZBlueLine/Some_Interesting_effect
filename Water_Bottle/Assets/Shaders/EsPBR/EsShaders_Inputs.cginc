#ifndef ESSHADERS_PBRINPUTS_INCLUDED
#define ESSHADERS_PBRINPUTS_INCLUDED

struct appdata
{
	fixed4 color : COLOR;
	float4 vertex : POSITION;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 texcoord : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1;
};

struct v2fBase
{
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float4 texcoord : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
#endif
	float4 ambientOrLightmapUV : TEXCOORD5;
	float4 screenPos : TEXCOORD6;
	UNITY_LIGHTING_COORDS(7, 8)
#if _DETAIL_ENABLE
		float4 texcoord1 : TEXCOORD9;
#endif
	UNITY_FOG_COORDS(11)
};

struct v2fAdd
{
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float4 texcoord : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
#endif
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
//sampler2D _Matcap_Reflection;
//sampler2D _Global_Matcap_Reflection;

float _BumpScale;
float _Smoothness;
float _Anisotropy;

int _FabricType;

float _Occlusion;
float _Metallic;

int _HintHighlightOn;
float _HintHighlightSpeed;
float _HintHighlightIdensity;
fixed4 _HintHighlighColor;

//-------Detail Info----------
//sampler2D _DetailNormalMap;
//float4 _DetailNormalMap_ST;
//sampler2D _DetailAlbedo;
//float4 _DetailAddColor;
//float4 _DetailAlbedo_ST;
//float _DetailNormalScale;
//float4 _DAWorldUVTilling;


#endif