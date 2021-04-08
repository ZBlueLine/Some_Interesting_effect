v2fBase vertBase (appdata v)
{
	v2fBase o;
	UNITY_INITIALIZE_OUTPUT(v2fBase,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	//o.texcoord.zw = TRANSFORM_TEX(v.texcoord, _AnisotropicRampTex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);

#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
	o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.worldBinormal = cross(o.worldNormal, o.worldTangent) * tangentSign;
	v.normal.w = 0.0f;
	#if _DETAIL_ENABLE
	o.texcoord1.xy = TRANSFORM_TEX(v.texcoord, _DetailAlbedo);
	#endif
#endif

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;
	o.ambientOrLightmapUV = VertexGI(v.texcoord1, o.worldPos, o.worldNormal);

	o.screenPos = ComputeScreenPos(o.pos);
	//#if _REFLECTION_MATCAP
	////采样修正
	//o.NtoV.x = mul(UNITY_MATRIX_IT_MV[0], v.normal);
	//o.NtoV.y = mul(UNITY_MATRIX_IT_MV[1], v.normal);
	//#endif
	//We need this for shadow receiving and lighting
	UNITY_TRANSFER_LIGHTING(o, v.texcoord1);
	//填充雾效所需要的参数，定义在UnityCG.cginc
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

fixed4 fragBase (v2fBase i) : SV_Target
{
	float3 worldPos = i.worldPos;

	float2 mainTexcoord = i.texcoord.xy;
#if _ALBEDO_BY_WORLD_MAPPING
	mainTexcoord = 0.05 * worldPos.xz * _MainWorldUVTilling.xy + _MainWorldUVTilling.zw;
#endif

	fixed4 mainColor = tex2D(_MainTex, mainTexcoord);

	fixed alpha = i.color.a * mainColor.a * _Color.a;

#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif

#if _FADECIRCLE_ON
	half2 clipPos = i.screenPos.xy / i.screenPos.w;				
	float distanceToCenter = distance(clipPos, half2(0.5, 0.5));				
	alpha *= smoothstep(_FadeCircleRadius, _FadeCircleRadius + CircleFadeFallOff, distanceToCenter);
#endif

	fixed3 baseColor = mainColor.rgb;
	
	fixed3 albedo = i.color.rgb * baseColor * _Color.rgb;

#if _PBRMAP
	fixed4 pbrInfo = tex2D(_PBRMap, mainTexcoord);
	half metallic = pbrInfo.r * _Metallic;
	half smoothness = pbrInfo.g * _Smoothness;
	half occlusion = _LerpOneTo(pbrInfo.a, _Occlusion);

	half3 emission = lerp(_HintHighlighColor * _HintHighlightIdensity * lerpPingpong(_Time.y * _HintHighlightSpeed), _EmissionColor * pbrInfo.b, step(_HintHighlightOn, 0));//自发光颜色
#else
	half metallic = _Metallic;
	half smoothness = _Smoothness;

	half occlusion = _Occlusion;
	half3 emission = _HintHighlighColor * lerp(_HintHighlightIdensity * lerpPingpong(_Time.y * _HintHighlightSpeed), 0, step(_HintHighlightOn, 0));//自发光颜色
#endif

	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);

	//如果定义了细节法线，需要lerp
#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
		float3 worldNormal = normalize(i.worldNormal);
		float3 worldBinormal = normalize(i.worldBinormal);
		float3 worldTangent = normalize(i.worldTangent);

		float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, mainTexcoord), _BumpScale);
		normal = normalize(normal);
			
		float3 blendNormal = normal;
	#if _DETAIL_ENABLE && _DETAIL_NORMAL
		#if _DETAIL_BY_WORLD_MAPPING
			half3 detailNormal = _UnpackScaledNormal(tex2D(_DetailNormalMap, worldUV), _DetailNormalScale);
		#else
			half3 detailNormal = _UnpackScaledNormal(tex2D(_DetailNormalMap, i.texcoord1.xy), _DetailNormalScale);
		#endif
		#if _DETAIL_BLEND_LERP
			blendNormal = lerp(normal, detailNormal, detailAlbedo.a);
		#else
			blendNormal = lerp(normal, BlendNormals(normal, detailNormal), detailAlbedo.a);
		#endif
	#endif
		normal = normalize(blendNormal);
		worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);
		worldNormal = normalize(worldNormal);
	#if _BRDF_FABRIC
			float3 fabricMircoNormal = _UnpackScaledNormal(tex2D(_FabricMap, _FabricMircoScale * mainTexcoord), _FabricMicroBumpScale);
			fabricMircoNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, normalize(i.worldNormal), fabricMircoNormal);
			fabricMircoNormal = normalize(fabricMircoNormal);
			worldNormal = normalize(worldNormal + fabricMircoNormal);
	#endif

#else
	#if _BRDF_FABRIC
		fixed4 fabricMap = tex2D(_FabricMap, _FabricMircoScale * mainTexcoord);
		occlusion *= fabricMap.a;
		occlusion = saturate(occlusion);

		half3 fabricMircoNormal = _UnpackScaledNormal(fabricMap.xyz, _FabricMicroBumpScale);
		fabricMircoNormal = normalize(WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, fabricMircoNormal));
		worldNormal = normalize(worldNormal + i.worldNormal);
	#endif
		float3 worldNormal = normalize(i.worldNormal);
#endif

	half perceptualRoughness = 1 - smoothness;

	half3 refDir = reflect(-worldViewDir, worldNormal);
#if _BRDF_FABRIC
	float roughnessT;
	float roughnessB;
	ConvertValueAnisotropyToValueTB(perceptualRoughness, _Anisotropy, roughnessT, roughnessB);
	refDir = GetAnisotropyReflectionDir(-worldViewDir, worldBinormal, worldNormal, _Anisotropy);
#endif

	/*float3 worldBitangent1 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic1 * anisotropicRampTex.r);
	float3 worldBitangent2 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic2 * anisotropicRampTex.r);*/

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);
	//lightAtten = ApplyMicroSoftShadow(occlusion, worldNormal, worldLightDir, lightAtten);

	//计算间接光
	half shadowStrenth = _RealtimeShadowColor.a * _LightShadowData.r;
	float3 coloredAtten = (1 - lightAtten) * (_RealtimeShadowColor.rgb - 1) + 1;
	half3 lightColor = _LightColor0 * coloredAtten;
	half3 giDiffuse = IndirectDiffuse(i.ambientOrLightmapUV, worldNormal, worldPos, occlusion, lightColor);//计算间接光漫反射.

	
	// unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) 
	// standard dielectric reflectivity coef at incident angle (= 4%)
	// 非金属的F0 = 0.04
	// 注意： 如果是用Specular流程的，这里的话要考虑EnergyConservationBetweenDiffuseAndSpecular，也就是monochrome到specular颜色的混合.
	half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);

	//1 - 反射率,漫反射总比率
	half oneMinusReflectivity = (1- metallic) * unity_ColorSpaceDielectricSpec.a;
	//计算漫反射率
	half3 diffColor = albedo * oneMinusReflectivity;

	emission = EmissionSetup(emission, i.texcoord, worldNormal, worldViewDir, worldLightDir, lightColor, worldPos);

	fixed refelctionAlpha = 1;
	
	half3 giSpecular;//计算间接光镜面反射，后面可以的话，调成cubemap或matcap
#if _DEFAULT_PROBE_REFLECTION 
	giSpecular = GISpecular(refDir, worldPos, perceptualRoughness, occlusion);//计算间接光镜面反射，后面可以的话，调成cubemap或matcap.
#elif _PLANAR_REFLECTION
	giSpecular = GISpecular_PlanarRt(UNITY_PROJ_COORD(i.screenPos), perceptualRoughness, normal, occlusion, _ReflectionGamma, refelctionAlpha);
	giSpecular *= _ReflectionFactor * refelctionAlpha;
#elif _REFLECTION_BLEND
	giSpecular = GISpecular_PlanarRt(UNITY_PROJ_COORD(i.screenPos), perceptualRoughness, normal, occlusion, _ReflectionGamma, refelctionAlpha);
	giSpecular = lerp(GISpecular(refDir, worldPos, perceptualRoughness, occlusion), giSpecular, refelctionAlpha * _ReflectionBlendFactor);
#elif _REFLECTION_MULTIPLE
	giSpecular = _ReflectionFactor * GISpecular_PlanarRt(UNITY_PROJ_COORD(i.screenPos), perceptualRoughness, normal, occlusion, _ReflectionGamma, refelctionAlpha);
	half3 colorNoGI = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, 0);
	colorNoGI.rgb = colorNoGI.rgb * giSpecular * _ReflectionBlendFactor + (1 - any(giSpecular.rgb)) * GISpecular(refDir, worldPos, perceptualRoughness, occlusion);
	colorNoGI += emission;
	return half4(colorNoGI, alpha);
#elif _REFLECTION_ADD
	giSpecular = _ReflectionFactor * GISpecular_PlanarRt(UNITY_PROJ_COORD(i.screenPos), perceptualRoughness, normal, occlusion, _ReflectionGamma, refelctionAlpha);
	half3 colorNoGI = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, 0);
	colorNoGI.rgb = colorNoGI.rgb + giSpecular;
	colorNoGI += emission;
	return half4(colorNoGI, alpha);
#elif _REFLECTION_OFF
	giSpecular = _ReflectionColor;
#else
	//combine
	giSpecular = GISpecular(refDir, worldPos, perceptualRoughness, occlusion) + _ReflectionFactor * GISpecular_PlanarRt(UNITY_PROJ_COORD(i.screenPos), perceptualRoughness, worldNormal, occlusion, _ReflectionGamma, refelctionAlpha);
#endif
	half3 color = 0;
	//#ifdef _BRDF_SKIN
	//				fixed4 sss = tex2D(_SkinSSSTex, i.texcoord.xy);
	//				color = Es_BDRF_SKIN(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular, sss);
#if _BRDF_FABRIC
	if(_FabricType == 0)
		color = Es_BDRF_Fabric_Cotton(diffColor, specColor, _FuzzColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular);
	else
		color = Es_BDRF_Fabric_Silk(diffColor, specColor, _FuzzColor, oneMinusReflectivity, perceptualRoughness, roughnessT, roughnessB, worldNormal, worldTangent, worldBinormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular);
#else
	color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular);
#endif
	color += emission;
	//color = RimSetup(color, worldNormal, worldViewDir);
	UNITY_APPLY_FOG(i.fogCoord, color);
	return half4(color, alpha);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
v2fAdd vertAdd (appdata v)
{
	v2fAdd o;
	UNITY_INITIALIZE_OUTPUT(v2fAdd,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	//o.texcoord.zw = TRANSFORM_TEX(v.texcoord, _AnisotropicRampTex);

	o.worldNormal = UnityObjectToWorldNormal(v.normal);
#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
	o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.worldBinormal = cross(o.worldNormal, o.worldTangent) * tangentSign;
	v.normal.w = 0.0f;
#endif
	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;

	o.screenPos = ComputeScreenPos(o.pos);
	TRANSFER_SHADOW(o);
	return o;
}

fixed4 fragAdd (v2fAdd i) : SV_Target
{
	float2 mainTexcoord = i.texcoord.xy;

	fixed4 mainColor = tex2D(_MainTex, mainTexcoord);
	fixed alpha = i.color.a * mainColor.a * _Color.a;
#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif

#if _FADECIRCLE_ON
	half2 clipPos = i.screenPos.xy / i.screenPos.w;
	float distanceToCenter = distance(clipPos, half2(0.5, 0.5));
	//alpha *= max(_MinFadeCircleAlpha, smoothstep(_FadeCircleRadius, _FadeCircleRadius + CircleFadeFallOff, distanceToCenter));								
	alpha *= smoothstep(_FadeCircleRadius, _FadeCircleRadius + CircleFadeFallOff, distanceToCenter);
#endif

	fixed3 albedo = i.color.rgb * mainColor.rgb * _Color.rgb;
	//fixed4 anisotropicRampTex = tex2D(_AnisotropicRampTex, i.texcoord.zw);

#if _PBRMAP
	fixed4 pbrInfo = tex2D(_PBRMap, mainTexcoord);
	half metallic = pbrInfo.r * _Metallic;
	half smoothness = pbrInfo.g * _Smoothness;
	half occlusion = _LerpOneTo(pbrInfo.a, _Occlusion);
	half3 emission = mainColor.rgb * _EmissionColor * pbrInfo.b;//自发光颜色
#else
	half metallic = _Metallic;
	half smoothness = _Smoothness;

	half occlusion = 1 - _Occlusion;
	half3 emission = mainColor.rgb * _EmissionColor;//自发光颜色
#endif

	float3 worldPos = i.worldPos;
	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

#if defined(_NORMALMAP) || defined(_BRDF_FABRIC)
	float3 worldNormal = normalize(i.worldNormal);
	float3 worldBinormal = normalize(i.worldBinormal);
	float3 worldTangent = normalize(i.worldTangent);

	float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, mainTexcoord), _BumpScale);
	normal = normalize(normal);
	worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);

#if _BRDF_FABRIC
	fixed4 fabricMap = tex2D(_FabricMap, _FabricMircoScale * mainTexcoord);
	half3 fabricMircoNormal = _UnpackScaledNormal(fabricMap.xyz, _FabricMicroBumpScale);
	fabricMircoNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, fabricMircoNormal);
	normal.xyz = normalize(fabricMircoNormal + normal);
#endif

#else
	float3 worldNormal = normalize(i.worldNormal);
#if _BRDF_FABRIC
	fixed4 fabricMap = tex2D(_FabricMap, _FabricMircoScale * mainTexcoord);
	half3 fabricMircoNormal = _UnpackScaledNormal(fabricMap.xyz, _FabricMicroBumpScale);
	fabricMircoNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, fabricMircoNormal);
	normal.xyz = normalize(fabricMircoNormal + normal);	
#endif

#endif

	half perceptualRoughness = 1 - smoothness;

#if _BRDF_FABRIC
	float roughnessT;
	float roughnessB;
	ConvertValueAnisotropyToValueTB(perceptualRoughness, _Anisotropy, roughnessT, roughnessB);
#endif

	half3 refDir = reflect(-worldViewDir, worldNormal);
	/*float3 worldBitangent1 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic1 * anisotropicRampTex.r);
	float3 worldBitangent2 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic2 * anisotropicRampTex.r);*/

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);
	//lightAtten = ApplyMicroSoftShadow(occlusion, worldNormal, worldLightDir, lightAtten);
	half shadowStrenth = _ShadowColor.a * _LightShadowData.r;
	//lightAtten = (lightAtten - shadowStrenth) + shadowStrenth;
	float3 coloredAtten = (1 - lightAtten) * (_ShadowColor.rgb - 1) + 1;
	// unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) 
	// standard dielectric reflectivity coef at incident angle (= 4%)
	// 非金属的F0 = 0.04
	// 注意： 如果是用Specular流程的，这里的话要考虑EnergyConservationBetweenDiffuseAndSpecular，也就是monochrome到specular颜色的混合.
	half3 specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	//1 - 反射率,漫反射总比率
	half oneMinusReflectivity = (1 - metallic) * unity_ColorSpaceDielectricSpec.a;
	//计算漫反射率
	half3 diffColor = albedo * oneMinusReflectivity;
	half3 lightColor = _LightColor0 * coloredAtten;

	//计算间接光
	half3 color = 0;
#if _BRDF_FABRIC
	if (_FabricType == 0)
		color = Es_BDRF_Fabric_Cotton(diffColor, specColor, _FuzzColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, 0, 0);
	else
		color = Es_BDRF_Fabric_Silk(diffColor, specColor, _FuzzColor, oneMinusReflectivity, smoothness, roughnessT, roughnessB, worldNormal, worldTangent, worldBinormal, worldViewDir, worldLightDir, lightColor, 0, 0);
#else
	color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, 0, 0);
#endif
	return half4(color, alpha);
}


