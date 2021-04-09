Shader "Custom/LiquidBottle"
{
    Properties
    {
        [Header(Liquid Properties)]
        _FillAmount("Liquid Level", float) = 0
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
        _BottleSize("Bottle Size", Range(0, 1)) = 0
        _BottleRoughness("Bottle Roughness", Range(0, 1)) = 0.9

        _BottleColor("Bottle Color", Color) = (0, 0, 0, 1)
        _BottleRimPower("Bottle Rim Power", Range(0, 6)) = 0
        _SpecularPower("Specular Power", Range(0, 100)) = 20

        [Space(10)] 
        [Header(Bottle Frensnel Effect)]
        _BottleFresnelColor("Bottle Fresnel Color", Color) = (0, 0, 0, 1)
        _BottleFresnelValue("Bottle Fresnel Value", Range(0, 1)) = 0.02
        _BottleFresnelPow("Bottle Fresnel Power", Range(0, 20)) = 5
        
    }
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
            float _FillAmount;
            fixed4 _LiquidColor;
            fixed4 _SurfaceColor;
            fixed4 _FoamColor;
            float _FoamHeight;
            fixed _LiquidRoughness;

            //----------------Wave Controller-----------
            sampler2D _WaveTex;
            float4 _WaveTex_ST;
            float _LiquidWaveIntensity;
            float _LiquidWaveDensity;
            float _WaveMoveSpeed;

            //-------------Translucence Liquid Effect---------
            float _LiquidThicknessValue;
            float _LiquidInnerThickness;
            float _LiquidOutterThickness;
            // float _Delta;
            float _Refractive;

            //----------------Liquid Frensnel Effect----------
            fixed4 _LiquidFresnelColor;
            float _LiquidFresnelValue;
            float _LiquidFresnelPow;

            float3 _WorldZeroPos;
            float3 _ForceDir;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float liquidHeightYaxisValue : TEXCOORD1;
                float3 worldnormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };


            float GetLiquidHeight(float3 worldPos, float originHeight, float waveHeight)
            {
                float3 posToCenterDir = float3(worldPos.x, 0, worldPos.z) - float3(_WorldZeroPos.x, 0, _WorldZeroPos.z);
                _ForceDir.xz += _ForceDir.y;

                float degree = dot(posToCenterDir, _ForceDir);
                return originHeight + degree * waveHeight;
            }

            float GetFresnel(float f0, float3 v, float3 h, float powValue)
            {
                return f0 + (1 - _LiquidThicknessValue)*pow(1-dot(v, h), powValue);

                //another Fresnel function
                // return _LiquidThicknessValue + (1 - _LiquidThicknessValue)*pow(2, -5.55473*dot(V, H)-6.98316*dot(V, H));
            }

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
                float3 worldNormal = normalize(i.worldnormal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 halfDir = normalize(viewDir + lightDir);
                float waterHeight = _LiquidWaveIntensity*(tex2D(_WaveTex, (float2(i.worldPos.x, i.worldPos.z))*_LiquidWaveDensity + normalize(_ForceDir.xz)*_Time.z*_WaveMoveSpeed));

                i.liquidHeightYaxisValue = GetLiquidHeight(i.worldPos, i.liquidHeightYaxisValue, waterHeight*2);

                //------------Liquid edge tension------------

                //if only want foam partion have tension, add this if statement
                // if(0.5+_FoamHeight-i.liquidHeightYaxisValue < 0.1)
                // {
                float3 horizonViewDir = viewDir;
                horizonViewDir.y = 0;

                i.liquidHeightYaxisValue = lerp(i.liquidHeightYaxisValue, i.liquidHeightYaxisValue + 0.07, pow((cos(dot(horizonViewDir, worldNormal))-0.5)*2, 5));
                // }

                if(facing<0)
                    worldNormal = float3(0, 1, 0);

                //----------------Liquid color-------------------------
                float foamHeightVal = step(i.liquidHeightYaxisValue, 0.5+_FoamHeight) - step(i.liquidHeightYaxisValue, 0.5);
                float liquidVal = (step(i.liquidHeightYaxisValue, 0.5));
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
                    float lightBackValue = GetFresnel(_LiquidThicknessValue, viewDir, worldNormal/* - viewDir*_Delta*/, _LiquidInnerThickness);
                    float3 refDir = refract(-viewDir, worldNormal, _Refractive);

                    half3 giSpecular = GISpecular(refDir, i.worldPos, _LiquidRoughness*_LiquidRoughness, 1);
                    lightBackValue = smoothstep(0.05, _LiquidOutterThickness, lightBackValue);

                    finalColor.rgb += giSpecular.rgb*lightBackValue;

                    float fValue = GetFresnel(_LiquidFresnelValue, viewDir, worldNormal/* - viewDir*_Delta*/, _LiquidFresnelPow);
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
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldnormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
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
                float3 worldNormal = normalize(i.worldnormal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 halfDir = normalize(lightDir + viewDir);

    
                //--------------bottle edge specular----------------
                float3 reflectDir = reflect(-viewDir, worldNormal);
                fixed3 giSpecular = GISpecular(reflectDir, i.worldPos, _BottleRoughness*_BottleRoughness, 1);
                half specular = pow(max(0, dot(halfDir, worldNormal)), _SpecularPower);

                //--------------bottle edge light----------------
                float nDotv = max(0, dot(worldNormal, viewDir));
                float alpha = pow(1 - nDotv, _BottleRimPower);
                alpha = saturate(alpha+specular);

                return (fixed4(specular*_LightColor0.rgb + giSpecular, alpha));
            }
            ENDCG
        }
    }
}