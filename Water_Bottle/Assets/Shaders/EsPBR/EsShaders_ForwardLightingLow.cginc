v2fBase vertBaseLow (appdata v)
{
	v2fBase o;
	UNITY_INITIALIZE_OUTPUT(v2fBase,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

#ifdef _LIGHT_FLOW_ON
	o.texcoord.zw = step(1, _LightFlowMode) ? v.vertex.xz : v.vertex.yz;
#endif
	o.worldNormal = UnityObjectToWorldNormal(v.normal);

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;
	o.ambientOrLightmapUV = VertexGI(v.texcoord1, o.worldPos, o.worldNormal);

	o.screenPos = ComputeScreenPos(o.pos);
#if _REFLECTION_MATCAP
	//o.NtoV.x = mul(UNITY_MATRIX_IT_MV[0], v.normal);
	//o.NtoV.y = mul(UNITY_MATRIX_IT_MV[1], v.normal);
#endif
	//We need this for shadow receiving and lighting
	UNITY_TRANSFER_LIGHTING(o, v.texcoord1);
	//填充雾效所需要的参数，定义在UnityCG.cginc
	//UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

fixed4 fragBaseLow (v2fBase i) : SV_Target
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

	half occlusion = _Occlusion;
	half3 emission = mainColor.rgb * _EmissionColor;//自发光颜色

	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);

	float3 worldNormal = normalize(i.worldNormal);
	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);

	half shadowStrenth = _RealtimeShadowColor.a * _LightShadowData.r;
	float3 coloredAtten = (1 - lightAtten) * (_RealtimeShadowColor.rgb - 1) + 1;

	half3 specColor = 0.15;//lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	//计算漫反射率
	half3 diffColor = albedo;
	half3 lightColor = _LightColor0 * coloredAtten;
	half smoothness = _Smoothness;
	emission = EmissionSetup(emission, i.texcoord, worldNormal, worldViewDir, worldLightDir, lightColor, worldPos);
	fixed refelctionAlpha = 1;

	//计算间接光
	half3 giDiffuse = ShadeSHPerPixel(worldNormal, i.ambientOrLightmapUV.rgb, worldPos);//计算间接光漫反射.
	half3 color = 0;
	half nl = saturate(dot(worldLightDir, worldNormal));
	float3 halfDir = normalize(worldLightDir + worldViewDir);
	half nh = saturate(dot(worldNormal, halfDir));
	fixed3 specular = lightColor.rgb * specColor.rgb * pow(nh, max(8, smoothness / 0.1));

	color = diffColor * lightColor * nl + specular + albedo * giDiffuse;
	return half4(color, alpha);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
v2fAdd vertAddLow (appdata v)
{
	v2fAdd o;
	UNITY_INITIALIZE_OUTPUT(v2fAdd,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

	o.worldNormal = UnityObjectToWorldNormal(v.normal);

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;

	o.screenPos = ComputeScreenPos(o.pos);
	
	//TRANSFER_SHADOW(o);
	return o;
}

fixed4 fragAddLow (v2fAdd i) : SV_Target
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
	alpha *= smoothstep(_FadeCircleRadius, _FadeCircleRadius + CircleFadeFallOff, distanceToCenter);
#endif

	fixed3 albedo = i.color.rgb * mainColor.rgb * _Color.rgb;
	//fixed4 anisotropicRampTex = tex2D(_AnisotropicRampTex, i.texcoord.zw);

	half metallic = _Metallic;
	half smoothness = _Smoothness;

	half occlusion = 1 - _Occlusion;
	half3 emission = mainColor.rgb * _EmissionColor;//自发光颜色


	float3 worldPos = i.worldPos;
	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

	float3 worldNormal = normalize(i.worldNormal);

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);
	
	//lightAtten = (lightAtten - shadowStrenth) + shadowStrenth;
	float3 coloredAtten = (1 - lightAtten) * (_ShadowColor.rgb - 1) + 1;
	// 非金属的F0 = 0.04
	// 注意： 如果是用Specular流程的，这里的话要考虑EnergyConservationBetweenDiffuseAndSpecular，也就是monochrome到specular颜色的混合.
	half3 specColor = 0.15;//lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	//1 - 反射率,漫反射总比率
	half oneMinusReflectivity = (1 - metallic) * unity_ColorSpaceDielectricSpec.a;
	//计算漫反射率
	half3 diffColor = albedo * oneMinusReflectivity;
	half3 lightColor = _LightColor0 * coloredAtten;

	//BlinnPhong
	half3 color = 0;
	half nl = saturate(dot(worldLightDir, worldNormal));
	float3 halfDir = normalize(worldLightDir + worldViewDir);
	half nh = saturate(dot(worldNormal, halfDir));
	fixed3 specular = lightColor.rgb * specColor.rgb * pow(nh, max(8, smoothness / 0.1));
	color = diffColor * lightColor * nl + specular;
	//half3 color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, 0, 0);
	return half4(color, alpha);
}


