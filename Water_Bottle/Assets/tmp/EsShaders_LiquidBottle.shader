Shader "Unlit/LiquidBottle"
{
    Properties
    {
        [Header(Liquid Properties)]
        _FillAmount("Fill Amount", float) = 0
        _LiquidColor("Liquid Color", Color) = (0, 0, 0, 1)
        _SurfaceColor("Liquid Surface Color", Color) = (0, 0, 0, 1)
        _FoamColor("Foam Color", Color) = (0, 0, 0, 1)
        _FoamHeight("Foam Height", float) = 0.1
        _LiquidRoughness("Liquid Roughness", Range(0, 1)) = 0.9


        [Space(10)]
        [Header(Wave Controller)]
        _WaveTex ("Liquid Wave Texture", 2D) = "white" {}
        _LiquidWaveIntensity("Liquid Wave Intensity", Range(0, 6)) = 3.9
        _LiquidWaveDensity("Liquid Wave Density", Range(0, 1)) = 0.18
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
        _LiquidFresnelColor("Liquid Fresnel Color", Color) = (0, 0, 0, 1)
        _LiquidFresnelValue("Liquid Fresnel Value", Range(0, 1)) = 0.02
        _LiquidFresnelPow("Liquid Fresnel Power", Range(0, 20)) = 5

        [Space(20)]
        [Header(Bottle Properties)]
        _BottleColor("Bottle Color", Color) = (0, 0, 0, 1)
        _BottleSize("Bottle Size", Range(0, 1)) = 0
        _BottleRoughness("Bottle Roughness", Range(0, 1)) = 0.9
        _BottleMinAlpha("Bottle Min Alpha", Range(0, 1)) = 0.1

        _BottleRimPower("Bottle Rim Power", Range(0, 9)) = 0
        _SpecularPower("Specular Power", Range(0, 100)) = 20

        [Space(10)] 
        [Header(Bottle Frensnel Effect)]
        _BottleFresnelColor("Bottle Fresnel Color", Color) = (0, 0, 0, 1)
        _BottleFresnelValue("Bottle Fresnel Value", Range(0, 1)) = 0.02
        _BottleFresnelPow("Bottle Fresnel Power", Range(0, 10)) = 5
        
    }

    CGINCLUDE
    half3 _WorldZeroPos;
    half3 _ForceDir;
    half GetLiquidHeight(half3 worldPos, half originHeight, half waveHeight)
    {
        half3 posToCenterDir = half3(worldPos.x, 0, worldPos.z) - half3(_WorldZeroPos.x, 0, _WorldZeroPos.z);
        _ForceDir.xz += _ForceDir.y;

        half degree = dot(posToCenterDir, _ForceDir);
        return originHeight + degree * waveHeight;
    }

    half GetFresnel(half f0, half3 v, half3 h, half powValue)
    {
        return f0 + (1 - f0)*pow(1-dot(v, h), powValue);

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
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsPBR/EsShaders_Inputs.cginc"
			#include "EsPBR/EsShaders_BRDF.cginc"

            //----------------Liquid Properties--------------
            half _FillAmount;
            fixed4 _LiquidColor;
            fixed4 _SurfaceColor;
            fixed4 _FoamColor;
            half _FoamHeight;
            fixed _LiquidRoughness;

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

            struct a2v
            {
                half4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
                half liquidHeightYaxisValue : TEXCOORD1;
                half3 worldnormal : TEXCOORD2;
                half3 worldPos : TEXCOORD3;
            };
            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _WaveTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);

                o.liquidHeightYaxisValue = o.worldPos.y - _WorldZeroPos.y - _FillAmount;
                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                half3 worldNormal = normalize(i.worldnormal);
                half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                half3 halfDir = normalize(viewDir + lightDir);
                half waterHeight = _LiquidWaveIntensity*(tex2D(_WaveTex, (half2(i.worldPos.x, i.worldPos.z))*_LiquidWaveDensity + normalize(_ForceDir.xz)*_Time.z*_WaveMoveSpeed));

                i.liquidHeightYaxisValue = GetLiquidHeight(i.worldPos, i.liquidHeightYaxisValue, waterHeight);

                //------------Liquid edge tension------------

                //if only want foam partion have tension, add this if statement
                // if(0.5+_FoamHeight-i.liquidHeightYaxisValue < 0.1)
                // {
                half3 horizonViewDir = viewDir;
                horizonViewDir.y = 0;

                i.liquidHeightYaxisValue = lerp(i.liquidHeightYaxisValue, i.liquidHeightYaxisValue + 0.07, pow((cos(dot(horizonViewDir, worldNormal))-0.5)*2, 5));
                // }

                if(facing<0)
                    worldNormal = half3(0, 1, 0);

                //----------------Liquid color-------------------------
                half foamHeightVal = step(i.liquidHeightYaxisValue, 0.5+_FoamHeight) - step(i.liquidHeightYaxisValue, 0.5);
                half liquidVal = (step(i.liquidHeightYaxisValue, 0.5));
                fixed4 foamCol = foamHeightVal * _FoamColor;
                fixed4 liquidCol =  liquidVal * _LiquidColor;
                liquidCol += foamCol;

                if(foamHeightVal + liquidVal < 0.01)
                    discard;

                fixed4 surfaceColor = _SurfaceColor * (foamHeightVal + liquidVal);
                fixed4 finalColor = facing > 0 ? liquidCol : surfaceColor;
                
                //------------------LiquidEdge SubSurface--------------------
                if(facing>0)
                {
                    half lightBackValue = GetFresnel(_LiquidThicknessValue, viewDir, worldNormal/* - viewDir*_Delta*/, _LiquidInnerThickness);
                    half3 refDir = refract(-viewDir, worldNormal, _Refractive);

                    half3 giSpecular = GISpecular(refDir, i.worldPos, _LiquidRoughness*_LiquidRoughness, 1);
                    lightBackValue = smoothstep(0.05, _LiquidOutterThickness, lightBackValue);

                    finalColor.rgb += giSpecular.rgb*lightBackValue;

                    half fValue = GetFresnel(_LiquidFresnelValue, viewDir, worldNormal/* - viewDir*_Delta*/, _LiquidFresnelPow);
                    finalColor.rgb = lerp(finalColor.rgb, _LiquidFresnelColor.rgb , fValue);
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

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "EsPBR/EsShaders_BRDF.cginc"

            //------------------Bottle Properties--------------
            fixed4 _BottleColor;
            fixed _BottleMinAlpha;
            half _BottleRimPower;
            half _SpecularPower;
            half _BottleBrightness;
            half _BottleSize;
            fixed _BottleRoughness;

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

                half fValue = GetFresnel(_BottleFresnelValue, viewDir, worldNormal, _BottleFresnelPow);
                fixed4 finalCol = fixed4(specular*_LightColor0.rgb + giSpecular, alpha);
                finalCol = lerp(finalCol, _BottleFresnelColor, fValue);
                return finalCol;
            }
            ENDCG
        }
    }
}