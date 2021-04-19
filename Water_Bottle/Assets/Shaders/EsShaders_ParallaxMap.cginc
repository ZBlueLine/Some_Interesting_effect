/*
All feature
#pragma shader_feature _PARALLAX_MAP
// #pragma shader_feature _USE_RAYMARCHING (high overhead)
#pragma shader_feature _OFFSET_LIMITING
#pragma shader_feature _RAYMARCHING_INTERPOLATE
#pragma shader_feature _SUPPORT_DYNAMIC_BATCHING (enable this feature when using Dynamic Batching)

*/

half _ParallaxScale;

half _MinValue;
half _MaxValue;

sampler2D _ParallaxTexture;
half4 _ParallaxTexture_ST;

sampler2D _BackGroundNoise;
half4 _BackGroundNoise_ST;
half _NoiseSpeedX;
half _NoiseSpeedY;

sampler2D _BubbleTexture;

fixed4 _BubbleInnerColor;
fixed4 _BubbleOuterColor;

half _Buble1SizeX;
half _Buble1SizeY;
half _Buble2SizeX;
half _Buble2SizeY;
half _Buble2OffsetX;
half _Buble2OffsetY;

half _Layer1SpeedX;
half _Layer1SpeedY;
half _Layer2SpeedX;
half _Layer2SpeedY;
half _Layer3SpeedX;
half _Layer3SpeedY;

half _Layer1HeightBias;
half _Layer2HeightBias;
half _Layer3HeightBias;

#ifdef _PARALLAX_MAP
	half GetParallaxHeight (float2 uv) 
	{
		return tex2D(_ParallaxTexture, uv);
	}
	float2 ParallaxOffset (float2 uv, float2 viewDir, half layerHeightBiasAccum) 
	{
		
		half height = GetParallaxHeight(uv);
		height -= layerHeightBiasAccum;
		height -= 0.5;
		height *= _ParallaxScale;
		return viewDir * height;
	}

	//切线空间视线向量（指向相机）,视差贴图的uv, 视差贴图, 视差强度
	fixed4 ApplyParallax (in float3 tangentViewDir, in float2 uv, in half speedScale) 
	{
		tangentViewDir = normalize(tangentViewDir);
		#ifndef _OFFSET_LIMITING
			#ifndef PARALLAX_BIAS
				#define PARALLAX_BIAS 0.42
			#endif	
			half2 newViewDir = tangentViewDir.xy/(tangentViewDir.z + PARALLAX_BIAS);
		#else
			half2 newViewDir = tangentViewDir.xy;
		#endif

		#if !defined(_PARALLAX_FUNCTION)
			#define _PARALLAX_FUNCTION ParallaxOffset

		half layerHeightBiasAccum = 0;
		#endif

		float2 offset = 0;
		fixed4 Col = (0, 0, 0, 0);
		half2 layerBaseUV;
		
#ifdef EnableLayer1

		layerHeightBiasAccum = _Layer1HeightBias;
		layerBaseUV = (uv-0.5)*half2(_Buble1SizeX,_Buble1SizeY) + 0.5 + _Time.x* float2(_Layer1SpeedX,_Layer1SpeedY)+float2(0, 3);
		offset = _PARALLAX_FUNCTION(layerBaseUV, newViewDir, layerHeightBiasAccum);

		layerBaseUV += offset *half2(_Buble1SizeX,_Buble1SizeY);
		Col += tex2D(_BubbleTexture, layerBaseUV);
		// return tex2D(_BackGroundNoise, noiseUv);
#endif 

#ifdef EnableLayer2
		layerHeightBiasAccum = _Layer2HeightBias;

		layerBaseUV = (uv-0.5)*half2(_Buble1SizeX,_Buble1SizeY) + 0.5 + (_Time.x * float2(_Layer2SpeedX,_Layer2SpeedY));
		offset = _PARALLAX_FUNCTION(layerBaseUV, newViewDir, layerHeightBiasAccum);

		layerBaseUV += offset *half2(_Buble1SizeX,_Buble1SizeY);
		Col += tex2D(_BubbleTexture, layerBaseUV);
#endif 

#ifdef EnableLayer3
		layerHeightBiasAccum = _Layer3HeightBias;

		layerBaseUV = (uv-0.5)*half2(_Buble1SizeX,_Buble1SizeY) + 0.5 + (fmod(_Time.x,1) * float2(_Layer3SpeedX,_Layer3SpeedY));
		offset = _PARALLAX_FUNCTION(layerBaseUV, newViewDir, layerHeightBiasAccum);

		layerBaseUV += offset *half2(_Buble1SizeX,_Buble1SizeY);
		Col += tex2D(_BubbleTexture, layerBaseUV);
#endif 
		Col = saturate(Col);
		half2 noiseUv = uv*_BackGroundNoise_ST.xy + _Time.x * float2(_NoiseSpeedX, _NoiseSpeedY);
		Col += (tex2D(_BackGroundNoise, noiseUv)-0.5)*2;

		fixed4 finalColor = lerp(_BubbleOuterColor, _BubbleInnerColor, Col.r*0.5+0.5);
#ifdef _ENABLE_COLORSTEP
		Col.r = smoothstep(_MinValue, _MaxValue, Col.r);
#endif 
		
		return fixed4(finalColor.rgb * Col.r, Col.r);
	}


	//Raymarching Parallax
	// float2 ParallaxRaymarching (float2 uv, float2 viewDir, half layerHeightBiasAccum) {
	// 	#ifndef PARALLAX_RAYMARCHING_STEPS
	// 		#define PARALLAX_RAYMARCHING_STEPS 10
	// 	#endif
		
	// 	float2 uvOffset = 0;
	// 	half stepSize = 1.0/PARALLAX_RAYMARCHING_STEPS;
	// 	float2 uvDelta = viewDir * (stepSize * _ParallaxScale);
	// 	half stepHeight = 1;
	// 	half surfaceHeight = GetParallaxHeight(uv);

	// 	//multi layer
	// 	surfaceHeight -= layerHeightBiasAccum;
	// 	#ifdef _RAYMARCHING_INTERPOLATE	
	// 		float2 prevUVOffset = uvOffset;
	// 		half prevStepHeight = stepHeight;
	// 		half prevSurfaceHeight = surfaceHeight;
	// 	#endif

	// 	for(int i = 0; i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight; ++i)
	// 	{
	// 		#ifdef _RAYMARCHING_INTERPOLATE	
	// 			prevUVOffset = uvOffset;
	// 			prevStepHeight = stepHeight;
	// 			prevSurfaceHeight = surfaceHeight;
	// 		#endif
	// 		uvOffset -= uvDelta;
	// 		stepHeight -= stepSize;
	// 		surfaceHeight = GetParallaxHeight(uv + uvOffset);
	// 	}
	// 	#if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
	// 		#define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
	// 	#endif

	// 	#if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
	// 		for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++) 
	// 		{
	// 			uvDelta *= 0.5;
	// 			stepSize *= 0.5;
	// 			if(stepHeight < surfaceHeight)
	// 			{
	// 				uvOffset += uvDelta;
	// 				stepHeight += stepSize;
	// 			}
	// 			else
	// 			{
	// 				uvOffset -= uvDelta;
	// 				stepHeight -= stepSize;
	// 			}
	// 			surfaceHeight = GetParallaxHeight(uv + uvOffset);
	// 		}
	// 	#elif defined(_RAYMARCHING_INTERPOLATE)
	// 		half prevDifference = prevStepHeight - prevSurfaceHeight;
	// 		half difference = surfaceHeight - stepHeight;
	// 		half t = prevDifference / (prevDifference + difference);
	// 		uvOffset = prevUVOffset - uvDelta * t;
	// 	#endif
	// 	return uvOffset;
	// }
#endif