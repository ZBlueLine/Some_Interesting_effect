#ifndef ESSHADERS_BRDF_ACTOR_INCLUDED
#define ESSHADERS_BRDF_ACTOR_INCLUDED

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

// return value falls in [0, 1] section //
inline float lerpPingpong(float value)
{
	int remainder = fmod(floor(value), 2);
	return remainder == 1 ? 1 - frac(value) : frac(value);
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

//计算间接光漫反射
inline half3 IndirectDiffuse(half4 ambientOrLightmapUV, float3 normalWorld, float3 normalPos, half occlusion)
{
	half3 indirectDiffuse = ShadeSHPerPixel(normalWorld, ambientOrLightmapUV.rgb, normalPos);
	return indirectDiffuse * occlusion;
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
	//对第一个反射探头进行采样
	half3 specular = SamplerReflectProbe(UNITY_PASS_TEXCUBE(unity_SpecCube0), refDir, roughness, unity_SpecCube0_HDR);
	return specular * occlusion;
}

inline half3 RimSetup(half3 color, float3 normal, float3 viewDir)
{
#if _RIM_HIGHLIGHT_ON
	bool rimBounceOn = _RimBounceInfo.w > 0.1;
	//float4 rimColor = _RimColor;
	half nDotV = max(0, dot(normal, viewDir));
	//float rimPower = _RimPower;
	/*if (rimBounceOn)
	{
		float rimBouncePowerMin = _RimBounceInfo.x;
		float rimBouncePowerMax = _RimBounceInfo.y;
		float rimBouncePowerSpeed = _RimBounceInfo.z;

		rimColor = _RimBounceColor;
		rimPower = rimBouncePowerMin + rimBouncePowerMax * abs(sin(_Time.x * rimBouncePowerSpeed));
	}*/
	half rimFresnel = saturate(pow(1.0 - nDotV, _RimPower));
	color = lerp(color, _RimScale * _RimColor.rgb, _RimColor.a * _RimBlend * rimFresnel);
#else
	float4 rimColor = _SideRimColor;
	//float3 worldNorm = normalize(unity_WorldToObject[0].xyz * normal.x + unity_WorldToObject[1].xyz * normal.y + unity_WorldToObject[2].xyz * normal.z);
	float3 worldNorm = mul((float3x3)UNITY_MATRIX_V, normal);
	half nDotV = max(0, dot(worldNorm, _SideRimDir.xyz));
	half rimFresnel = saturate(pow(nDotV, _SideRimPower));
	color = lerp(color, _SideRimColor.rgb, _SideRimColor.a * rimFresnel);
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

inline half3 _Pow4(half3 x)
{
	return x * x*x*x;
}

inline half4 FresnelLerpFast(half4 F0, half4 F90, half cosA)
{
	half t = _Pow4(1 - cosA);
	return lerp(F0, F90, t);
}

inline float3 WorldSpaceNormalFromTangentSpace(float3 tangent, float3 binormal, float3 normal, float3 normalTangent)
{
	return tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z;
	/*float3 tSpace0 = float3(tangent.x, binormal.x, normal.x);
	float3 tSpace1 = float3(tangent.y, binormal.y, normal.y);
	float3 tSpace2 = float3(tangent.z, binormal.z, normal.z);
	return normalize(float3(dot(tSpace0, normalTangent), dot(tSpace1, normalTangent), dot(tSpace2, normalTangent)));*/
}


// -------------------------Standard Microfacet BRDF on Mobile-------------------------
half3 Es_BDRF_Mobile(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 viewDir, float3 lightDir,
	half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	half3 halfDir = normalize((lightDir + viewDir));
	float nl = saturate(dot(normal, lightDir));
	float nh = saturate(dot(normal, halfDir));
	half nv = saturate(dot(normal, viewDir));
	half lh = saturate(dot(lightDir, halfDir));

	half perceptualRoughness = 1 - smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	roughness = max(roughness, 0.075);

	// Diffuse term
	half diffuseTerm = nl; 

	half a = roughness;
	float a2 = a * a;
	float d = nh * nh * (a2 - 1.f) + 1.00001f;

	float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);

	// on mobiles (where half actually means something) denominator have risk of overflow
	// clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
	// sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE)
	specularTerm = specularTerm - 1e-4f;
#endif

	// surfaceReduction用来修正IBL的反射GGX的修正.
	// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(realRoughness^2+1)

	// 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
	// 1-x^3*(0.6-0.08*x)   approximation for 1/(x^4+1)
	half surfaceReduction = (0.6 - 0.08*perceptualRoughness);
	surfaceReduction = 1.0 - roughness * perceptualRoughness * surfaceReduction;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	// To provide true Lambert lighting, we need to be able to kill specular completely.
	specularTerm *= any(specColor) ? 1.0 : 0.0;

	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = (diffColor + specularTerm * specColor) * lightColor * diffuseTerm
		+ giDiffuse * diffColor
		+ surfaceReduction * giSpecular * FresnelLerpFast(specColor, grazingTerm, nv);
	return color;
}

#endif