#ifndef ESSHADERS_BRDF_HELPER_INCLUDED
#define ESSHADERS_BRDF_HELPER_INCLUDED

#define HALF_EPSILON 0.0001

//-------Shadow Fix---------
fixed4 _RealtimeShadowColor;
fixed4 _ShadowColor;
half _ShadowMapToneThreshold;

sampler2D _ThicknessMap;
float _TransculancyDistortion;
float _TransculancyPower;
fixed4 _TransculancyColor;
half _TransculancyGIScale;

float3 _ReflectionProbePos;
float3 _BoxMax;
float3 _BoxMin;

//
//
//sampler2D _AnisotropicRampTex;
//float4 _AnisotropicRampTex_ST;

sampler2D _ReflectionTexture;
sampler2D _BluredRelfectionColor;
half _ReflectionFactor;
half _ReflectionBlendFactor;
float _ReflectionGamma;
half4 _ReflectionColor;

float4 _RimColor;
float _RimScale;
float _RimPower;
float _RimBlend;

float4 _RimBounceInfo;
float4 _RimBounceColor;



//float _OutlineScale;
//float _OutlineColor;

sampler2D _LightFlowTex;
float4 _LightFlowTex_ST;

float4 _LightFlowColor;
int _LightFlowMode;
half _LightFlowAngle;
half _LightFlowWidth;
half _LightFlowLoopTime;
half _LightFlowInterval;

//------Iridescene------
sampler2D _ShadeBlendMap;
sampler2D _RainbowTex;
float _RainbowPower;
float _RainbowIntensity;
float _IridesenceIntensity;
float4 _AnisotropicColor;

//cloth
half4 _SheenColor;

//-------Fabric Info---------
sampler2D _FabricMap;
fixed4 _FuzzColor;
float _Fabric;
half _FabricMicroBumpScale;
fixed4 _WrapLightColor;
half _FabricMircoScale;

#define FLT_EPS  5.960464478e-8
#define FLT_MAX 3.402823466e+38F 
#define FLT_MIN 1.175494351e-38F 


inline half _Pow2(half x)
{
	return x * x;
}

inline half _Pow4(half x)
{
	return x * x*x*x;
}

inline float2 _Pow4(float2 x)
{
	return x * x*x*x;
}

inline half3 _Pow4(half3 x)
{
	return x * x*x*x;
}

inline half4 _Pow4(half4 x)
{
	return x * x*x*x;
}

inline half _Pow5(half x)
{
	return x * x * x*x * x;
}

inline half2 _Pow5(half2 x)
{
	return x * x * x*x * x;
}

inline half3 _Pow5(half3 x)
{
	return x * x * x*x * x;
}

inline half4 _Pow5(half4 x)
{
	return x * x * x*x * x;
}

float3 ShiftTangent(float3 T, float3 N, float shift)
{
	float3 shiftT = T + shift * N;
	return normalize(shiftT);
}

half _LerpOneTo(half b, half t)
{
	half oneMinusT = 1 - t;
	return oneMinusT + b * t;
}

half3 _LerpWhiteTo(half3 b, half t)
{
	half oneMinusT = 1 - t;
	return half3(oneMinusT, oneMinusT, oneMinusT) + b * t;
}

half3 _UnpackScaledNormal(half4 packednormal, half scale)
{
//#ifndef UNITY_NO_DXT5nm
	// Unpack normal as DXT5nm (1, y, 1, x) or BC5 (x, y, 0, 1)
	// Note neutral texture like "bump" is (0, 0, 1, 1) to work with both plain RGB normal and DXT5nm/BC5
	packednormal.x *= packednormal.w;
//#endif
	fixed3 normal;
	normal.xy = (packednormal.xy * 2 - 1) * scale;
	normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
	return normal;
}

half3 _UnpackScaledNormal(half3 packednormal, half scale)
{
	fixed3 normal;
	normal.xy = (packednormal.xy * 2 - 1) * scale;
	normal.z = sqrt(1 - saturate(dot(normal.xy, normal.xy)));
	return normal;
}

half3 _UnpackScaledNormal_DX(half4 packednormal, half scale)
{
//#ifndef UNITY_NO_DXT5nm
	// Unpack normal as DXT5nm (1, y, 1, x) or BC5 (x, y, 0, 1)
	// Note neutral texture like "bump" is (0, 0, 1, 1) to work with both plain RGB normal and DXT5nm/BC5
	packednormal.x *= packednormal.w;
//#endif
	fixed3 normal;
	normal.xz = (packednormal.xz * 2 - 1) * scale;
	normal.y = sqrt(1 - saturate(dot(normal.xz, normal.xz)));
	return normal;
}


// return value falls in [0, 1] section //
inline float lerpPingpong(float value)
{
	int remainder = fmod(floor(value), 2);
	return remainder == 1 ? 1 - frac(value) : frac(value);
}



/// 此处是顶点光照的处理
/// 1. 对于场景中的静态物体(LightMap Static),那么顶点光照应该是采样的是Lightmap里面的烘焙光照颜色， 输出lightmap的贴图坐标信息.
/// 2. 对于场景中的动态物体，那么需要采样的SH9的球谐光照, 输出SH9的颜色到rgb.
inline half4 VertexGI(float2 texcoord , float3 worldPos, float3 worldNormal)
{
	//计算环境光照或光照贴图uv坐标
	half4 ambientOrLightmapUV = 0;
	//如果开启光照贴图，计算光照贴图的uv坐标
#ifdef LIGHTMAP_ON
	ambientOrLightmapUV.xy = texcoord.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	ambientOrLightmapUV.zw = 0;
	//仅对动态物体采样光照探头,定义在UnityCG.cginc
#elif UNITY_SHOULD_SAMPLE_SH
	//计算非重要的顶点光照
#ifdef VERTEXLIGHT_ON
	//计算4个顶点光照，定义在UnityCG.cginc
	ambientOrLightmapUV.rgb = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, worldPos, worldNormal);
#endif
	//计算球谐光照，定义在UnityCG.cginc
	ambientOrLightmapUV.rgb = ShadeSHPerVertex(worldNormal, ambientOrLightmapUV.rgb);
#endif
	return ambientOrLightmapUV;
}

inline half4 VertexGI_SH(float2 texcoord, float3 worldPos, float3 worldNormal)
{
	//计算环境光照或光照贴图uv坐标
	half4 ambientOrLightmapUV = 0;
	//仅对动态物体采样光照探头,定义在UnityCG.cginc
#ifdef UNITY_SHOULD_SAMPLE_SH
	//计算球谐光照，定义在UnityCG.cginc
	ambientOrLightmapUV.rgb = ShadeSHPerVertex(worldNormal, ambientOrLightmapUV.rgb);
#endif
	return ambientOrLightmapUV;
}


// Decodes HDR textures
// handles dLDR, RGBM formats
// Called by DecodeLightmap when UNITY_NO_RGBM is not defined.
inline half3 _DecodeLightmapRGBM(half4 data, half4 decodeInstructions)
{
	// If Linear mode is not supported we can skip exponent part
#if defined(UNITY_COLORSPACE_GAMMA)
# if defined(UNITY_FORCE_LINEAR_READ_FOR_RGBM)
	return (decodeInstructions.x * data.a) * sqrt(data.rgb);
# else
	return (decodeInstructions.x * data.a) * data.rgb;
# endif
#else
	return (decodeInstructions.x * pow(data.a, decodeInstructions.y)) * data.rgb;
#endif
}

// Decodes doubleLDR encoded lightmaps.
inline half3 _DecodeLightmapDoubleLDR(fixed4 color, half4 decodeInstructions)
{
	// decodeInstructions.x contains 2.0 when gamma color space is used or pow(2.0, 2.2) = 4.59 when linear color space is used on mobile platforms
	return unity_Lightmap_HDR.x * color.rgb;
}


inline half3 _DecodeLightmap(fixed4 color, half4 decodeInstructions)
{
#if defined(UNITY_LIGHTMAP_DLDR_ENCODING)
	return _DecodeLightmapDoubleLDR(color, decodeInstructions);
#elif defined(UNITY_LIGHTMAP_RGBM_ENCODING)
	return _DecodeLightmapRGBM(color, decodeInstructions);
#else //defined(UNITY_LIGHTMAP_FULL_HDR)
	return color.rgb;
#endif
}


inline half3 _DecodeLightmap(fixed4 color)
{
	return _DecodeLightmap(color, unity_Lightmap_HDR);
}

//计算间接光漫反射
inline half3 IndirectDiffuse(half4 ambientOrLightmapUV, float3 normalWorld, float3 normalPos, half occlusion, inout half3 lightColor)
{
	half3 indirectDiffuse = 0;
	half atten = 1;
	//如果是动态物体，间接光漫反射为在顶点函数中计算的非重要光源
#if UNITY_SHOULD_SAMPLE_SH
	indirectDiffuse = ShadeSHPerPixel(normalWorld, ambientOrLightmapUV.rgb, normalPos);
#endif

	//在這裏要處理GI中的陰影
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	half bakedAtten = UnitySampleBakedOcclusion(ambientOrLightmapUV.xy, normalPos);
	float zDist = dot(_WorldSpaceCameraPos - normalPos, UNITY_MATRIX_V[2].xyz);
	float fadeDist = UnityComputeShadowFadeDistance(normalPos, zDist);
	atten = UnityMixRealtimeAndBakedShadows(1, bakedAtten, UnityComputeShadowFade(fadeDist));
#endif
	lightColor *= atten;
	//对于静态物体，则采样光照贴图或动态光照贴图
#ifdef LIGHTMAP_ON
	// Baked lightmaps, 对光照贴图进行采样和解码
	//UNITY_SAMPLE_TEX2D定义在HLSLSupport.cginc
	//DecodeLightmap定义在UnityCG.cginc
	half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, ambientOrLightmapUV.xy);
	half3 bakedColor = _DecodeLightmap(bakedColorTex);
	half shadowStrenth = _ShadowColor.a;
	half3 bakedColorTonned = (1 - bakedColor) * (_ShadowColor.rgb - 1) + 1;
	half bakedColorIllumination = 0.299 * bakedColor.r + 0.587 * bakedColor.g + 0.184 * bakedColor.b;
	//return smoothstep(_ShadowMapToneThreshold, 1, bakedColorIllumination);
	bakedColor = lerp(bakedColor, bakedColorTonned, smoothstep(_ShadowMapToneThreshold, 1, bakedColorIllumination));
		#ifdef DIRLIGHTMAP_COMBINED
			fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, ambientOrLightmapUV.xy);
			indirectDiffuse += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);

			#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
				indirectDiffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(indirectDiffuse, 0, bakedColorTex, normalWorld);
			#endif

			#else // not directional lightmap
				indirectDiffuse += bakedColor;

				#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
					indirectDiffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(indirectDiffuse, 0, bakedColorTex, normalWorld);
				#endif
		#endif
#endif

#ifdef DYNAMICLIGHTMAP_ON
		//对动态光照贴图进行采样和解码, 基本不用.
		//DecodeRealtimeLightmap定义在UnityCG.cginc
		half3 realtimeColor = DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, ambientOrLightmapUV.zw));
	#ifdef DIRLIGHTMAP_COMBINED
		half4 realtimeDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, ambientOrLightmapUV.zw);
		indirectDiffuse += DecodeDirectionalLightmap(realtimeColor, realtimeDirTex, normalWorld);
	#else
		indirectDiffuse += realtimeColor;
	#endif
#endif

	//将间接光漫反射乘以环境光遮罩，返回
	return indirectDiffuse * occlusion;
}

inline half3 IndirectDiffuseMedium(half4 ambientOrLightmapUV, float3 normalWorld, float3 normalPos, half occlusion, inout half3 lightColor)
{
	half3 indirectDiffuse = 0;
	half atten = 1;
	//如果是动态物体，间接光漫反射为在顶点函数中计算的非重要光源
#if UNITY_SHOULD_SAMPLE_SH
	indirectDiffuse = ShadeSHPerPixel(normalWorld, ambientOrLightmapUV.rgb, normalPos);
#endif

	//在這裏要處理GI中的陰影
#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
	half bakedAtten = UnitySampleBakedOcclusion(ambientOrLightmapUV.xy, normalPos);
	float zDist = dot(_WorldSpaceCameraPos - normalPos, UNITY_MATRIX_V[2].xyz);
	float fadeDist = UnityComputeShadowFadeDistance(normalPos, zDist);
	atten = UnityMixRealtimeAndBakedShadows(1, bakedAtten, UnityComputeShadowFade(fadeDist));
#endif
	lightColor *= atten;
	//对于静态物体，则采样光照贴图或动态光照贴图
#ifdef LIGHTMAP_ON
	// Baked lightmaps, 对光照贴图进行采样和解码
	//UNITY_SAMPLE_TEX2D定义在HLSLSupport.cginc
	//DecodeLightmap定义在UnityCG.cginc
	half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, ambientOrLightmapUV.xy);
	half3 bakedColor = _DecodeLightmap(bakedColorTex);
	half shadowStrenth = _ShadowColor.a;
	half3 bakedColorTonned = (1 - bakedColor) * (_ShadowColor.rgb - 1) + 1;
	half bakedColorIllumination = 0.299 * bakedColor.r + 0.587 * bakedColor.g + 0.184 * bakedColor.b;
	//return smoothstep(_ShadowMapToneThreshold, 1, bakedColorIllumination);
	bakedColor = lerp(bakedColor, bakedColorTonned, smoothstep(_ShadowMapToneThreshold, 1, bakedColorIllumination));

	indirectDiffuse += bakedColor;
#endif

	//将间接光漫反射乘以环境光遮罩，返回
	return indirectDiffuse * occlusion;
}

//计算间接光漫反射
inline half3 IndirectDiffuseAvatar(half4 ambientOrLightmapUV, float3 normalWorld, float3 normalPos, half occlusion)
{
	half3 indirectDiffuse = 0;
	//如果是动态物体，间接光漫反射为在顶点函数中计算的非重要光源
#ifdef _SH_ENV_LIGHTING_OFF
	return 0;
#else
	indirectDiffuse = ShadeSHPerPixel(normalWorld, ambientOrLightmapUV.rgb, normalPos);
#endif
	//将间接光漫反射乘以环境光遮罩，返回
	return indirectDiffuse * occlusion;
}



//计算间接光漫反射
inline half3 IndirectDiffuseFur(half4 ambientOrLightmapUV, float3 normalWorld, float3 normalPos, half occlusion)
{
	half3 indirectDiffuse = 0;
	//如果是动态物体，间接光漫反射为在顶点函数中计算的非重要光源
#if UNITY_SHOULD_SAMPLE_SH
		indirectDiffuse = ShadeSHPerPixel(normalWorld, ambientOrLightmapUV.rgb, normalPos);
	#endif
		//对于静态物体，则采样光照贴图或动态光照贴图
	#ifdef LIGHTMAP_ON
			// Baked lightmaps, 对光照贴图进行采样和解码
			//UNITY_SAMPLE_TEX2D定义在HLSLSupport.cginc
			//DecodeLightmap定义在UnityCG.cginc
			half4 bakedColorTex = UNITY_SAMPLE_TEX2D(unity_Lightmap, ambientOrLightmapUV.xy);
			half3 bakedColor = _DecodeLightmap(bakedColorTex);			
		#ifdef DIRLIGHTMAP_COMBINED
			fixed4 bakedDirTex = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, ambientOrLightmapUV.xy);
			indirectDiffuse += DecodeDirectionalLightmap(bakedColor, bakedDirTex, normalWorld);
		#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) 
			indirectDiffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(indirectDiffuse, 0, bakedColorTex, normalWorld);
		#endif

		#else // not directional lightmap
			indirectDiffuse += bakedColor;
		#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN)
			indirectDiffuse = SubtractMainLightWithRealtimeAttenuationFromLightmap(indirectDiffuse, 0, bakedColorTex, normalWorld);
		#endif
	#endif
#endif


	//将间接光漫反射乘以环境光遮罩，返回
	return indirectDiffuse * occlusion;
}

half3 _ShadeSHPerPixel(half3 normal, half3 ambient, float3 worldPos)
{
	half3 ambient_contrib = 0.0;
#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
	// Completely per-pixel
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
	if (unity_ProbeVolumeParams.x == 1.0)
		ambient_contrib = SHEvalLinearL0L1_SampleProbeVolume(half4(normal, 1.0), worldPos);
	else
		ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
#else
	ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
#endif

	ambient_contrib += SHEvalLinearL2(half4(normal, 1.0));

	ambient += max(half3(0, 0, 0), ambient_contrib);

#ifdef UNITY_COLORSPACE_GAMMA
	ambient = LinearToGammaSpace(ambient);
#endif

#elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
	// Completely per-vertex
	// nothing to do here. Gamma conversion on ambient from SH takes place in the vertex shader, see ShadeSHPerVertex.
#else
	// L2 per-vertex, L0..L1 & gamma-correction per-pixel
	// Ambient in this case is expected to be always Linear, see ShadeSHPerVertex()
#if UNITY_LIGHT_PROBE_PROXY_VOLUME
	if (unity_ProbeVolumeParams.x == 1.0)
		ambient_contrib = SHEvalLinearL0L1_SampleProbeVolume(half4(normal, 1.0), worldPos);
	else
		ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
#else
	ambient_contrib = SHEvalLinearL0L1(half4(normal, 1.0));
#endif

	ambient = max(half3(0, 0, 0), ambient + ambient_contrib);     // include L2 contribution in vertex shader before clamp.
#ifdef UNITY_COLORSPACE_GAMMA
	ambient = LinearToGammaSpace(ambient);
#endif
#endif
	return ambient;
}


//重新映射反射方向
inline half3 BoxProjectedDirection(half3 worldRefDir, float3 worldPos, float4 cubemapCenter, float4 boxMin, float4 boxMax)
{
	//使下面的if语句产生分支，定义在HLSLSupport.cginc中
	UNITY_BRANCH
		if (cubemapCenter.w > 0.0)//如果反射探头开启了BoxProjection选项，cubemapCenter.w > 0
		{
			half3 rbmax = (boxMax.xyz - worldPos) / worldRefDir;
			half3 rbmin = (boxMin.xyz - worldPos) / worldRefDir;

			half3 rbminmax = (worldRefDir > 0.0f) ? rbmax : rbmin;

			half fa = min(min(rbminmax.x, rbminmax.y), rbminmax.z);

			worldPos -= cubemapCenter.xyz;
			worldRefDir = worldPos + worldRefDir * fa;
		}
	return worldRefDir;
}

float3 BoxProjectedDirection2(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
#if UNITY_SPECCUBE_BOX_PROJECTION
	UNITY_BRANCH
		if (cubemapPosition.w > 0)
		{
			float3 factors =
				((direction > 0 ? _BoxMax : _BoxMin) - position) / direction;
			float scalar = min(min(factors.x, factors.y), factors.z);
			direction = direction * scalar + (position - _ReflectionProbePos.xyz);
		}
#endif
	return direction;
}


//采样反射探头
//UNITY_ARGS_TEXCUBE定义在HLSLSupport.cginc,用来区别平台
inline half3 SamplerReflectProbe(UNITY_ARGS_TEXCUBE(tex), half3 refDir, half roughness, half4 hdr)
{
	half mip = roughness * 6;
	//对反射探头进行采样
	//UNITY_SAMPLE_TEXCUBE_LOD定义在HLSLSupport.cginc，用来区别平台
	half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(tex, refDir, mip);
	//采样后的结果包含HDR,所以我们需要将结果转换到RGB
	//定义在UnityCG.cginc
	return DecodeHDR(rgbm, hdr);
}

//计算间接光镜面反射
inline half3 GISpecular(half3 refDir, float3 worldPos, half roughness, half occlusion)
{
	// MM: came up with a surprisingly close approximation to what the #if 0'ed out code above does.
	roughness = roughness * (1.7 - 0.7*roughness);

	half3 specular = 0;
	//重新映射第一个反射探头的采样方向
	half3 refDir1 = BoxProjectedDirection2(refDir, worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin.xyz, unity_SpecCube0_BoxMax.xyz);
	//对第一个反射探头进行采样
	specular = SamplerReflectProbe(UNITY_PASS_TEXCUBE(unity_SpecCube0), refDir1, roughness, unity_SpecCube0_HDR);

	////如果第一个反射探头的权重小于1的话，我们将会采样第二个反射探头，进行混合
	////使下面的if语句产生分支，定义在HLSLSupport.cginc中
	//UNITY_BRANCH
	//	if (unity_SpecCube0_BoxMin.w < 0.99999)
	//	{
	//		//重新映射第二个反射探头的方向
	//		half3 refDir2 = BoxProjectedDirection2(refDir, worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
	//		//对第二个反射探头进行采样
	//		half3 ref2 = SamplerReflectProbe(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), refDir2, roughness, unity_SpecCube1_HDR);

	//		//进行混合
	//		specular = lerp(ref2, ref1, unity_SpecCube0_BoxMin.w);
	//	}
	//	else
	//	{
	//		specular = ref1;
	//	}
	return specular * occlusion;
}

//计算间接光镜面反射
inline half3 GetAnisotropyReflectionDir(half3 view, half3 binormal, half3 normal, half anisotropy)
{
	half3 anisotropicTagent = cross(view, binormal);
	half3 anisotropicNormal = cross(anisotropicTagent, binormal);
	half3 reflectionNormal = normalize(lerp(normal, anisotropicNormal, anisotropy));
	return view - 2 * dot(reflectionNormal, view) * reflectionNormal;
}

//计算间接光镜面反射
inline half3 GISpecular_PlanarRt(half4 screenPosTexcoord, half roughness, half3 normal, half occlusion, float gamma, out fixed alpha)
{
	screenPosTexcoord.xyz += normal;
	fixed4 reflectionColor = tex2Dproj(_ReflectionTexture, screenPosTexcoord);
	alpha = reflectionColor.a;
	fixed3 reflectionGI = reflectionColor.rgb;
	//fixed3 blurredColor = tex2Dproj(_BluredRelfectionColor, screenPosTexcoord).rgb;
	//reflectionGI = lerp(reflectionColor, blurredColor, roughness);
	reflectionGI = pow(reflectionGI, gamma) * occlusion; // trick to color adjust.
	return reflectionGI;
}

inline half3 RimSetup(half3 color, float3 normal, float3 viewDir)
{
#if _RIM_HIGHLIGHT_ON
	bool rimBounceOn = _RimBounceInfo.w > 0.1;
	float4 rimColor = _RimColor;
	half nDotV = max(0, dot(normal, viewDir));
	float rimPower = _RimPower;
	/*if (rimBounceOn)
	{
		float rimBouncePowerMin = _RimBounceInfo.x;
		float rimBouncePowerMax = _RimBounceInfo.y;
		float rimBouncePowerSpeed = _RimBounceInfo.z;

		rimColor = _RimBounceColor;
		rimPower = rimBouncePowerMin + rimBouncePowerMax * abs(sin(_Time.x * rimBouncePowerSpeed));
	}*/
	half rimFresnel = saturate(pow(1.0 - nDotV, rimPower));
	color = lerp(color, _RimScale * rimColor.rgb, rimColor.a * _RimBlend * rimFresnel);
#endif
	return color;
}

inline half3 EmissionSetup(half3 emission, half4 texcoord, float3 normal, float3 viewDir, float lightDir, half3 lightColor, float3 worldPosition)
{
#ifdef _TRANSCULANCY_ON
	float3 tranculancyLightDistortion = normalize((lightDir + (normal * _TransculancyDistortion)));
	half3 giDiffuseDistorted = _ShadeSHPerPixel(normalize(normal * _TransculancyDistortion) * -1.0, 0, worldPosition);
	float tranculancyDot = dot((tranculancyLightDistortion * -1.0), viewDir);
	fixed thickness = 1 - tex2D(_ThicknessMap, texcoord.xy).r;
	emission += thickness * pow(saturate(tranculancyDot), _TransculancyPower) * (lightColor * _TransculancyColor.rgb + _TransculancyGIScale * giDiffuseDistorted);
#endif
	
//#if _LIGHT_FLOW_ON
//	half2 lightFlowTexcoord = TRANSFORM_TEX(texcoord.zw, _LightFlowTex);
//	float sinX = sin(_LightFlowAngle);
//	float cosX = cos(_LightFlowAngle);
//	float2x2 rotationMatrix = float2x2(cosX, -sinX, sinX, cosX);
//	lightFlowTexcoord = mul(lightFlowTexcoord / _LightFlowWidth, rotationMatrix);
//
//	float totalTime = _LightFlowInterval + _LightFlowLoopTime;
//
//	float currentTurnStartTime = (int)((_Time.y / totalTime)) * totalTime;
//	float currentTurnTimePassed = _Time.y - currentTurnStartTime - _LightFlowInterval;
//
//	float percent = currentTurnTimePassed / _LightFlowLoopTime;
//	lightFlowTexcoord = frac(lightFlowTexcoord + float2(percent, percent));
//
//	half3 lightFlowColor = tex2D(_LightFlowTex, lightFlowTexcoord).rgb;
//	emission += lightFlowColor * _LightFlowColor.a * _LightFlowColor.rgb;
//#endif 
	return emission;
}


inline float ToonTerm(float nl, float toon_offset, float xxx)
{
	nl = (nl + 1) / 2;
	float toon_start = toon_offset - xxx;
	toon_start = max(toon_start, 0);
	float toon_end = toon_offset;
	return smoothstep(toon_start, toon_end, nl);
}

inline float _GGXTerm(float NdotH, float roughness)
{
	float a2 = roughness * roughness;
	float d = (NdotH * a2 - NdotH) * NdotH + 1.0f; // 2 mad
	return UNITY_INV_PI * a2 / (d * d + 1e-7f); // This function is not intended to be running on Mobile,
											// therefore epsilon is smaller than what can be represented by half
}

inline float _GGXTerm2(float nh, float roughness)
{
	float Roughness = _Pow2(roughness);
	float factor1 = (Roughness * 0.3183099);
	float factor2 = _Pow2((Roughness * nh - nh) * nh + 1);
	float result = factor1 / factor2;
	return result;
}

// Smith-Schlick derived for Beckmann
inline half _SmithBeckmannVisibilityTerm(half NdotL, half NdotV, half roughness)
{
	half c = 0.797884560802865h; // c = sqrt(2 / Pi)
	half k = roughness * c;
	return SmithVisibilityTerm(NdotL, NdotV, k) * 0.25f; // * 0.25 is the 1/4 of the visibility term
}

// BlinnPhong normalized as normal distribution function (NDF)
// for use in micro-facet model: spec=D*G*F
// eq. 19 in https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
inline half _NDFBlinnPhongNormalizedTerm(half NdotH, half n)
{
	// norm = (n+2)/(2*pi)
	half normTerm = (n + 2.0) * (0.5 / UNITY_PI);

	half specTerm = pow(NdotH, n);
	return specTerm * normTerm;
}

inline half _PerceptualRoughnessToSpecPower(half perceptualRoughness)
{
	half m = PerceptualRoughnessToRoughness(perceptualRoughness);   // m is the true academic roughness.
	half sq = max(1e-4f, m*m);
	half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
	n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
	return n;
}

// Ref: http://jcgt.org/published/0003/02/03/paper.pdf
inline float _SmithJointGGXVisibilityTerm(float NdotL, float NdotV, float roughness)
{
#if 0
	// Original formulation:
	//  lambda_v    = (-1 + sqrt(a2 * (1 - NdotL2) / NdotL2 + 1)) * 0.5f;
	//  lambda_l    = (-1 + sqrt(a2 * (1 - NdotV2) / NdotV2 + 1)) * 0.5f;
	//  G           = 1 / (1 + lambda_v + lambda_l);

	// Reorder code to be more optimal
	half a = roughness;
	half a2 = a * a;

	half lambdaV = NdotL * sqrt((-NdotV * a2 + NdotV) * NdotV + a2);
	half lambdaL = NdotV * sqrt((-NdotL * a2 + NdotL) * NdotL + a2);

	// Simplify visibility term: (2.0f * NdotL * NdotV) /  ((4.0f * NdotL * NdotV) * (lambda_v + lambda_l + 1e-5f));
	return 0.5f / (lambdaV + lambdaL + 1e-5f);  // This function is not intended to be running on Mobile,
												// therefore epsilon is smaller than can be represented by half
#else
	// Approximation of the above formulation (simplify the sqrt, not mathematically correct but close enough)
	float a = roughness;
	float lambdaV = NdotL * (NdotV * (1 - a) + a);
	float lambdaL = NdotV * (NdotL * (1 - a) + a);

#if defined(SHADER_API_SWITCH)
	return 0.5f / (lambdaV + lambdaL + 1e-4f); // work-around against hlslcc rounding error
#else
	return 0.5f / (lambdaV + lambdaL + 1e-5f);
#endif

#endif
}

inline float AnistropicalSpecular(float3 worldNormal, float3 worldTangent, float exp, float3 halfDir, float shiftAmount)
{
	fixed3 shiftTangent = normalize(shiftAmount * worldNormal + worldTangent);
	float powResult = _Pow2(dot(shiftTangent, halfDir));
	float index = _Pow5(1 / exp);
	float result = pow(sqrt(1 - powResult), index) * smoothstep(-1, 0, dot(shiftTangent, halfDir));
	return result;
}

inline float _FabricLambertNoPI(float roughness)
{
	return lerp(1.0, 0.5, roughness);
}

inline float _FabricLambert(float roughness)
{
	return UNITY_INV_PI * _FabricLambertNoPI(roughness);
}

inline float _DisneyDiffuse(float smoothness, float lh, float nl, float nv)
{
	float fd90 = 0.5 + 2 * lh * lh * (1 - smoothness);
	float viewScatter = _Pow5(1 - nv) * (fd90 - 1) + 1;
	float lightScatter = _Pow5(1 - nl) * (fd90 - 1) + 1;
	return viewScatter * lightScatter;
}


inline half3 _FresnelTerm(half3 F0, half cosA)
{
	half4 t = _Pow5(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}
inline half3 _FresnelTermFabric(half3 F0, half cosA)
{
	half t = _Pow4(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}
inline half3 _FresnelTermEs(half3 F0, half cosA)
{
	half t = _Pow5(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}
inline half4 FresnelLerp(half4 F0, half4 F90, half cosA)
{
	half t = _Pow5(1 - cosA);   // ala Schlick interpoliation
	return lerp(F0, F90, t);
}

inline half4 FresnelLerpFast(half4 F0, half4 F90, half cosA)
{
	half t = _Pow4(1 - cosA);
	return lerp(F0, F90, t);
}

inline float D_InvBlinn(float Roughness, float NoH)
{
	float m = Roughness * Roughness;
	float m2 = m * m;
	float A = 4;
	float Cos2h = NoH * NoH;
	float Sin2h = 1 - Cos2h;
	//return rcp( PI * (1 + A*m2) ) * ( 1 + A * ClampedPow( Sin2h, 1 / m2 - 1 ) );
	return rcp(UNITY_PI * (1 + A * m2)) * (1 + A * exp(-Cos2h / m2));
}

inline float D_InvBeckmann(float Roughness, float NoH)
{
	float m = Roughness * Roughness;
	float m2 = m * m;
	float A = 4;
	float Cos2h = NoH * NoH;
	float Sin2h = 1 - Cos2h;
	float Sin4h = Sin2h * Sin2h;
	return rcp(UNITY_PI * (1 + A * m2) * Sin4h) * (Sin4h + A * exp(-Cos2h / (m2 * Sin2h)));
}

inline float D_InvGGX(float Roughness, float NoH)
{
	float a = Roughness * Roughness;
	float a2 = a * a;
	float A = 4;
	float d = (NoH - a2 * NoH) * NoH + a2;
	return rcp(UNITY_PI * (1 + A * a2)) * (1 + 4 * a2*a2 / (d*d));
}

inline half FabricScatterFresnelLerp(half nv, half scale)
{
	half t0 = Pow4(1 - nv);
	half t1 = 0.4 * (1 - nv);
	return (t1 - t0) * scale + t0;
}

inline float V_Cloth(float NoV, float NoL)
{
	return rcp(4 * (NoL + NoV - NoL * NoV));
}

inline float FabricD(float roughness, float NdotH)
{
	return 0.96 * pow(1 - NdotH, 2) + 0.057;
}

// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
inline float3 F_Schlick(float3 SpecularColor, float VoH)
{
	float Fc = Pow5(1 - VoH);					// 1 sub, 3 mul
	//return Fc + (1 - Fc) * SpecularColor;		// 1 add, 3 mad

	// Anything less than 2% is physically impossible and is instead considered to be shadowing
	return saturate(50.0 * SpecularColor.g) * Fc + (1 - Fc) * SpecularColor;

}


// [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
inline float Diffuse_OrenNayar(float Roughness, float Roughness2, float NoV, float NoL, float VoH)
{
	float s = Roughness2;// / ( 1.29 + 0.5 * a );
	float s2 = s * s;
	float VoL = 2 * VoH * VoH - 1;		// double angle identity
	float Cosri = VoL - NoV * NoL;
	float C1 = 1 - 0.5 * s2 / (s2 + 0.33);
	float C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * (Cosri >= 0 ? rcp(max(NoL, NoV)) : 1);
	return UNITY_INV_PI * (C1 + C2) * (1 + Roughness * 0.5);
}



inline float3 WorldSpaceNormalFromTangentSpace(float3 tangent, float3 binormal, float3 normal, float3 normalTangent)
{
	return tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z;
	/*float3 tSpace0 = float3(tangent.x, binormal.x, normal.x);
	float3 tSpace1 = float3(tangent.y, binormal.y, normal.y);
	float3 tSpace2 = float3(tangent.z, binormal.z, normal.z);
	return normalize(float3(dot(tSpace0, normalTangent), dot(tSpace1, normalTangent), dot(tSpace2, normalTangent)));*/
}

inline float3 TangentSpaceViewDir(float3 tangent, float3 binormal, float3 normal, float3 viewDir)
{
	float3x3 TBN = float3x3(tangent, binormal, normal);
	return mul(TBN, viewDir);
}

inline float3 WorldSpaceLightDir(float3 worldPos)
{
	float3 lightDir = _WorldSpaceLightPos0.xyz;
	if (_WorldSpaceLightPos0.w > 0.)
	{
		// non-directional light - this is a position, not a direction
		lightDir = normalize(lightDir - worldPos.xyz);
	}
	return lightDir;
}

// http://advances.realtimerendering.com/other/2016/naughty_dog/NaughtyDog_TechArt_Final.pdf
inline float ApplyMicroSoftShadow(float ao, float3 N, float3 L, float shadow)
{
	float aperture = 2.0 * ao * ao;
	float microShadow = saturate(abs(dot(L, N)) + aperture - 1.0);
	return shadow * microShadow;
}

inline float3 ApplyLightWrap(float3 lightWrapColor, float3 worldNormal, float3 vertexNormalWs, float3 lightDir, float nl)
{
	float lightWrapDistance = 0.1;
	float3 wrapLight = lightWrapDistance * lightWrapColor;
	nl = lerp(max(wrapLight.r, max(wrapLight.g, wrapLight.b)), 1.0, nl);

	float wrapForwardNdotL = max(nl, dot(vertexNormalWs, lightDir));
	float3 wrapForward = lerp(wrapLight, float3(1, 1, 1), wrapForwardNdotL);
	float3 wrapRecede = lerp(-wrapLight, float3(1, 1, 1), nl);

	float3 wrapLighting = saturate(lerp(wrapRecede, wrapForward, lightWrapColor));
	return wrapLighting;
}

// 各项异性高光.
float AnistropicSpecular(float dotTH, float exponent)
{
	float sinTH = sqrt(1 - dotTH * dotTH);
	float dirAtten = smoothstep(-1, 0, dotTH);
	return dirAtten * pow(sinTH, exponent);
}

// Ashikhmin 2007, "Distribution-based BRDFs"
inline float D_Ashikhmin(float roughness, float NoH) {
	float a2 = roughness * roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125);
	float sin4h = max(0.0001,sin2h * sin2h);
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (UNITY_PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

inline float V_Ashikhmin(float nv, float nl)
{
	return 1. / (4. * (nl + nv - nl * nv));
}

inline float D_CharlieNoPI(float NdotH, float roughness)
{
	float invR = rcp(roughness);
	float cos2h = NdotH * NdotH;
	float sin2h = 1.0 - cos2h;
	// Note: We have sin^2 so multiply by 0.5 to cancel it
	return (2.0 + invR) * pow(abs(sin2h), invR * 0.5) / 2.0;
}

inline float D_Charlie(float NdotH, float roughness)
{
	return UNITY_INV_PI * D_CharlieNoPI(NdotH, roughness);
}

// Ref: "Crafting a Next-Gen Material Pipeline for The Order: 1886".
inline float ClampNdotV(float NdotV)
{
	return max(NdotV, 0.0001); // Approximately 0.0057 degree bias
}

// return usual BSDF angle
inline void GetBSDFAngle(float3 V, float3 L, float NdotL, float unclampNdotV, out float LdotV, out float NdotH, out float LdotH, out float clampNdotV, out float invLenLV)
{
	// Optimized math. Ref: PBR Diffuse Lighting for GGX + Smith Microsurfaces (slide 114).
	LdotV = dot(L, V);
	invLenLV = rsqrt(max(2.0 * LdotV + 2.0, FLT_EPS));    // invLenLV = rcp(length(L + V)), clamp to avoid rsqrt(0) = inf, inf * 0 = NaN
	NdotH = saturate((NdotL + unclampNdotV) * invLenLV);        // Do not clamp NdotV here
	LdotH = saturate(invLenLV * LdotV + invLenLV);
	clampNdotV = ClampNdotV(unclampNdotV);
}

// Inline D_GGXAniso() * V_SmithJointGGXAniso() together for better code generation.
inline float DV_SmithJointGGXAniso(float TdotH, float BdotH, float NdotH, float NdotV,
	float TdotL, float BdotL, float NdotL,
	float roughnessT, float roughnessB, float partLambdaV)
{
	float a2 = roughnessT * roughnessB;
	float3 v = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
	float  s = dot(v, v);

	float lambdaV = NdotL * partLambdaV;
	float lambdaL = NdotV * length(float3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

	float2 D = float2(a2 * a2 * a2, s * s);  // Fraction without the multiplier (1/Pi)
	float2 G = float2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

	// This function is only used for direct lighting.
	// If roughness is 0, the probability of hitting a punctual or directional light is also 0.
	// Therefore, we return 0. The most efficient way to do it is with a max().
	return (UNITY_INV_PI * 0.5) * (D.x * G.x) / max(D.y * G.y, FLT_MIN);
}


inline void ConvertValueAnisotropyToValueTB(float roughness, float anisotropy, out float valueT, out float valueB)
{
	// Use the parametrization of Sony Imageworks.
	// Ref: Revisiting Physically Based Shading at Imageworks, p. 15.
	valueT = roughness * (1 + anisotropy);
	valueB = roughness * (1 - anisotropy);
}

inline float GetSmithJointGGXAnisoPartLambdaV(float TdotV, float BdotV, float NdotV, float roughnessT, float roughnessB)
{
	return length(float3(roughnessT * TdotV, roughnessB * BdotV, NdotV));
}


inline float DV_SmithJointGGXAniso(float TdotH, float BdotH, float NdotH,
	float TdotV, float BdotV, float NdotV,
	float TdotL, float BdotL, float NdotL,
	float roughnessT, float roughnessB)
{
	float partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
	return DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, NdotV,
		TdotL, BdotL, NdotL,
		roughnessT, roughnessB, partLambdaV);
}

#endif