Shader "Custom/WaterBottle"
{
    Properties
    {
        [Header(Water Properties)]
        _FillAmount("Water Level", float) = 0
        _WaterColor("Water Color", Color) = (0, 0, 0, 1)
        _SurfaceColor("Water Surface Color", Color) = (0, 0, 0, 1)
        _FoamColor("Foam Color", Color) = (0, 0, 0, 1)
        _FoamHeight("Foam Height", float) = 0.1
        _WaterRoughness("Water Roughness", Range(0, 1)) = 0.9


        [Space(10)]
        [Header(Wave Controller)]
        _NoiseTex ("Water Noise Texture", 2D) = "white" {}
        _NoiseScale("Water Wave Scale", Range(0, 6)) = 3.9
        _NoiseDensity("Water Wave Density", Range(0, 1)) = 0.18
        _NoiseSpeed("Wave Move Speed", Range(0, 5)) = 0.8

        [Space(10)] 
        [Header(Translucence Water Effect)]
        _WaterThicknessValue("Water Thickness Value", Range(0, 1)) = 0.02
        _CenterWaterThickness("Center Water Turbid Degree", range(0, 20)) = 3
        _EdgeWaterThickness("Edge Water Turbid Degree", range(0.1, 2)) = 0.4
        _RefrScale("Refraction Scale", Range(-1, 1)) = 0.5
        // _Delta("Normal Distortion", Range(0, 2)) = 1

        [Space(10)] 
        [Header(Water Frensnel Effect)]
        _FresnelColor("Fresnel Color", Color) = (0, 0, 0, 1)
        _FresnelValue("Fresnel Value", Range(0, 1)) = 0.02
        _FresnelPow("Fresnel Range", Range(0, 5)) = 5

        [Space(20)]
        [Header(Bottle Properties)]
        _BottleColor("Bottle Color", Color) = (0, 0, 0, 1)
        _RimRange("Bottle Rim Range", Range(0, 10)) = 0
        _Specular("Specular", Range(0, 40)) = 0
        _AlphaRange("Alpha Range", Range(0, 1)) = 0
        _Dis("Bottle Size", Range(0, 1)) = 0
        _BottleRoughness("Bottle Roughness", Range(0, 1)) = 0.9
        
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



			// #pragma skip_variants POINT POINT_COOKIE SHADOWS_CUBE VERTEXLIGHT_ON  

			// #include "EsPBR/EsShaders_FowardLighting.cginc"
            //----------------Water Properties--------------
            float _FillAmount;
            fixed4 _WaterColor;
            fixed4 _SurfaceColor;
            fixed4 _FoamColor;
            float _FoamHeight;
            fixed _WaterRoughness;

            //----------------Wave Controller-----------
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            float _NoiseScale;
            float _NoiseDensity;
            float _NoiseSpeed;

            //-------------Translucence Water Effect---------
            float _WaterThicknessValue;
            float _CenterWaterThickness;
            float _EdgeWaterThickness;
            // float _Delta;
            float _RefrScale;

            //----------------Water Frensnel Effect----------
            fixed4 _FresnelColor;
            float _FresnelValue;
            float _FresnelPow;

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
                float WaterEdgeY : TEXCOORD1;
                float3 worldnormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };


            float GetWaterHeight(float3 worldPos, float height, float newHeight)
            {
                float3 DisVector = float3(worldPos.x, height, worldPos.z) - float3(_WorldZeroPos.x, height, _WorldZeroPos.z);
                // float forceValue = length(_ForceDir);
                // _ForceDir = float3(4, 0, 0);
                _ForceDir.xz += _ForceDir.y;
                float d = dot(DisVector, _ForceDir);
                // d += saturate(_ForceDir.y);
                return height + d * newHeight;// + _ForceDir.y*newHeight;
            }

            float GetFresnel(float F0, float3 V, float3 H, float powValue)
            {
                // return _WaterThicknessValue + (1 - _WaterThicknessValue)*pow(2, -5.55473*dot(V, H)-6.98316*dot(V, H));
                return F0 + (1 - _WaterThicknessValue)*pow(1-dot(V, H), powValue);
            }


            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.WaterEdgeY = o.worldPos.y - _WorldZeroPos.y - _FillAmount;
                o.worldnormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                float3 worldNormal = normalize(i.worldnormal);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 halfDir = normalize(viewDir + LightDir);
                float waterHeight = _NoiseScale*(tex2D(_NoiseTex, (float2(i.worldPos.x, i.worldPos.z))*_NoiseDensity + normalize(_ForceDir.xz)*_Time.z*_NoiseSpeed));
                // return tex2D(_NoiseTex, (float2(i.worldPos.x, i.worldPos.z))*_NoiseDensity + normalize(float2(1, 1))*_Time.z*_NoiseSpeed).r;

                i.WaterEdgeY = GetWaterHeight(i.worldPos, i.WaterEdgeY, waterHeight*2);

                if(0.5+_FoamHeight-i.WaterEdgeY < 0.1)
                {
                    float3 horizonViewDir = viewDir;
                    horizonViewDir.y = 0;
                    i.WaterEdgeY = lerp(i.WaterEdgeY, i.WaterEdgeY + 0.07, pow((cos(dot(horizonViewDir, worldNormal))-0.5)*2, 5));
                }
                if(facing<0)
                    worldNormal = float3(0, 1, 0);

                float edgeVal = step(i.WaterEdgeY, 0.5+_FoamHeight) - step(i.WaterEdgeY, 0.5);
                float finalVal = (step(i.WaterEdgeY, 0.5));

                fixed4 edgeCol = edgeVal * _FoamColor;
                fixed4 col =  finalVal * _WaterColor;
                col += edgeCol;
                // return fixed4(_ForceDir, 1);
                if(edgeVal + finalVal < 0.01)
                    discard;

                fixed4 topColor = _SurfaceColor * (edgeVal + finalVal);
                fixed4 color = facing > 0 ? col : topColor;
                
                if(facing>0)
                {
                    //---------------------SubSurface--------------------
                    float LightBackValue = GetFresnel(_WaterThicknessValue, viewDir, worldNormal/* - viewDir*_Delta*/, _CenterWaterThickness);
                    float3 relDir = refract(viewDir, worldNormal, _RefrScale);

                    half3 giSpecular = GISpecular(relDir, i.worldPos, _WaterRoughness*_WaterRoughness, 1);
                    // return fixed4(giSpecular, 1);
                    LightBackValue = smoothstep(0.05, _EdgeWaterThickness, LightBackValue);
                    // return LightBackValue;

                    color.rgb += giSpecular.rgb*LightBackValue;

                    float Fvalue = GetFresnel(_FresnelValue, viewDir, worldNormal/* - viewDir*_Delta*/, _FresnelPow);
                    color.rgb += _FresnelColor.rgb * Fvalue;
                    // return Fvalue;   
                }
                return color;
            }
            ENDCG
        }
        
        Tags { "RenderType"="Transparent" "IgnoreProjection" = "True" "Queue" = "Transparent"}
        Pass
        {
            // AlphaToMask on
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
            float _RimRange;
            float _Specular;
            float _AlphaRange;
            float _Dis;
            fixed _BottleRoughness;

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
                v.vertex.xyz += v.normal * _Dis;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldnormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                float3 worldNormal = normalize(i.worldnormal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 H = normalize(LightDir + viewDir);


                float3 relDir = reflect(-viewDir, worldNormal);
                fixed3 giSpecular = GISpecular(relDir, i.worldPos, _BottleRoughness*_BottleRoughness, 1);
                half specular = pow(max(0, dot(H, worldNormal)), _Specular);

                // giSpecular = lerp(giSpecular, _BottleColor, 0.5);
                float NdotV = max(0, dot(worldNormal, viewDir));
                float alpha = pow(1 - NdotV, _RimRange);
                fixed3 rim = giSpecular * alpha;

                return fixed4(specular*_LightColor0.rgb + rim + giSpecular, alpha*_AlphaRange + specular*_AlphaRange);
            }
            ENDCG
        }
    }
}