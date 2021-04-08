v2fBase vertBase (appdata v)
{
	v2fBase o;
	UNITY_INITIALIZE_OUTPUT(v2fBase,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);

#if defined(_NORMALMAP) 
	o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.worldBinormal = cross(o.worldNormal, o.worldTangent) * tangentSign;
#endif

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;
	o.ambientOrLightmapUV = VertexGI_SH(v.texcoord1, o.worldPos, o.worldNormal);

	//o.screenPos = ComputeScreenPos(o.pos);
	#if _REFLECTION_MATCAP
	//采样修正
	//float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
	//float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);
	//float3 objectViewDir = mul(unity_WorldToObject, float4(worldViewDir, 0));

	o.NtoV.x = mul(UNITY_MATRIX_IT_MV[0], v.normal);
	o.NtoV.y = mul(UNITY_MATRIX_IT_MV[1], v.normal);
	//o.refViewDir = mul(UNITY_MATRIX_MV, float4(objectViewDir, 0)).xyz;
	#endif
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
	fixed4 mainColor = tex2D(_MainTex, mainTexcoord);
	fixed alpha = i.color.a * mainColor.a * _Color.a;

#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
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
#if defined(_NORMALMAP) 
		float3 worldNormal = normalize(i.worldNormal);
		float3 worldBinormal = normalize(i.worldBinormal);
		float3 worldTangent = normalize(i.worldTangent);

		float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, mainTexcoord), _BumpScale);
		normal = normalize(normal);
		worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);
#else
		float3 worldNormal = normalize(i.worldNormal);
#endif

	half perceptualRoughness = 1 - smoothness;

	half3 refDir = reflect(-worldViewDir, worldNormal);

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);
	//lightAtten = ApplyMicroSoftShadow(occlusion, worldNormal, worldLightDir, lightAtten);

	//计算间接光
	half3 lightColor = _LightColor0 * lightAtten;
	half3 giDiffuse = _GIFade * IndirectDiffuse(i.ambientOrLightmapUV, worldNormal, worldPos, occlusion);
	
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

	half3 giSpecular = 0;
#if _DEFAULT_PROBE_REFLECTION 
	giSpecular = _GIFade * GISpecular(refDir, worldPos, perceptualRoughness, occlusion);
#elif _REFLECTION_MATCAP
	half lod = perceptualRoughness * 6;
	lod = lod > 5.0 ? 5 : lod;
	//采样修正
	//half2 refLightDir = reflect(-i.refViewDir, worldNormal).xy;
	//half2 normalDir = i.NtoV;
	//float curvature = saturate(length(fwidth(worldNormal)) / length(fwidth(worldPos)) * 1);
	//half2 uv = lerp(refLightDir, normalDir, curvature);
	//giSpecular = tex2Dlod(_MatCapTex, float4(uv * 0.5 + 0.5/*i.NtoV.xy * 0.5 + 0.5*/, 0, lod));
	giSpecular = tex2Dlod(_Global_Matcap_Reflection, float4(i.NtoV.xy * 0.5 + 0.5, 0, lod));
#elif _REFLECTION_OFF
	giSpecular = _ReflectionColor;
#endif

	half3 color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular);
	color += emission;
	color = RimSetup(color, worldNormal, worldViewDir);
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

	//o.screenPos = ComputeScreenPos(o.pos);
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

	fixed3 albedo = i.color.rgb * mainColor.rgb * _Color.rgb;
	//fixed4 anisotropicRampTex = tex2D(_AnisotropicRampTex, i.texcoord.zw);

	float3 vertexWorldNormal = normalize(i.worldNormal);

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

#if defined(_NORMALMAP) 
	float3 worldNormal = normalize(i.worldNormal);
	float3 worldBinormal = normalize(i.worldBinormal);
	float3 worldTangent = normalize(i.worldTangent);

	float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, mainTexcoord), _BumpScale);
	normal = normalize(normal);
	worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);
	worldNormal = normalize(worldNormal);
#else
	float3 worldNormal = normalize(i.worldNormal);
#endif

	half perceptualRoughness = 1 - smoothness;

	half3 refDir = reflect(-worldViewDir, worldNormal);
	/*float3 worldBitangent1 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic1 * anisotropicRampTex.r);
	float3 worldBitangent2 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic2 * anisotropicRampTex.r);*/

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);
	//lightAtten = ApplyMicroSoftShadow(occlusion, worldNormal, worldLightDir, lightAtten);
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
	half3 color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, 0, 0);
	return half4(color, alpha);
}


