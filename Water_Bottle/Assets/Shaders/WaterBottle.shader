Shader "Custom/WaterBottle"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _FillAmount("Fill Amount", float) = 0

        _ColorWater("Color Water", Color) = (0, 0, 0, 1)
        _SurfaceColor("Surface Color", Color) = (0, 0, 0, 1)
        _SectionColor("Section Color", Color) = (0, 0, 0, 1)
        _SectionFactor("Section Factor", float) = 20
        _FoamColor("Foam Color", Color) = (0, 0, 0, 1)
        _FoamWidth("Foam Width", float) = 0.1
        _NoiseScale("Noise Scale", Range(0, 6)) = 1
        _NoiseFrequence("Noise Frequence", Range(0, 1)) = 0.1
        _NoiseSpeed("Noise Speed", Range(0, 5)) = 1
        _FresnelWater0("Water Fresnel Value", float) = 0.02
        _FresnelWaterP("Fresnel Water Power", range(0, 6)) = 2

        _FresnelGlass0("Glass Fresnel Value", float) = 0.028

        [Space(10)] 
        _Delta("BackLight Distortion", Range(0, 2)) = 1
        _BackLightScale("Back Light Scale", float) = 1
        _BackLightP("Back Light P", float) = 10
        _FresnelColor("Fresnel Color", Color) = (0, 0, 0, 1)


        [Space(20)]
        _BottleColor("Bottle Color", Color) = (0, 0, 0, 1)
        _RimRange("Bottle Rim Range", float) = 0
        _Specular("Specular", float) = 0
        _AlphaRange("Alpha Range", Range(-1, 1)) = 0
        _Dis("Bottle Size", float) = 0
        
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
			#include "EsShaders_Inputs.cginc"
			#include "EsShaders_BRDF.cginc"
            
            #include "EsShaders_FowardLighting.cginc"

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

            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            float _FillAmount;
            float _FoamWidth;

            float _NoiseScale;
            float _NoiseFrequence;
            float _NoiseSpeed;

            fixed4 _FoamColor;
            fixed4 _ColorWater;
            fixed4 _SectionColor;
            float _SectionFactor;

            float _FresnelWater0;
            float _FresnelGlass0;

            float _FresnelWaterP;
            
            fixed4 _SurfaceColor;
            float3 _WorldZeroPos;

            float3 _ForceDir;

            //-------------SubSurface------------------
            float _Delta;
            float _BackLightScale;
            float _BackLightP;
            fixed4 _FresnelColor;


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

            float GetFresnel(float3 V, float3 H)
            {
                // return _FresnelWater0 + (1 - _FresnelWater0)*pow(2, -5.55473*dot(V, H)-6.98316*dot(V, H));
                return _FresnelWater0 + (1 - _FresnelWater0)*pow(1-dot(V, H), _FresnelWaterP);
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

                float waterHeight = _NoiseScale*(tex2D(_NoiseTex, (float2(i.worldPos.x, i.worldPos.z))*_NoiseFrequence + normalize(_ForceDir.xz)*_Time.z*_NoiseSpeed));
                // return tex2D(_NoiseTex, (float2(i.worldPos.x, i.worldPos.z))*_NoiseFrequence + normalize(float2(1, 1))*_Time.z*_NoiseSpeed).r;

                i.WaterEdgeY = GetWaterHeight(i.worldPos, i.WaterEdgeY, waterHeight*2);

                if(0.5+_FoamWidth-i.WaterEdgeY < 0.1)
                {
                    float3 horizonViewDir = viewDir;
                    horizonViewDir.y = 0;
                    i.WaterEdgeY = lerp(i.WaterEdgeY, i.WaterEdgeY + 0.07, pow((cos(dot(horizonViewDir, worldNormal))-0.5)*2, 5));
                }
                if(facing<0)
                    worldNormal = float3(0, 1, 0);

                float edgeVal = step(i.WaterEdgeY, 0.5+_FoamWidth) - step(i.WaterEdgeY, 0.5);
                float finalVal = (step(i.WaterEdgeY, 0.5));

                fixed4 edgeCol = edgeVal * _FoamColor;
                fixed4 col =  finalVal * _ColorWater;
                col += edgeCol;
                // return fixed4(_ForceDir, 1);
                if(edgeVal + finalVal < 0.01)
                    discard;

                fixed4 topColor = _SurfaceColor * (edgeVal + finalVal);
                fixed4 color = facing > 0 ? col : topColor;
                
                if(facing>0)
                {
                    //---------------------SubSurface--------------------
                    float Fvalue = GetFresnel(viewDir, worldNormal - viewDir*_Delta);
                    fixed LightBackValue = Fvalue;
                    color.rgb = lerp(color.rgb, _FresnelColor.rgb, LightBackValue);
                }
                // float value = pow(1-dot(worldNormal, viewDir),_SectionFactor);
                // value = smoothstep(0.1, 0.3, value);

                
                // color = lerp(color, _SectionColor, Fvalue);
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

            fixed4 _BottleColor;
            float _Dis;
            float _RimRange;
            float _AlphaRange;

            float _Specular;
        

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

                float NdotV = max(0, dot(worldNormal, viewDir));

                float specular = _BottleColor * pow(max(0, dot(H, worldNormal)), _Specular);
                float diffuse = _BottleColor * max(0, dot(worldNormal, LightDir));

                float alpha = pow(1 - NdotV, _RimRange);
                fixed3 rim = _BottleColor * alpha;

                return fixed4(diffuse + specular + rim, alpha*_AlphaRange + specular*_AlphaRange);
            }
            ENDCG
        }
    }
}