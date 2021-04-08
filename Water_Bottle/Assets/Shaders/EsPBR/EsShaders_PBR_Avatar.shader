// General PBR Avatar Shader. Copyright (c) Electronic Soul Dianhun. 
// Authored By Jiang Guanmian From Tech & Art Research Dep.

Shader "EsShaders/PBR Avatar"
{
	Properties
	{
		[HideInInspector] _BRDFType("__brdftype", Float) = 0.0

		_Color("Color", Color) = (1,1,1,1)
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_MainTex("Albedo", 2D) = "white" {}
		[NoScaleOffset]_PBRMap("PBRMap[R-Metallic, G-Smoothness, B-Emission, A-AO]", 2D) = "white" {}
		[NoScaleOffset]_BumpMap("Normal", 2D) = "bump" {}
		_BumpScale("NormalScale", Range(-2 , 2)) = 1
		_AnisotropicRampTex("Anisotropic Ramp Tex", 2D) = "white" {}
		_Smoothness("Smoothness", Range(0, 1)) = 1
		_Occlusion("Occlusion", Range(0, 1)) = 1
		_Metallic("Metallic", Range(0, 1)) = 1

		[NoScaleOffset]_ThicknessMap("Thickness", 2D) = "white" {}
		_TransculancyDistortion("Transculancy Distortion", Range(-1, 1)) = 1
		_TransculancyPower("Transculancy Power", Range(0.001, 40)) = 1
		_TransculancyGIScale("Transculancy Power", Range(0, 4)) = 1
		[HDR]_TransculancyColor("Transculancy Color", Color) = (0,0,0,0)

		[NoScaleOffset]_SkinBRDFLut("Skin BRDF Lut", 2D) = "black" {}
		[NoScaleOffset]_SkinSSSTex("Skin Curvelate Map", 2D) = "black" {}
		[HDR]_SkinSubColor("Skin SubColor", Color) = (0,0,0,0)
		_SkinCurvatureScale("Skin Curvelate Sacle", Range(-5, 5)) = 1
		_SkinThicknessScale("Skin Thickness Sacle", Range(0, 1)) = 1
		_SkinPower("Skin Power", Range(0.001, 40)) = 1
		_SkinDistortion("Skin Distortion", Range(-1, 1)) = 1

		[HDR]_EmissionColor("Emmision Color",Color) = (0,0,0,0)

		_ReflectionFactor("Reflection Factor", Range(0, 50)) = 0.2
		_ReflectionBlendFactor("Reflection Blend Factor", Range(0, 1)) = 0.2
		_ReflectionGamma("Reflection Gamma", Range(0,10)) = 2.2

		_RimScale("RimScale", Float) = 1
		_RimPower("RimPower", Range(1 , 10)) = 5
		[HDR]_RimColor("RimColor", Color) = (1,1,1,1)
		_RimBounceInfo("Rim Bounce Info", Vector) = (1,1,1,0)
		_RimBounceColor("Rim Bounce Color", Color) = (1,1,1,0)

		_OutlineWidth("Outlie Width", Float) = 1
		_OutlineScale("Outlie Scale", Float) = 1
		_OutlinePower("Outlie Power", Float) = 1
		[HDR]_OutlineColor("Outline Color", Color) = (1,1,1,0)
		[HideInInspector] _ColorMaskForOutline("Color Mask For Outline", Float) = 0

		_ShadeBlendMap("Shade Blend Map", 2D) = "black" {}

		_RainbowTex("Rainbow Texture", 2D) = "white"{}
		_RainbowPower("Rainbow Power", float) = 1
		_RainbowIntensity("Rainbow Intensity", float) = 1
		_IridesenceIntensity("Iridesence Intensity", float) = 3
		[HDR]_AnisotropicColor("Anisotropic Color", Color) = (1,1,1,1)

		_LightFlowTex("LightFlow Texture", 2D) = "white" {}
		_LightFlowAngle("LightFlow Width", Float) = 1
		_LightFlowWidth("LightFlow Scale", Float) = 1
		_LightFlowLoopTime("LightFlow Power", Float) = 1
		_LightFlowInterval("LightFlow Power", Float) = 1
		_LightFlowMode("LightFlow Mode", Float) = 1
		[HDR]_LightFlowColor("LightFlow Color", Color) = (1,1,1,1)

		//Cloth 
		[HDR]_SheenColor("Sheen Color", Color) = (1,1,1,1)
		_FabricMap("Fabric Micro Normal Map", 2D) = "bump"{}
		_FabricMircoScale("Fabric Micro Scale", Float) = 1
		_FabricMicroBumpScale("Fabric Micro Bump Scale", Range(-2 , 2)) = 1

		// Blending state
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
		[HideInInspector] _Cull("__cull", Float) = 2
	}
    SubShader
    {
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
			Cull[_Cull]
			CGPROGRAM
			#pragma vertex vertBase
			#pragma fragment fragBase
			#pragma target 3.0

			#pragma multi_compile_fwdbase

			#pragma shader_feature_local _SH_ENV_LIGHTING_OFF
			//#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _PBRMAP
			#pragma shader_feature_local _RIM_HIGHLIGHT_ON
			#pragma shader_feature_local _LIGHT_FLOW_ON


			#pragma shader_feature_local _TRANSCULANCY_ON
			#pragma shader_feature_local _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			//#pragma shader_feature_local _BRDF_SKIN _BRDF_FABRIC



			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsShaders_Inputs_Avatar.cginc"
			#include "EsShaders_BRDF.cginc"

			//#pragma skip_variants POINT POINT_COOKIE SHADOWS_CUBE VERTEXLIGHT_ON SHADOWS_SCREEN DYNAMICLIGHTMAP_ON

			#include "EsShaders_FowardLighting_Avatar.cginc"

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

			//#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _PBRMAP
			#pragma shader_feature_local _TRANSCULANCY_ON
			#pragma shader_feature_local _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsShaders_Inputs_Avatar.cginc"
			#include "EsShaders_BRDF.cginc"
			//#pragma skip_variants SHADOWS_CUBE VERTEXLIGHT_ON SHADOWS_SCREEN DYNAMICLIGHTMAP_ON 
			#include "EsShaders_FowardLighting_Avatar.cginc"
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

			#pragma shader_feature_local _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			// Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
			//#pragma multi_compile _ LOD_FADE_CROSSFADE

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "EsShaders_Shadow.cginc"

			ENDCG
		}
	}
	CustomEditor "EsShaders_PBR_Avatar_GUI"
}
