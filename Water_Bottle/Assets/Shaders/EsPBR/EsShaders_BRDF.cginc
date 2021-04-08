#ifndef ESSHADERS_BRDF_INCLUDED
#define ESSHADERS_BRDF_INCLUDED

#include "EsShaders_BRDFHelper.cginc"

// -------------------------Standard Microfacet BRDF-------------------------
half3 Es_BDRF(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
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
	roughness = max(roughness, 0.002);

	// Diffuse term
	//half diffuseTerm = _DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;

	half diffuseTerm = nl; // tone mapping, 后期需要改的, 如果有这个需求.
	//float V = _SmithBeckmannVisibilityTerm(nl, nv, roughness);
	//float D = _NDFBlinnPhongNormalizedTerm(nh, _PerceptualRoughnessToSpecPower(perceptualRoughness));

	float V = _SmithJointGGXVisibilityTerm(nl, nv, roughness);
	float D = _GGXTerm(nh, roughness);
	half3 F = _FresnelTermEs(specColor, lh);//计算BRDF高光反射项，菲涅尔项F
	float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#endif

	specularTerm = max(0, specularTerm * nl);

	//#if defined(_SPECULARHIGHLIGHTS_OFF)
	//	specularTerm = 0.0;
	//#endif

	// surfaceReduction用来修正IBL的反射GGX的修正.
	// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
	half surfaceReduction;
#ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#else
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
#endif

	// To provide true Lambert lighting, we need to be able to kill specular completely.
	specularTerm *= any(specColor) ? 1.0 : 0.0;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ specularTerm * F * lightColor + surfaceReduction * giSpecular * FresnelLerp(specColor, grazingTerm, nv);
	return color;
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
	half diffuseTerm = nl; // tone mapping, 后期需要改的, 如果有这个需求.

	half a = roughness;
	float a2 = a * a;
	float d = nh * nh * (a2 - 1.f) + 1.00001f;

#ifdef UNITY_COLORSPACE_GAMMA
	// Tighter approximation for Gamma only rendering mode!
	// DVF = sqrt(DVF);
	// DVF = (a * sqrt(.25)) / (max(sqrt(0.1), lh)*sqrt(roughness + .5) * d);
	float specularTerm = a / (max(0.32f, lh) * (1.5f + roughness) * d);
#else
	float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);
#endif

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
#ifdef UNITY_COLORSPACE_GAMMA
	half surfaceReduction = 0.28;
#else
	half surfaceReduction = (0.6 - 0.08*perceptualRoughness);
#endif

	surfaceReduction = 1.0 - roughness * perceptualRoughness*surfaceReduction;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	// To provide true Lambert lighting, we need to be able to kill specular completely.
	specularTerm *= any(specColor) ? 1.0 : 0.0;

	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = (diffColor + specularTerm * specColor) * lightColor * diffuseTerm
		+ giDiffuse * diffColor
		+ surfaceReduction * giSpecular * FresnelLerpFast(specColor, grazingTerm, nv);
	return color;
}

// ---------------------------------------Cloth BRDF---------------------------------------
half3 Es_BDRF_Fabric_Cotton(half3 diffColor, half3 specColor, half4 fuzzColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 V, float3 L,
	half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	half3 H = normalize((L + V));
	float NdotL = saturate(dot(normal, L));
	//float NdotH = saturate(dot(normal, H));
	half _NdotV = dot(normal, V);

	float LdotV, NdotH, LdotH, NdotV, invLenLV;
	GetBSDFAngle(V, L, NdotL, _NdotV, LdotV, NdotH, LdotH, NdotV, invLenLV);

	half perceptualRoughness = 1 - smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	roughness = max(roughness, 0.002);

	half fabricDiffuseTerm = _FabricLambertNoPI(perceptualRoughness);

	half diffuseTerm = fabricDiffuseTerm * NdotL;


	float D_fabric = D_CharlieNoPI(NdotH, roughness);
	float V_fabric = V_Ashikhmin(NdotV, NdotL);

	half3 grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	half surfaceReduction;
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]

	// To provide true Lambert lighting, we need to be able to kill specular completely.
	float specularTerm = saturate(V_fabric * D_fabric);
	//specularTerm *= any(specColor) ? 1.0 : 0.0;
	half3 F_specGI = surfaceReduction * giSpecular * FresnelLerp(specColor, grazingTerm, NdotV);

	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ diffuseTerm * specularTerm * (lightColor * fuzzColor.rgb + F_specGI);
	return color;
}
// ---------------------------------------Cloth BRDF---------------------------------------
half3 Es_BDRF_Fabric_Silk(half3 diffColor, half3 specColor, half4 fuzzColor, half oneMinusReflectivity, float roughness, float roughnessT, float roughnessB, 
	float3 normal, float3 tangentWS, float3 bitangentWS, float3 V, float3 L,
	half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	float NdotL = saturate(dot(normal, L));
	half _NdotV = saturate(dot(normal, V));

	float LdotV, NdotH, LdotH, NdotV, invLenLV;
	GetBSDFAngle(V, L, NdotL, _NdotV, LdotV, NdotH, LdotH, NdotV, invLenLV);

	// For silk we just use a tinted anisotropy
	float3 H = (L + V) * invLenLV;

	// For anisotropy we must not saturate these values
	float TdotH = dot(tangentWS, H);
	float TdotL = dot(tangentWS, L);
	float BdotH = dot(bitangentWS, H);
	float BdotL = dot(bitangentWS, L);

	float TdotV = dot(tangentWS, V);
	float BdotV = dot(bitangentWS, V);

	roughnessT = max(roughnessT, 0.002);
	roughnessB = max(roughnessB, 0.002);

	roughness = max(roughness , 0.002);

	float partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);

	// TODO: Do comparison between this correct version and the one from isotropic and see if there is any visual difference
	float DV = DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, NdotV, TdotL, BdotL, NdotL,
		roughnessT, roughnessB, partLambdaV);

	// Fabric are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
	float3 F = _FresnelTermEs(specColor, LdotH);

	float specularTerm = F * DV;

	// Note: diffuseLighting is multiply by color in PostEvaluateBSDF
	float diffuseTerm = _DisneyDiffuse(NdotV, NdotL, LdotV, roughness);
	diffuseTerm *= saturate((dot(normal, L) + 0.5) / 2.25);

	half3 grazingTerm = saturate(roughness + (1 - oneMinusReflectivity));
	half surfaceReduction;
	surfaceReduction = 1.0 / (roughness * roughness + 1.0);           // fade \in [0.5;1]
	half3 F_specGI = surfaceReduction * giSpecular * FresnelLerp(specColor, grazingTerm, NdotV);

	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ NdotL * specularTerm * (lightColor * fuzzColor.rgb) + F_specGI;
	return color;
}


// -------------------------Layered or Multilple Pass Fur BRDF-------------------------
half3 Es_BDRF_Fur(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 viewDir, float3 lightDir,
	half3 lightColor, half3 giDiffuse)
{
	half3 halfDir = normalize((lightDir + viewDir));
	float nl = saturate(dot(normal, lightDir));
	float nh = saturate(dot(normal, halfDir));
	half nv = saturate(dot(normal, viewDir));
	half lh = saturate(dot(lightDir, halfDir));
	half perceptualRoughness = 1 - smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	roughness = max(roughness, 0.002);

	// Diffuse term
	//half diffuseTerm = _DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
	half diffuseTerm = 0.5 * nl + 0.5;


	//half diffuseTerm = nl; // tone mapping, 后期需要改的, 如果有这个需求.
	float V = _SmithBeckmannVisibilityTerm(nl, nv, roughness);
	float D = _NDFBlinnPhongNormalizedTerm(nh, _PerceptualRoughnessToSpecPower(perceptualRoughness));

	//float V = _SmithJointGGXVisibilityTerm(nl, nv, roughness);
	//float D = _GGXTerm(nh, roughness);
	half3 F = _FresnelTermEs(specColor, lh);//计算BRDF高光反射项，菲涅尔项F
	float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later

#ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#endif

	specularTerm = max(0, specularTerm * nl);

	//#if defined(_SPECULARHIGHLIGHTS_OFF)
	//	specularTerm = 0.0;
	//#endif

	// surfaceReduction用来修正IBL的反射GGX的修正.
	// surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
	half surfaceReduction;
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]

	// To provide true Lambert lighting, we need to be able to kill specular completely.
	specularTerm *= any(specColor) ? 1.0 : 0.0;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ specularTerm * F * lightColor;
	return color;
}



//-----------------------------------------Anisotropic Functions--------------------------------------------------------------------------------
// Anisotropic GGX
// From HDRenderPipeline
float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
	float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
	return 1.0 / (roughnessT * roughnessB * f * f);
}

// Smith Joint GGX Anisotropic Visibility
// Taken from https://cedec.cesa.or.jp/2015/session/ENG/14698.html
float SmithJointGGXAnisotropic(float TdotV, float BdotV, float NdotV, float TdotL, float BdotL, float NdotL, float roughnessT, float roughnessB)
{
	float aT = roughnessT;
	float aT2 = aT * aT;
	float aB = roughnessB;
	float aB2 = aB * aB;

	float lambdaV = NdotL * sqrt(aT2 * TdotV * TdotV + aB2 * BdotV * BdotV + NdotV * NdotV);
	float lambdaL = NdotV * sqrt(aT2 * TdotL * TdotL + aB2 * BdotL * BdotL + NdotL * NdotL);

	return 0.5 / (lambdaV + lambdaL);
}


// Schlick Fresnel
float FresnelSchlick(float f0, float f90, float u)
{
	float x = 1.0 - u;
	float x5 = x * x;
	x5 = x5 * x5 * x;
	return (f90 - f0) * x5 + f0; // sub mul mul mul sub mad
}

// Convert Anistropy to roughness
void ConvertAnisotropyToRoughness(float roughness, float anisotropy, out float roughnessT, out float roughnessB)
{
	// (0 <= anisotropy <= 1), therefore (0 <= anisoAspect <= 1)
	// The 0.9 factor limits the aspect ratio to 10:1.
	float anisoAspect = sqrt(1.0 - 0.9 * anisotropy);
	roughnessT = roughness / anisoAspect; // Distort along tangent (rougher)
	roughnessB = roughness * anisoAspect; // Straighten along bitangent (smoother)
}

//Clamp roughness
float ClampRoughnessForAnalyticalLights(float roughness)
{
	return max(roughness, 0.000001);
}

inline half GeneralBRDFSpecular(half3 specColor, half lh, half nh, half roughness)
{
	roughness = max(roughness, 0.075);

	half a = roughness;
	float a2 = a * a;
	float d = nh * nh * (a2 - 1.f) + 1.00001f;

#ifdef UNITY_COLORSPACE_GAMMA
	float specularTerm = a / (max(0.32f, lh) * (1.5f + roughness) * d);
#else
	float specularTerm = a2 / (max(0.1f, lh*lh) * (roughness + 0.5f) * (d * d) * 4);
#endif

#if defined (SHADER_API_MOBILE)
	specularTerm = specularTerm - 1e-4f;
#endif

	specularTerm *= any(specColor) ? 1.0 : 0.0;

	return specularTerm;
}

inline half AnisotropicBRDFSpecular(half3 normal, half3 tangent, half3 bitangent, half3 viewDir, half3 lightDir, half3 H, half anisotropy, half roughness)
{
	float shiftAmount = dot(normal, viewDir);
	normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
	//Regular vectors
	float NdotL = saturate(dot(normal, lightDir));
	float NdotV = abs(dot(normal, viewDir));
	float LdotV = dot(lightDir, viewDir);
	float invLenLV = rsqrt(abs(2 + 2 * normalize(LdotV)));
	float NdotH = saturate(dot(normal, H));
	float LdotH = saturate(dot(lightDir, H));
	//Tangent vectors
	float TdotH = dot(tangent, H);
	float TdotL = dot(tangent, lightDir);
	float BdotH = dot(bitangent, H);
	float BdotL = dot(bitangent, lightDir);
	float TdotV = dot(viewDir, tangent);
	float BdotV = dot(viewDir, bitangent);

	float roughnessT;
	float roughnessB;

	ConvertAnisotropyToRoughness(roughness, anisotropy, roughnessT, roughnessB);
	//Clamp roughness
	roughnessT = ClampRoughnessForAnalyticalLights(roughnessT);
	roughnessB = ClampRoughnessForAnalyticalLights(roughnessB);
	//Visibility & Distribution terms
	float V = SmithJointGGXAnisotropic(TdotV, BdotV, NdotV, TdotL, BdotL, NdotL, roughnessT, roughnessB);
	float D = D_GGXAnisotropic(TdotH, BdotH, NdotH, roughnessT, roughnessB);

	//Specular term
	float specularTerm = V * D;

	// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
	specularTerm =min(max(0, specularTerm),2.0);

#	ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#	endif
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
#endif
	return specularTerm;
}

inline half VelvetBRDFSpecular(half nv,half nl, half nh, half roughness)
{
	roughness = max(roughness, 0.075);
	//specular term
	float D = D_Ashikhmin(roughness, nh);
	float V = V_Ashikhmin(nv, nl);
	float specularTerm = V * D;
	#if defined (SHADER_API_MOBILE)
	specularTerm = specularTerm - 1e-4f;
	#endif
	specularTerm = min(max(0.0001, specularTerm),2.0);


	#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
	#endif
	return specularTerm;
}

inline half SkinBRDFSpecular(half3 specColor, half nv, half nl, half nh, half smoothness, half oneMinusReflectivity)
{

	half roughness = 1 - smoothness;
	roughness *= roughness;
	half roughness2 = roughness * roughness;

	half denominator = (nh * nh) * (roughness2 - 1.f) + 1.f;
	half D = roughness2 / (UNITY_PI * denominator * denominator);

	half G_L = nl + sqrt((nl - nl * roughness) * nl + roughness);
	half G_V = nv + sqrt((nv - nv * roughness) * nv + roughness);
	half G = 1.0 / (G_V * G_L);

	half F = 1 - oneMinusReflectivity + (oneMinusReflectivity)* exp2(-8.6562 * nh);

	half specularTerm = D * G * F;
	specularTerm *= any(specColor) ? 1.0 : 0.0;
	specularTerm = min(max(0.0001, specularTerm), 2.0);

	return specularTerm;
}


// Ref: Donald Revie - Implementing Fur Using Deferred Shading (GPU Pro 2)
// The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to the normal.
// The returned normal is NOT normalized.
float3 ComputeGrainNormal(float3 grainDir, float3 V)
{
	float3 B = cross(-V, grainDir);
	return cross(B, grainDir);
}

//Modify Normal for Anisotropic IBL (Realtime version)
// Fake anisotropic by distorting the normal.
// The grain direction (e.g. hair or brush direction) is assumed to be orthogonal to N.
// Anisotropic ratio (0->no isotropic; 1->full anisotropy in tangent direction)
float3 GetAnisotropicModifiedNormal(float3 grainDir, float3 N, float3 V, float anisotropy)
{
	float3 grainNormal = ComputeGrainNormal(grainDir, V);
	// TODO: test whether normalizing 'grainNormal' is worth it.
	return normalize(lerp(N, grainNormal, anisotropy));
}


half3 Es_AnisotropicBRDF_Fast(float3 diffColor, float3 specColor, float oneMinusReflectivity, float smoothness,
	float3 normal, float3 tangent1, float3 tangent2,
	float anisotropyStrength1, float anisotropyStrength2,
	float anisotropyIdensity1, float anisotropyIdensity2,
	float3 viewDir, float3 lightDir, half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	//Normal shift
	float shiftAmount = dot(normal, viewDir);
	normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
	//tangent = ShiftTangent(biNormal, normal, anisotropy);

	//Regular vectors
	float NdotL = saturate(dot(normal, lightDir)) * 0.5 + 0.5;
	float NdotV = abs(dot(normal, viewDir));
	float LdotV = dot(lightDir, viewDir);
	float3 H = Unity_SafeNormalize(lightDir + viewDir);
	//float invLenLV = rsqrt(abs(2 + 2 * normalize(LdotV)));
	//float NdotH = saturate(dot(normal, H));
	float LdotH = saturate(dot(lightDir, H));
	//Tangent vectors
	float TdotH1 = dot(tangent1, H);
	float TdotH2 = dot(tangent2, H);

	//Fresnels
	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	float3 F = FresnelLerp(specColor, grazingTerm, NdotV); //Original Schlick - Replace from SRP?
														   //float3 fresnel0 = lerp(specColor, diffColor, metallic);
														   //float3 F = FresnelSchlick(fresnel0, 1.0, LdotH);
														   //Calculate roughness
	float roughnessT;
	float roughnessB;
	float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
	float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
	//ConvertAnisotropyToRoughness(roughness, anisotropy, roughnessT, roughnessB);
	//Clamp roughness
	//roughnessT = ClampRoughnessForAnalyticalLights(roughnessT);
	//roughnessB = ClampRoughnessForAnalyticalLights(roughnessB);
	//Visibility & Distribution terms
	/*float V = SmithJointGGXAnisotropic(TdotV, BdotV, NdotV, TdotL, BdotL, NdotL, roughnessT, roughnessB);
	float D = D_GGXAnisotropic(TdotH, BdotH, NdotH, roughnessT, roughnessB);*/
	//Specular term
	float3 specularTerm = anisotropyIdensity1 * AnistropicSpecular(TdotH1, anisotropyStrength1) + anisotropyIdensity2 * AnistropicSpecular(TdotH2, anisotropyStrength2);

#	ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#	endif
	// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
	specularTerm = max(0, specularTerm * NdotL);
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
#endif
	//Diffuse term
	float diffuseTerm = DisneyDiffuse(NdotV, NdotL, LdotH, perceptualRoughness) * NdotL;// - Need this NdotL multiply?
																						//Reduction
	half surfaceReduction;
#	ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;		// 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#	else
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);			// fade \in [0.5;1]
#	endif
																	//Final
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ specularTerm * F * lightColor;
	return color;
}

half3 Es_AnisotropicBRDF(float3 diffColor, float3 specColor, float oneMinusReflectivity, float smoothness,
	float3 normal, float3 tangent, float3 bitangent,
	float anisotropy, float3 viewDir,
	float3 lightDir, half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	//Unpack world vectors
	/*float3 tangent = worldVectors[0];
	float3 bitangent = worldVectors[1];*/
	//Normal shift
	float shiftAmount = dot(normal, viewDir);
	normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f) : normal;
	//Regular vectors
	float NdotL = saturate(dot(normal, lightDir));
	float NdotV = abs(dot(normal, viewDir));
	float LdotV = dot(lightDir, viewDir);
	float3 H = Unity_SafeNormalize(lightDir + viewDir);
	float invLenLV = rsqrt(abs(2 + 2 * normalize(LdotV)));
	float NdotH = saturate(dot(normal, H));
	float LdotH = saturate(dot(lightDir, H));
	//Tangent vectors
	float TdotH = dot(tangent, H);
	float TdotL = dot(tangent, lightDir);
	float BdotH = dot(bitangent, H);
	float BdotL = dot(bitangent, lightDir);
	float TdotV = dot(viewDir, tangent);
	float BdotV = dot(viewDir, bitangent);
	//Fresnels
	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
	float3 F = FresnelLerp(specColor, grazingTerm, NdotV); //Original Schlick - Replace from SRP?
														   //float3 fresnel0 = lerp(specColor, diffColor, metallic);
														   //float3 F = FresnelSchlick(fresnel0, 1.0, LdotH);
														   //Calculate roughness
	float roughnessT;
	float roughnessB;
	float perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
	float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
	ConvertAnisotropyToRoughness(roughness, anisotropy, roughnessT, roughnessB);
	//Clamp roughness
	roughnessT = ClampRoughnessForAnalyticalLights(roughnessT);
	roughnessB = ClampRoughnessForAnalyticalLights(roughnessB);
	//Visibility & Distribution terms
	float V = SmithJointGGXAnisotropic(TdotV, BdotV, NdotV, TdotL, BdotL, NdotL, roughnessT, roughnessB);
	float D = D_GGXAnisotropic(TdotH, BdotH, NdotH, roughnessT, roughnessB);
	//Specular term
	float3 specularTerm = V * D;
#	ifdef UNITY_COLORSPACE_GAMMA
	specularTerm = sqrt(max(1e-4h, specularTerm));
#	endif
	// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
	specularTerm = max(0, specularTerm * NdotL);
#if defined(_SPECULARHIGHLIGHTS_OFF)
	specularTerm = 0.0;
#endif
	//Diffuse term
	float diffuseTerm = DisneyDiffuse(NdotV, NdotL, LdotH, perceptualRoughness) * NdotL;// - Need this NdotL multiply?
																						//Reduction
	half surfaceReduction;
#	ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;		// 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#	else
	surfaceReduction = 1.0 / (roughness*roughness + 1.0);			// fade \in [0.5;1]
#	endif
																	//Final
	half3 color = diffColor * (giDiffuse + lightColor * diffuseTerm)
		+ specularTerm * F * lightColor + surfaceReduction * giSpecular * FresnelLerp(specColor, grazingTerm, NdotV);
	return color;
}



half3 Es_BDRF_Velvet(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 viewDir, float3 lightDir,
	half3 lightColor, half3 giDiffuse, half3 giSpecular)
{
	half3 halfDir = normalize((lightDir + viewDir));
	float nl = saturate(dot(normal, lightDir));
	float nh = saturate(dot(normal, halfDir));
	half nv = saturate(dot(normal, viewDir));
	half lh = saturate(dot(lightDir, halfDir));
	half vh = saturate(dot(viewDir, halfDir));

	half perceptualRoughness = 1 - smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;
	roughness = max(roughness, 0.075);

	//diffuse term
	half3 diffuseTerm = nl;

	//specular term
	half D = D_Ashikhmin(roughness, nh);
	half V = V_Ashikhmin(nv, nl);
	half3 F = _SheenColor;
	half specularTerm = V * D;
#if defined (SHADER_API_MOBILE)
	specularTerm = specularTerm - 1e-4f;
#endif
#ifdef UNITY_COLORSPACE_GAMMA
	half surfaceReduction = 0.28;
#else
	half surfaceReduction = (0.6 - 0.08 * perceptualRoughness);
#endif

	surfaceReduction = 1.0 - roughness * perceptualRoughness*surfaceReduction;

	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

	specularTerm *= any(specColor) ? 1.0 : 0.0;
	// diffuse  + gi diffuse + specular + gi specluar + emmision.
	half3 color = (diffColor + specularTerm * F) * lightColor * diffuseTerm + giDiffuse * diffColor
		+ surfaceReduction * giSpecular * FresnelLerpFast(specColor, grazingTerm, nv);
	return color;
}

//-----------------------------------------SKIN Functions--------------------------------------------------------------------------------
//half3 Es_BDRF_SKIN(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
//	float3 normal, float3 viewDir, float3 lightDir,
//	half3 lightColor, half3 giDiffuse, half3 giSpecular,
//	half4 sssTex)
//{
//	half curvature = sssTex.g * _SkinCurvatureScale;
//	half thickness = 1 - sssTex.r;
//	thickness *= _SkinThicknessScale;
//
//#define oneMinusRoughness smoothness
//#define Pi 3.14159265358979323846
//#define OneOnLN2_x6 8.656170
//
//	half dotNL = max(0, dot(normal, lightDir));
//
//	half dotNV = max(0, dot(normal, viewDir)); // UNITY BRDF does not normalize(viewDir) ) );
//	half3 halfDir = normalize(lightDir + viewDir);
//	half dotNH = max(0, dot(normal, halfDir));
//	half dotLH = max(0, dot(lightDir, halfDir));
//
//	//	////////////////////////////////////////////////////////////
//	//	Cook Torrrance
//	//	from The Order 1886 // http://blog.selfshadow.com/publications/s2013-shading-course/rad/s2013_pbs_rad_notes.pdf
//	half alpha = 1 - smoothness; // alpha is roughness
//	alpha *= alpha;
//	half alpha2 = alpha * alpha;
//
//	//	Specular Normal Distribution Function: GGX Trowbridge Reitz
//	half denominator = (dotNH * dotNH) * (alpha2 - 1.f) + 1.f;
//	half D = alpha2 / (Pi * denominator * denominator);
//	//	Geometric Shadowing: Smith
//		// B. Karis, http://graphicrants.blogspot.se/2013/08/specular-brdf-reference.html
//	half G_L = dotNL + sqrt((dotNL - dotNL * alpha) * dotNL + alpha);
//	half G_V = dotNV + sqrt((dotNV - dotNV * alpha) * dotNV + alpha);
//	half G = 1.0 / (G_V * G_L);
//	//	Fresnel: Schlick / fast fresnel approximation
//	half F = 1 - oneMinusReflectivity + (oneMinusReflectivity)* exp2(-OneOnLN2_x6 * dotNH);
//	// half3 FresnelSchlickWithRoughness = s.Specular + ( max(s.Specular, oneMinusRoughness) - s.Specular) * exp2(-OneOnLN2_x6 * dotNV );
//
//	//	Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II", changed by EPIC
//	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
//	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
//	half4 r = (1 - oneMinusRoughness) * c0 + c1;
//	half a004 = min(r.x * r.x, exp2(-9.28 * dotNV)) * r.x + r.y;
//	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
//	half3 F_L = specColor * AB.x + AB.y;
//
//	//	Skin Lighting
//	half2 brdfUV;
//	// Half-Lambert lighting value based on blurred normals.
//	brdfUV.x = dotNL * 0.5 + 0.5;
//
//	// Curvature amount. Multiplied by light's luminosity so brighter light = more scattering.
//	// Pleae note: gi.light.color already contains light attenuation
//	brdfUV.y = curvature * max(0, dot(lightColor, fixed3(0.22, 0.707, 0.071)));
//	half3 brdf = tex2D(_SkinBRDFLut, brdfUV).rgb;
//	//	Translucency
//	float3 H = normalize(lightDir + normal * _SkinDistortion);
//	float transDot = pow(saturate(dot(-viewDir, H)), _SkinPower) * (1 - thickness);
//
//	half3 lightScattering = transDot * _SkinSubColor;
//	//	Final composition
//	half3 c = diffColor * lightColor * lerp(dotNL.xxx, brdf, thickness) // diffuse
//		+ giDiffuse * diffColor
//		+ lightScattering
//		+ D * G * F * lightColor * dotNL // direct specular
//		+ giSpecular * F_L; // * FresnelSchlickWithRoughness;						// indirect specular
//	return c;
//}

//Anisotropy + Iridesence
half3 Es_BDRF_Avatar(half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
	float3 normal, float3 tangent, float3 bitangent,
	float3 viewDir, float3 lightDir,
	half3 lightColor, half3 giDiffuse, half3 giSpecular,
	sampler2D skinBRDFLut,
	sampler2D skinSSSTex,	//R:thickness G:curvature
	half skinCurvatureScale,
	half skinThicknessScale,
	half3 skinSubColor,
	half  skinPower,
	half  skinDistortion,
	half2 mainTexcoord)
{
	//fabric normal
	fixed4 fabricMap = tex2D(_FabricMap, _FabricMircoScale * mainTexcoord);
	half3 fabricMircoNormal = _UnpackScaledNormal(fabricMap.xyz, _FabricMicroBumpScale);

	fabricMircoNormal = WorldSpaceNormalFromTangentSpace(tangent, bitangent, normal, fabricMircoNormal);
	fabricMircoNormal.xyz = normalize(fabricMircoNormal + normal);
	half3 halfDir = Unity_SafeNormalize(lightDir + viewDir);
	float nl = saturate(dot(normal, lightDir));
	float nlMicro = saturate(dot(fabricMircoNormal, lightDir));

	float nh = saturate(dot(normal, halfDir));
	float nhMicro = saturate(dot(fabricMircoNormal, halfDir));

	half nv = saturate(dot(normal, viewDir));
	half nvMicro = saturate(dot(fabricMircoNormal, viewDir));

	half lh = saturate(dot(lightDir, halfDir));

	half4 blendFactors = tex2D(_ShadeBlendMap, mainTexcoord);

	half anisotropyFactor = blendFactors.r;		//各向异性
	half velvetFactor = blendFactors.g;			//布料
	half skinFactor = blendFactors.b;			//皮肤
	half iridescenceFactor = blendFactors.a;	//彩虹色

	//diffuseTerm
	half diffuseTerm = nl;

	//skin diffuseTerm
	fixed4 sss = tex2D(skinSSSTex, mainTexcoord);
	fixed curve = sss.g  * skinCurvatureScale;
	fixed thickness = sss.r * skinThicknessScale;
	fixed2 skinUV;
	skinUV.x = nl * 0.5 + 0.5;
	//skinUV.y = curve;
	skinUV.y = curve * dot(lightColor, fixed3(0.22, 0.707, 0.071));
	fixed3 sssColor = tex2D(skinBRDFLut, skinUV);
	half3 sssDiffuseTerm = lerp(sssColor, nl.rrr, thickness);
	sssDiffuseTerm = lerp(nl.rrr, sssDiffuseTerm, skinFactor);

	//	Translucency
	float3 H = normalize(lightDir + normal * skinDistortion);
	float transDot = pow(saturate(dot(-viewDir, H)), skinPower) * (1 - thickness);
	half3 lightScattering = transDot * skinSubColor;


	half perceptualRoughness = 1 - smoothness;
	half roughness = perceptualRoughness * perceptualRoughness;

	//general BRDF specular
	half generalSpecularTerm = GeneralBRDFSpecular(specColor, lh, nh, roughness);

	//anisotropy BRDF specular
	half anisotropicSpecularTerm = AnisotropicBRDFSpecular(normal, tangent, bitangent, viewDir, lightDir, halfDir, anisotropyFactor, roughness);

	//cloth BRDF specular
	half velvetBRDFSpecularTerm = VelvetBRDFSpecular(nvMicro, nlMicro, nhMicro, roughness);

	//skin BRDF specular 
	float skinBRDFSpecularTerm = SkinBRDFSpecular(specColor, nv, nl, nh, smoothness, oneMinusReflectivity);

	//specularTerm lerp

	half specularTerm = lerp(generalSpecularTerm, anisotropicSpecularTerm, anisotropyFactor);

	half finalSpecularTerm = lerp(specularTerm, velvetBRDFSpecularTerm, velvetFactor);

	finalSpecularTerm = lerp(finalSpecularTerm, skinBRDFSpecularTerm, skinFactor);

	//lerp Iridescene Specular Color
	half fresnel = saturate(1 - pow(1 - nv, _RainbowPower)) * _RainbowIntensity;

	half3 iridesceneColor = tex2D(_RainbowTex, half2(fresnel, 0.5)) * _IridesenceIntensity;

	iridesceneColor *= _AnisotropicColor.rgb;

	half3 blendIridesenceSpecColor = lerp(specColor, iridesceneColor, _AnisotropicColor.a *  iridescenceFactor);

	//lerp cloth specular
	half3 blendSpecColor = lerp(blendIridesenceSpecColor, _SheenColor, velvetFactor);

	//grazingTerm
	half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));

	//fresnel color
	half3 fresnelGISpecular = 0;
	//------------------skin fresnel
	const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
	const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
	half4 r = (1 - smoothness) * c0 + c1;
	half a004 = min(r.x * r.x, exp2(-9.28 * nv)) * r.x + r.y;
	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
	half3 F_L = specColor * AB.x + AB.y;
	half3 skinFresnelGISpecular = giSpecular * F_L;
	//-------------------------------

	//------------------------------general fresnel
	#ifdef UNITY_COLORSPACE_GAMMA
		half surfaceReduction = 0.28;
	#else
		half surfaceReduction = (0.6 - 0.08 * perceptualRoughness);
	#endif

	surfaceReduction = 1.0 - roughness * perceptualRoughness*surfaceReduction;

	half3 generalFresnelGISpecular = surfaceReduction * giSpecular * FresnelLerpFast(specColor, grazingTerm, nv);
	//------------------------------------------------------

	fresnelGISpecular = lerp(generalFresnelGISpecular, skinFresnelGISpecular,skinFactor);

	half3 color = diffColor * lightColor * sssDiffuseTerm
		+ finalSpecularTerm * blendSpecColor * lightColor * diffuseTerm
		+ giDiffuse * diffColor
		+ lerp(fixed3(0, 0, 0), lightScattering, skinFactor)
		+ fresnelGISpecular;

	return color;
}



#endif