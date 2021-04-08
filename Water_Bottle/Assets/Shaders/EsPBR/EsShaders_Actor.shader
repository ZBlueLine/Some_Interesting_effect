// General PBR Actor Shader. Copyright (c) Electronic Soul Dianhun. 
// Authored By Jiang Guanmian From Tech & Art Research Dep.

Shader "EsShaders/Actor"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}
		[NoScaleOffset]_PBRMap("PBRMap[R-Metallic, G-Smoothness, B-Emission, A-AO]", 2D) = "white" {}
		[NoScaleOffset]_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("NormalScale", Range(-5 , 5)) = 1
		_Smoothness("Smoothness", Range(0, 1)) = 1
		_GIFade("GI Fade", Range(0, 1)) = 1

					   
		_Occlusion("Occlusion", Range(0, 1)) = 1
		_Metallic("Metallic", Range(0, 1)) = 1
		//_RealtimeShadowColor("Realtime Shadow Color",Color) = (0,0,0,1)

		/*_FabricType("Fabric Type", Int) = 0
		_FabricMap("Fabric Map", 2D) = "white" {}
		[HDR]_FuzzColor("Fuzz Color", Color) = (1,1,1,1)*/

		[NoScaleOffset]_ThicknessMap("Thickness", 2D) = "white" {}
		_TransculancyDistortion("Transculancy Distortion", Range(-1, 1)) = 1
		_TransculancyPower("Transculancy Power", Range(0.001, 40)) = 1
		_TransculancyGIScale("Transculancy Power", Range(0, 4)) = 1
		[HDR]_TransculancyColor("Transculancy Color", Color) = (0,0,0,0)


		[HDR]_EmissionColor("Emmision Color",Color) = (0,0,0,0)
		[HDR]_HintHighlighColor("Hint Highlight Color",Color) = (1,1,0,0)
		_HintHighlightOn("Hint Highlight On", int) = 0
		_HintHighlightSpeed("Hint Highlight Speed", Float) = 0
		_HintHighlightIdensity("Hint Highlight Idensity", Float) = 1

		/*_SideRimDir("Side Rim Dir", Vector) = (1,1,1,0)
		_SideRimPower("Side Rim Power", Range(1 , 10)) = 5
		[HDR]_SideRimColor("Side Rim Color", Color) = (1,1,1,1)*/

		_RimScale("Rim Scale", Float) = 1
		_RimPower("Rim Power", Range(1 , 10)) = 5
		_RimBlend("Rim Blend", Range(0 , 1)) = 1
		[HDR]_RimColor("Rim Color", color) = (1,1,1,1)
		//_RimBounceInfo("Rim Bounce Info", Vector) = (1,1,1,0)
		//_RimBounceColor("Rim Bounce Color", Color) = (1,1,1,0)

		//_OutlineWidth("Outlie Width", Float) = 1
		//_OutlineScale("Outlie Scale", Float) = 1
		//_OutlinePower("Outlie Power", Float) = 1
		//[HDR]_OutlineColor("Outline Color", Color) = (1,1,1,0)
		//[HideInInspector] _ColorMaskForOutline("Color Mask For Outline", Float) = 0

		/*_LightFlowTex("LightFlow Texture", 2D) = "white" {}
		_LightFlowAngle("LightFlow Width", Float) = 1
		_LightFlowWidth("LightFlow Scale", Float) = 1
		_LightFlowLoopTime("LightFlow Power", Float) = 1
		_LightFlowInterval("LightFlow Power", Float) = 1
		_LightFlowMode("LightFlow Mode", Float) = 1
		[HDR]_LightFlowColor("LightFlow Color", Color) = (1,1,1,1)*/

		[HideInInspector] _ReflectionMode("_reflection_mode", Float) = 0.0
		//[HideInInspector] _LightOverride("__lightOverride", Float) = 0.0

		[NoScaleOffset]_Matcap_Reflection("Matcap Texture", 2D) = "white"{}
		_ReflectionColor("Reflection Color", Color) = (0,0,0,1)

		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
		[HideInInspector] _ZTest("__zt", Float) = 4
		[HideInInspector] _Cull("__cull", Float) = 2
	}

    SubShader
    {
		//LOD 300

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD"
			Tags
			{
				"LightMode" = "ForwardBase"
			}

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]
			ZTest[_ZTest]
			Cull[_Cull]

			CGPROGRAM
			#pragma vertex vertBase
			#pragma fragment fragBase
			#pragma multi_compile_fwdbase
			#pragma target 3.0
			#pragma multi_compile_fog
			#pragma shader_feature_local _DEFAULT_PROBE_REFLECTION 

			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _PBRMAP
			#pragma shader_feature_local _RIM_HIGHLIGHT_ON

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsShaders_Inputs_Actor.cginc"
			#include "EsShaders_BRDF_Actor.cginc"

			#pragma skip_variants POINT POINT_COOKIE SHADOWS_CUBE VERTEXLIGHT_ON  

			#include "EsShaders_FowardLighting_Actor.cginc"
			ENDCG
		}

		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend[_SrcBlend] One
			Fog { Color(0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma vertex vertAdd
			#pragma fragment fragAdd
			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows

			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _PBRMAP
			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

		
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsShaders_Inputs_Actor.cginc"
			#include "EsShaders_BRDF_Actor.cginc"

			#pragma skip_variants POINT_COOKIE SHADOWS_CUBE VERTEXLIGHT_ON _RIM_HIGHLIGHT_ON

			#include "EsShaders_FowardLighting_Actor.cginc"
			ENDCG
		}

		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			// -------------------------------------

			#pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster
			// Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
			//#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma skip_variants POINT_COOKIE SHADOWS_CUBE VERTEXLIGHT_ON  _RIM_HIGHLIGHT_ON

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "EsShaders_Shadow.cginc"

			ENDCG
		}
	}

	CustomEditor "EsShaders_Actor_GUI"
}
