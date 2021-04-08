#ifndef ESSHADERS_INPUTS_ACTOR_INCLUDED
#define ESSHADERS_INPUTS_ACTOR_INCLUDED

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
#if defined(_NORMALMAP)
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
#endif
	float4 ambientOrLightmapUV : TEXCOORD5;
	//float4 screenPos : TEXCOORD6;
	UNITY_LIGHTING_COORDS(6, 7)
#if _REFLECTION_MATCAP
	float2 NtoV : TEXCOORD8;
#endif
	UNITY_FOG_COORDS(9)
};

struct v2fAdd
{
	float4 pos : SV_POSITION;
	fixed4 color : COLOR;
	float4 texcoord : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 worldNormal : TEXCOORD2;
#if defined(_NORMALMAP) 
	float3 worldTangent : TEXCOORD3;
	float3 worldBinormal :TEXCOORD4;
#endif
	UNITY_LIGHTING_COORDS(5, 6)
};



fixed4 _Color;
fixed4 _EmissionColor;

fixed _Cutoff;
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _PBRMap;
sampler2D _BumpMap;

float _BumpScale;
float _Smoothness;

float _Occlusion;
float _Metallic;

fixed _GIFade;


int _HintHighlightOn;
float _HintHighlightSpeed;
float _HintHighlightIdensity;
fixed4 _HintHighlighColor;

float4 _SideRimColor;
float _SideRimScale;
float _SideRimPower;
float4 _SideRimDir;


float4 _RimBounceInfo;
float4 _RimColor;
float _RimScale;
float _RimPower;
float _RimBlend;

#endif