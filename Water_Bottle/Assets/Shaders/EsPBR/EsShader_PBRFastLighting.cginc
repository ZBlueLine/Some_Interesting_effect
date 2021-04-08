#include "../EsPBR/EsShaders_BRDFHelper.cginc"
#include "../EsPBR/EsShaders_BRDF.cginc"


fixed4 LightingForwardBase(fixed4 color, float4 mainTexcoord, float3 worldPos, float3 worldNormal, float3 worldTangent, float3 worldBinormal, float4 ambientOrLightmapUV, float lightAtten)
{
	fixed4 mainColor = tex2D(_MainTex, mainTexcoord);
	fixed alpha = color.a * mainColor.a * _Color.a;

#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif

	fixed3 baseColor = mainColor.rgb;
	fixed3 albedo = color.rgb * baseColor * _Color.rgb;

	float3 vertexWorldNormal = normalize(worldNormal);

	fixed4 pbrInfo = tex2D(_PBRMap, mainTexcoord);
	half metallic = pbrInfo.r * _Metallic;
	half smoothness = pbrInfo.g * _Smoothness;
	half occlusion = _LerpOneTo(pbrInfo.a, _Occlusion);
	half3 emission = mainColor.rgb * _EmissionColor * pbrInfo.b;//自发光颜色

	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);

	//如果定义了细节法线，需要lerp
	worldNormal = normalize(worldNormal);
	worldBinormal = normalize(worldBinormal);
	worldTangent = normalize(worldTangent);

	float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, mainTexcoord), _BumpScale);
	normal = normalize(normal);

	worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);
	worldNormal = normalize(worldNormal);

	half3 refDir = reflect(-worldViewDir, worldNormal);


	// unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) 
	// standard dielectric reflectivity coef at incident angle (= 4%)
	// 非金属的F0 = 0.04
	// 注意： 如果是用Specular流程的，这里的话要考虑EnergyConservationBetweenDiffuseAndSpecular，也就是monochrome到specular颜色的混合.
	half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);

	//1 - 反射率,漫反射总比率
	half oneMinusReflectivity = (1 - metallic) * unity_ColorSpaceDielectricSpec.a;
	//计算漫反射率
	half3 diffColor = albedo * oneMinusReflectivity;
	half3 lightColor = _LightColor0 * lightAtten;

	half perceptualRoughness = 1 - smoothness;
	emission = EmissionSetup(emission * albedo, mainTexcoord, worldNormal, worldViewDir, worldLightDir, lightColor, worldPos);
	fixed refelctionAlpha = 1;
	//计算间接光
	half3 giDiffuse = IndirectDiffuse(ambientOrLightmapUV, worldNormal, worldPos, occlusion, lightColor);//计算间接光漫反射.
#ifdef _REFLECTION_OFF
	half3 giSpecular = 0;
#else
	half3 giSpecular = GISpecular(refDir, worldPos, perceptualRoughness, occlusion);//计算间接光镜面反射，后面可以的话，调成cubemap或matcap.
#endif

	half3 finalColor = 0;
	finalColor = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular);
	finalColor += emission;	
	return half4(finalColor, alpha);
}