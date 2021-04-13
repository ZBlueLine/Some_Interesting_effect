/*
All feature
#pragma shader_feature _PARALLAX_MAP
// #pragma shader_feature _USE_RAYMARCHING (high overhead)
#pragma shader_feature _OFFSET_LIMITING
#pragma shader_feature _RAYMARCHING_INTERPOLATE
#pragma shader_feature _SUPPORT_DYNAMIC_BATCHING (enable this feature when using Dynamic Batching)

*/

half _ParallaxScale;
half _LayerHeightBias;
fixed4 _BubbleInnerColor;
fixed4 _BubbleOuterColor;

half _MinValue;
half _MaxValue;

sampler2D _ParallaxTexture;
half4 _ParallaxTexture_ST;

sampler2D _BubbleTexture;
half4 _BubbleTexture_ST;
sampler2D _BubbleTexture2;
half4 _BubbleTexture2_ST;

half _Layer1SpeedX;
half _Layer1SpeedY;
half _Layer2SpeedX;
half _Layer2SpeedY;
half _Layer3SpeedX;
half _Layer3SpeedY;

#ifdef _PARALLAX_MAP
	half GetParallaxHeight (float2 uv) 
	{
		return smoothstep(0.9, 0.99, tex2D(_ParallaxTexture, uv).r);
	}
	float2 ParallaxOffset (float2 uv, float2 viewDir, half layerHeightBiasAccum) 
	{
		
		half height = GetParallaxHeight(uv);
		height -= 0.5;
		height *= _ParallaxScale;
		height -= layerHeightBiasAccum;
		return viewDir * height*_ParallaxTexture_ST.xy;
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

	//切线空间视线向量（指向相机）,视差贴图的uv, 视差贴图, 视差强度
	fixed3 ApplyParallax (in float3 tangentViewDir, in float2 uv, in half speedScale) 
	{
		tangentViewDir = normalize(tangentViewDir);
		#ifndef _OFFSET_LIMITING
			#ifndef PARALLAX_BIAS
				#define PARALLAX_BIAS 0.42
			#endif	
			half2 newCoords = tangentViewDir.xy/(tangentViewDir.z + PARALLAX_BIAS);
		#else
			half2 newCoords = tangentViewDir.xy;
		#endif

		#if !defined(_PARALLAX_FUNCTION)
			#define _PARALLAX_FUNCTION ParallaxOffset

		half layerHeightBiasAccum = 0;
		#endif

		float2 offset = _PARALLAX_FUNCTION(uv.xy, newCoords, layerHeightBiasAccum);
		fixed4 Col = (0, 0, 0, 0);
		half2 layerBaseUV;
		
		#ifdef EnableLayer1

			layerHeightBiasAccum += _LayerHeightBias;
			layerBaseUV = uv*_BubbleTexture_ST.xy  + _Time.x * (half2(_Layer1SpeedX, _Layer1SpeedY));
			offset = _PARALLAX_FUNCTION(layerBaseUV, newCoords, layerHeightBiasAccum);
			layerBaseUV += offset;

			Col += tex2D(_BubbleTexture, layerBaseUV);
		#endif 

		#ifdef EnableLayer2
			layerHeightBiasAccum += _LayerHeightBias;

			layerBaseUV = uv*_BubbleTexture_ST.xy + _Time.x * half2(_Layer2SpeedX, _Layer2SpeedY);
			offset = _PARALLAX_FUNCTION(layerBaseUV, newCoords, layerHeightBiasAccum);
			layerBaseUV += offset;

			Col += tex2D(_BubbleTexture, layerBaseUV);
		#endif 

		#ifdef EnableLayer3
			layerHeightBiasAccum += _LayerHeightBias;

			layerBaseUV = uv*_BubbleTexture_ST.xy + _Time.x * float2(_Layer3SpeedX,_Layer3SpeedY);
			offset = _PARALLAX_FUNCTION(layerBaseUV, newCoords, layerHeightBiasAccum);
			layerBaseUV += offset;

			Col += tex2D(_BubbleTexture, uv*_BubbleTexture_ST.xy + _Time.x * float2(_Layer3SpeedX,_Layer3SpeedY));
			Col += tex2D(_BubbleTexture2, uv*_BubbleTexture2_ST.xy + _BubbleTexture2_ST.zw);
		#endif 
		// Col.r *= 1.;
		// Col.r = pow(Col.r, 2);
		fixed4 finalColor = lerp(_BubbleOuterColor, _BubbleInnerColor, Col.r);
		Col.r = smoothstep(_MinValue, _MaxValue, Col.r);
		// finalColor = pow(finalColor, 5);
		// Col.r = pow(Col.r, 1);
		// Col.r *= 0.9;
		// Col.r  = smoothstep(0.9, 0.99, Col.r);
		return finalColor * Col.r;
	}
#endif