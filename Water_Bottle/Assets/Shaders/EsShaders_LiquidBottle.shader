    Shader "EsShaders/LiquidBottle"
{
    Properties
    {
        [Header(Liquid Properties)]
        _FillAmount("Fill Amount", Range(-2, 2)) = -0.5
        _ModleCenterPos("Modle Center Pos (Object Space)", Vector) = (0, 0, 0, 1)

        [Toggle(_USE_GRADUAL_TEXTURE)]_USE_GRADUAL_TEXTURE("Use Gradual Texture", float) = 0
        [NoScaleOffset]_LiquidGradualTexture("Liquid Gradual Texture", 2D) = "white" {}
        _GradualScale("Gradual Scale", float) = 1
        _GradualOffset("Gradual Offset", float) = 1

        [Space(20)]
        [HDR]_LiquidColor("Liquid Color", Color) = (0, 2.1, 2.6, 1)
        [HDR]_SurfaceColor("Liquid Surface Color", Color) = (0, 0, 0, 1)
        _LiquidRoughness("Liquid Roughness", Range(0, 1)) = 0.18
        [HDR]_FoamColor("Foam Color", Color) = (0, 0.5, 0, 1)
        _FoamHeight("Foam Height", Range(0, 0.1)) = 0.06
        
        [Header(Liquid Tension)]
        _LiquidTension("Liquid Tension", Range(0, 40)) = 30
        _LiquidEdgeDrop("Liquid Edge Drop", Range(-0.07, 0.07)) = 0.02


        [Space(10)]
        [Header(Wave Controller)]
        _WaveTex ("Liquid Wave Texture", 2D) = "white" {}
        _LiquidWaveIntensity("Liquid Wave Intensity", Range(0, 6)) = 0.88
        _LiquidWaveDensity("Liquid Wave Density", Range(0, 3)) = 0.1
        _WaveMoveSpeed("Wave Move Speed", Range(0, 5)) = 0.8

        [Space(10)] 
        [Header(Translucence Liquid Effect)]
        _LiquidThicknessValue("Liquid Thickness Value", Range(0, 0.07)) = 0.02
        _LiquidInnerThickness("Liquid Inner Thickness", range(0, 20)) = 3
        _LiquidOutterThickness("Liquid Outter Thickness", range(0.1, 1)) = 0.4
        _Refractive("Refractive Index", Range(-1, 1)) = 0.5
        // _Delta("Normal Distortion", Range(0, 2)) = 1

        [Space(10)] 
        [Header(Liquid Frensnel Effect)]
        [HDR]_LiquidFresnelColor("Liquid Fresnel Color", Color) = (0, 0, 0, 1)
        _LiquidFresnelValue("Liquid Fresnel Value", Range(0, 1)) = 0.02
        _LiquidFresnelPow("Liquid Fresnel Power", Range(0, 20)) = 20

        [Space(20)]
        [Header(Bottle Properties)]
        [HDR]_BottleColor("Bottle Color", Color) = (0, 0, 0, 1)
        _BottleSize("Bottle Size", Range(0, 0.02)) = 0.008
        _BottleRoughness("Bottle Roughness", Range(0, 1)) = 0.9
        _BottleMinAlpha("Bottle Min Alpha", Range(0, 1)) = 0.1
        _BottleAlpahRange("Bottle Alpah Range", Range(0, 1)) = 1

        _BottleRimPower("Bottle Rim Power", Range(0, 9)) = 3
        _SpecularPower("Specular Power", Range(0, 100)) = 30

        [Space(10)] 
        [Header(Bottle Frensnel Effect)]
        [HDR]_BottleFresnelColor("Bottle Fresnel Color", Color) = (0, 0, 0, 1)
        _BottleFresnelValue("Bottle Fresnel Value", Range(0, 1)) = 0.02
        _BottleFresnelPow("Bottle Fresnel Power", Range(0, 30)) = 5

        //----------------ParallaxMap--------------------------

        [Space(40)] 
        [Toggle(_PARALLAX_MAP)]_parallax_map("using Parallax Map", float) = 0
        _ParallaxScale("Parallax Scale", Range(0, 0.2)) = 0.05
        [HideInInspector]_ParallaxTexture("Parallax Texture", 2D) = "black" {}
        
        [NoScaleOffset]_BubbleTexture("Bubble Color Texture", 2D) = "black" {}

        _Buble1SizeX("Bubble 1 Size Horizontal", Range(10, 0)) = 1
        _Buble1SizeY("Bubble 1 Size Vertical", Range(10, 0)) = 1

        // _Buble2SizeX("Bubble 2 Size Horizontal", Range(0, 10)) = 1
        // _Buble2SizeY("Bubble 2 Size Vertical", Range(0, 10)) = 1
        // _Buble2OffsetX("Bubble 2 Offset Horizontal", Range(0, 10)) = 0.2
        // _Buble2OffsetY("Bubble 2 Offset Vertical", Range(0, 10)) = 0.7

        [HDR]_BubbleInnerColor("Bubble Inner Color", Color) = (1, 1, 1, 1)
        [HDR]_BubbleOuterColor("Bubble Outer Color", Color) = (0.2, 0.2, 0.2, 1)
        [Space(10)]
        _BackGroundNoise("BackGround Noise", 2D) = "white" {}
        _NoiseSpeedX("Noise Move Speed X", Range(-40, 40)) = 1
        _NoiseSpeedY("Noise Move Speed Y", Range(-40, 40)) = 1

        [Space(20)]
		_Layer1HeightBias("Layer Height Start Bias", Range(0.0, 3)) = 0.2
        [Toggle(EnableLayer1)] _EnableLayer1("Enable", float) = 0
        _Layer1SpeedX("_Layer1 Speed X", float) = 1
        _Layer1SpeedY("_Layer1 Speed Y", float) = 1
        
		_Layer2HeightBias("Layer Height Start Bias", Range(0.0, 3)) = 0.2
        [Toggle(EnableLayer2)] _EnableLayer2("Enable", float) = 0
        _Layer2SpeedX("_Layer2 Speed X", float) = 1
        _Layer2SpeedY("_Layer2 Speed Y", float) = 1

		_Layer3HeightBias("Layer Height Start Bias", Range(0.0, 3)) = 0.2
        [Toggle(EnableLayer3)] _EnableLayer3("Enable", float) = 0
        _Layer3SpeedX("_Layer3 Speed X", float) = 1
        _Layer3SpeedY("_Layer3 Speed Y", float) = 1

        [Space(10)]
        [Toggle(_ENABLE_COLORSTEP)]_Enable_ColorStep("Enable step bubble color", float) = 0
        _MinValue("MinValue", Range(0, 1)) = 0.482
        _MaxValue("MaxValue", Range(0, 1)) = 0.609
        //----------------ParallaxMap--------------------------
    }

    CGINCLUDE
	#include "UnityCG.cginc"
	#include "Lighting.cginc"
	#include "AutoLight.cginc"
	#include "EsPBR/EsShaders_Inputs.cginc"
	#include "EsPBR/EsShaders_BRDF.cginc"
    half3 _WorldZeroPos;
    half3 _ForceDir;
    inline half CalcLiquidCutHeight(half3 worldPos, half originHeight, half waveHeight)
    {
        half3 posToCenterDir = half3(worldPos.x, 0, worldPos.z) - half3(_WorldZeroPos.x, 0, _WorldZeroPos.z);
        _ForceDir.xz += _ForceDir.y;

        half degree = dot(posToCenterDir, _ForceDir);
        return originHeight + degree * waveHeight;
    }

    inline half FresnelTerm(half f0, half vDotn, half powValue)
    {
        return f0 + (1 - f0) * pow(1-vDotn, powValue);
        //another Fresnel function
        // return _LiquidThicknessValue + (1 - _LiquidThicknessValue)*pow(2, -5.55473*dot(V, H)-6.98316*dot(V, H));
    }
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque"}
        
        Pass
        {
            Cull OFF
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //----------------ParallaxMap--------------------------
#ifdef _PARALLAX_MAP
            #pragma shader_feature _PARALLAX_MAP
            #pragma shader_feature PARALLAX_OFFSET_LIMITING
            #pragma shader_feature EnableLayer1
            #pragma shader_feature EnableLayer2
            #pragma shader_feature EnableLayer3
            #pragma shader_feature _PARALLAX_FUNCTION
            #pragma shader_feature _ENABLE_COLORSTEP
			// #define _PARALLAX_FUNCTION ParallaxRaymarching
            #include "EsShaders_ParallaxMap.cginc"
#endif
            //----------------ParallaxMap--------------------------

            #pragma shader_feature _USE_GRADUAL_TEXTURE


            //----------------Liquid Properties--------------
            sampler2D _LiquidGradualTexture;
            half _GradualScale;
            half _GradualOffset;

            half _FillAmount;
            half3 _ModleCenterPos;

            fixed4 _LiquidColor;
            fixed4 _SurfaceColor;
            fixed4 _FoamColor;
            half _FoamHeight;
            fixed _LiquidRoughness;

            half _LiquidTension;
            half _LiquidEdgeDrop;

            //----------------Wave Controller-----------
            sampler2D _WaveTex;
            half4 _WaveTex_ST;
            half _LiquidWaveIntensity;
            half _LiquidWaveDensity;
            half _WaveMoveSpeed;

            //-------------Translucence Liquid Effect---------
            half _LiquidThicknessValue;
            half _LiquidInnerThickness;
            half _LiquidOutterThickness;
            // half _Delta;
            half _Refractive;

            //----------------Liquid Frensnel Effect----------
            fixed4 _LiquidFresnelColor;
            half _LiquidFresnelValue;
            half _LiquidFresnelPow;

            //-------------------_Parallax---------------------

            struct a2v
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                half4 tangent : TANGENT;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
                half liquidHeightYaxisValue : TEXCOORD1;
                half3 worldnormal : TEXCOORD2;
                half4 worldPos : TEXCOORD3;
                half3 tangentViewDir : TEXCOORD4;
            };
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = v.uv;

                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);
                
				o.tangentViewDir = TangentSpaceViewDir(v.tangent.xyz, cross(v.normal, v.tangent.xyz) * v.tangent.w, v.normal, ObjSpaceViewDir(v.vertex));

                //CenterPos
                o.worldPos.w = mul(unity_ObjectToWorld, float4(_ModleCenterPos.xyz, 1)).y;

                o.liquidHeightYaxisValue = o.worldPos.y - o.worldPos.w - _FillAmount;
                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                
                half3 worldNormal = normalize(i.worldnormal);
                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                half3 halfDir = normalize(viewDir + lightDir);

                //random wave
                half waterHeight = _LiquidWaveIntensity*(tex2D(_WaveTex, (half2(i.worldPos.x, i.worldPos.z))*_LiquidWaveDensity + normalize(_ForceDir.xz)*_Time.z*_WaveMoveSpeed));

                i.liquidHeightYaxisValue = CalcLiquidCutHeight(i.worldPos, i.liquidHeightYaxisValue, waterHeight);

                //if only want foam partion have tension, add this if statement
                // if(0.5+_FoamHeight-i.liquidHeightYaxisValue < 0.1)
                // {

                //------------Liquid edge tension------------
                half3 horizonViewDir = viewDir;
                horizonViewDir.y = 0;
                i.liquidHeightYaxisValue = lerp(i.liquidHeightYaxisValue, i.liquidHeightYaxisValue + _LiquidEdgeDrop, pow((cos(dot(horizonViewDir, worldNormal))-0.5)*2, _LiquidTension));
                
                //------------Liquid edge tension------------

                // }

                if(facing<0)
                    worldNormal = half3(0, 1, 0);

                //----------------Liquid color-------------------------
                half foamHeightVal = step(i.liquidHeightYaxisValue, 0.5+_FoamHeight) - step(i.liquidHeightYaxisValue, 0.5);
                half liquidVal = (step(i.liquidHeightYaxisValue, 0.5));
                fixed4 foamCol = foamHeightVal * _FoamColor;

                #ifdef _USE_GRADUAL_TEXTURE
                    fixed4 liquidGradualColor = tex2D(_LiquidGradualTexture, _GradualScale*half2(i.worldPos.y-i.worldPos.w, 0.5) - _GradualOffset);
                    fixed4 liquidCol =  liquidVal * _LiquidColor * liquidGradualColor;
                #else 
                    fixed4 liquidCol =  liquidVal * _LiquidColor;
                #endif

                liquidCol += foamCol;

                if(foamHeightVal + liquidVal < 0.01)
                    discard;

                fixed4 surfaceColor = _SurfaceColor * (foamHeightVal + liquidVal);
                fixed4 finalColor = facing > 0 ? liquidCol : surfaceColor;
                
                //------------------LiquidEdge SubSurface--------------------
                if(facing>0)
                {
                    half vDotn = max(0, dot(viewDir, worldNormal));
                    half giSpecularRange = FresnelTerm(_LiquidThicknessValue, vDotn, _LiquidInnerThickness);
                    
                    half3 refDir = refract(-viewDir, worldNormal, _Refractive);

                    half3 giSpecular = GISpecular(refDir, i.worldPos, _LiquidRoughness*_LiquidRoughness, 1);
                    giSpecularRange = smoothstep(0.05, _LiquidOutterThickness, giSpecularRange);
                    finalColor.rgb += giSpecular.rgb*giSpecularRange;

                    half fValue = FresnelTerm(_LiquidFresnelValue, vDotn, _LiquidFresnelPow);  
                    finalColor.rgb = lerp(finalColor.rgb, _LiquidFresnelColor.rgb , fValue);


                    //--------------------Parallax-----------------------------
                    
                    half3 viewDirToCenter = (_WorldZeroPos.xyz - _WorldSpaceCameraPos.xyz);
                    viewDirToCenter.y = 0;
                    half3 leftDir = normalize(cross(normalize(viewDirToCenter), half3(0, 1, 0)));
                    half2 dirToCenterPos = i.worldPos.xz - (_WorldZeroPos.xz - leftDir*4);
                    
                    half2 palneuv = half2(dot(leftDir,dirToCenterPos), i.worldPos.y);

#ifdef _PARALLAX_MAP
                    fixed4 bubbleColor = ApplyParallax(normalize(i.tangentViewDir), i.uv, 1);
                    finalColor.rgb = lerp(finalColor.rgb, bubbleColor.rgb, bubbleColor.a*_BubbleInnerColor.a*liquidVal);
                    // return bubbleColor;
#endif
                }
                return finalColor;
            }
            ENDCG
        }
        
        Tags { "RenderType"="Transparent" "IgnoreProjection" = "True" "Queue" = "Transparent"}
        Pass
        {
            Blend SrcAlpha oneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //------------------Bottle Properties--------------
            fixed4 _BottleColor;
            fixed _BottleMinAlpha;
            half _BottleRimPower;
            half _SpecularPower;
            half _BottleBrightness;
            half _BottleSize;
            fixed _BottleRoughness;
            half _BottleAlpahRange;

            fixed4 _BottleFresnelColor;
            half _BottleFresnelValue;
            half _BottleFresnelPow;

            struct a2v
            {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                half4 vertex : SV_POSITION;
                half3 worldnormal : TEXCOORD1;
                half3 worldPos : TEXCOORD2;
            };

            v2f vert (a2v v)
            {
                v2f o;
                v.vertex.xyz += v.normal * _BottleSize;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                half3 worldNormal = normalize(i.worldnormal);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 halfDir = normalize(lightDir + viewDir);

    
                //--------------bottle edge specular----------------
                half3 reflectDir = reflect(-viewDir, worldNormal);
                fixed3 giSpecular = GISpecular(reflectDir, i.worldPos, _BottleRoughness*_BottleRoughness, 1);
                half specular = pow(max(0, dot(halfDir, worldNormal)), _SpecularPower);

                //--------------bottle edge light----------------
                half nDotv = max(0, dot(worldNormal, viewDir));
                half alpha = pow(1 - nDotv, _BottleRimPower);
                alpha = max(_BottleMinAlpha, saturate(alpha+specular));
                alpha *= _BottleAlpahRange;
                fixed4 finalCol = fixed4(specular*_LightColor0.rgb + giSpecular, alpha);

                half fValue = FresnelTerm(_BottleFresnelValue, max(0, dot(viewDir, worldNormal)), _BottleFresnelPow);                
                finalCol.rgb = lerp(finalCol.rgb, _BottleFresnelColor.rgb, fValue);
                return finalCol;
            }
            ENDCG
        }
    }
}