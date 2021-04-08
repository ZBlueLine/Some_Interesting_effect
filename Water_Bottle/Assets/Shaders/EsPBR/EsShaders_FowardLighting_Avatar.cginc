v2fBase_Avatar vertBase (appdata v)
{
	v2fBase_Avatar o;
	UNITY_INITIALIZE_OUTPUT(v2fBase_Avatar,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

#ifdef _LIGHT_FLOW_ON
	o.texcoord.zw = step(1, _LightFlowMode) ? v.vertex.xz : v.vertex.yz;
#endif
	//o.texcoord.zw = TRANSFORM_TEX(v.texcoord, _AnisotropicRampTex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.worldBinormal = cross(o.worldNormal, o.worldTangent) * tangentSign;
	v.normal.w = 0.0f;

	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;
	o.ambientOrLightmapUV = VertexGI_SH(v.texcoord1, o.worldPos, o.worldNormal);

	o.screenPos = ComputeScreenPos(o.pos);
	UNITY_TRANSFER_LIGHTING(o, v.texcoord1);
	return o;
}

fixed4 fragBase (v2fBase_Avatar i) : SV_Target
{
	float3 worldPos = i.worldPos;

	float2 uv = i.texcoord.xy;

	fixed4 mainColor = tex2D(_MainTex,uv);

	fixed alpha = i.color.a * mainColor.a * _Color.a;

#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif


	fixed3 baseColor = mainColor.rgb;
	fixed3 albedo = i.color.rgb * baseColor * _Color.rgb;

#if _PBRMAP
	fixed4 pbrInfo = tex2D(_PBRMap, i.texcoord.xy);
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

	float3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

	float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - worldPos);

	float3 worldNormal = normalize(i.worldNormal);
	float3 worldBinormal = normalize(i.worldBinormal);
	float3 worldTangent = normalize(i.worldTangent);

	float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, i.texcoord.xy), _BumpScale);
	normal = normalize(normal);

	worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);

	half3 refDir = reflect(-worldViewDir, worldNormal);
	/*float3 worldBitangent1 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic1 * anisotropicRampTex.r);
	float3 worldBitangent2 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic2 * anisotropicRampTex.r);*/

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);

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
	emission = EmissionSetup(emission * albedo, i.texcoord, worldNormal, worldViewDir, worldLightDir, lightColor, worldPos);
	//计算间接光
	half3 giDiffuse = IndirectDiffuseAvatar(i.ambientOrLightmapUV, worldNormal, worldPos, occlusion);//计算间接光漫反射.
	half3 giSpecular;//计算间接光镜面反射，后面可以的话，调成cubemap或matcap
	giSpecular = GISpecular(refDir, worldPos, perceptualRoughness, occlusion);//计算间接光镜面反射，后面可以的话，调成cubemap或matcap.
	half3 color = 0;
//#ifdef _BRDF_SKIN
//				fixed4 sss = tex2D(_SkinSSSTex, i.texcoord.xy);
//				color = Es_BDRF_SKIN(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular, sss);
//#elif _BRDF_FABRIC
//				color = Es_BDRF(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular, sss);
//#else
	//--------------------------------------------------------

	color = Es_BDRF_Avatar(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldTangent, worldBinormal, worldViewDir, worldLightDir, lightColor, giDiffuse, giSpecular, _SkinBRDFLut, _SkinSSSTex, _SkinCurvatureScale, _SkinThicknessScale, _SkinSubColor, _SkinPower, _SkinDistortion, i.texcoord);
	//color = Es_BDRF_Velvet(diffColor, specColor,oneMinusReflectivity,smoothness, worldNormal, worldViewDir, worldLightDir,lightColor,giDiffuse,giSpecular);
	color += emission;
	return half4(color, alpha);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
v2fAdd_Avatar vertAdd (appdata v)
{
	v2fAdd_Avatar o;
	UNITY_INITIALIZE_OUTPUT(v2fAdd_Avatar,o);
	o.pos = UnityObjectToClipPos(v.vertex);
	o.texcoord.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
	//o.texcoord.zw = TRANSFORM_TEX(v.texcoord, _AnisotropicRampTex);

	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);

	fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
	o.worldBinormal = cross(o.worldNormal, o.worldTangent) * tangentSign;
	v.normal.w = 0.0f;
	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	o.color = v.color;

	o.screenPos = ComputeScreenPos(o.pos);
	TRANSFER_SHADOW(o);
	//填充雾效所需要的参数，定义在UnityCG.cginc
	//UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

fixed4 fragAdd (v2fAdd_Avatar i) : SV_Target
{
	fixed4 mainColor = tex2D(_MainTex, i.texcoord.xy);
	fixed alpha = i.color.a * mainColor.a * _Color.a;
#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
#endif

	fixed3 albedo = i.color.rgb * mainColor.rgb * _Color.rgb;
	//fixed4 anisotropicRampTex = tex2D(_AnisotropicRampTex, i.texcoord.zw);

#if _PBRMAP
	fixed4 pbrInfo = tex2D(_PBRMap, i.texcoord.xy);
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

	float3 worldNormal = normalize(i.worldNormal);
	float3 worldBinormal = normalize(i.worldBinormal);
	float3 worldTangent = normalize(i.worldTangent);

	float3 normal = _UnpackScaledNormal(tex2D(_BumpMap, i.texcoord.xy), _BumpScale);
	normal = normalize(normal);
	worldNormal = WorldSpaceNormalFromTangentSpace(worldTangent, worldBinormal, worldNormal, normal);

	half3 refDir = reflect(-worldViewDir, worldNormal);
	/*float3 worldBitangent1 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic1 * anisotropicRampTex.r);
	float3 worldBitangent2 = ShiftTangent(worldBinormal, worldNormal, 0.01 + _Anisotropic2 * anisotropicRampTex.r);*/

	UNITY_LIGHT_ATTENUATION(lightAtten, i, worldPos);

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
	//计算间接光
	half3 color = Es_BDRF_Mobile(diffColor, specColor, oneMinusReflectivity, smoothness, worldNormal, worldViewDir, worldLightDir, lightColor, 0, 0);
	return half4(color, alpha);
}


