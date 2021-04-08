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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float WaterEdge : TEXCOORD1;
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
            
            fixed4 _SurfaceColor;
            float3 _WorldZeroPos;

            float3 _ForceDir;

            float GetWaterHeight(float3 worldPos, float height, float newHeight)
            {
                float3 DisVector = float3(worldPos.x, height, worldPos.z) - float3(_WorldZeroPos.x, height, _WorldZeroPos.z);
                // float forceValue = length(_ForceDir);
                // _ForceDir = float3(4, 0, 0);
                float d = dot(DisVector, _ForceDir);
                return height + d * newHeight;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.WaterEdge = o.worldPos.y - _WorldZeroPos.y - _FillAmount;
                o.worldnormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                float3 worldNormal = normalize(i.worldnormal);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

                // float waterHeight = cos(i.worldPos.x*UNITY_PI +_Time.y);

                float waterHeight = _NoiseScale*(tex2D(_NoiseTex, (float2(i.worldPos.x, i.worldPos.z))*_NoiseFrequence + normalize(_ForceDir.xz)*_Time.z*_NoiseSpeed));
                // float waterHeight = 2;
                if(facing<0)
                {
                    // float3 dx = ddx(i.worldPos);
                    // float3 dy = ddy(i.worldPos);
                    // dx.y = ddx(waterHeight);
                    // dy.y = ddy(waterHeight);
                    // worldNormal = normalize(cross(dx, dy));
                    worldNormal = float3(0, 1, 0);
                }
                // return waterHeight;
                i.WaterEdge = GetWaterHeight(i.worldPos, i.WaterEdge, waterHeight*2);
                float edgeVal = step(i.WaterEdge, 0.5+_FoamWidth) - step(i.WaterEdge, 0.5);
                float finalVal = (step(i.WaterEdge, 0.5));

                fixed4 edgeCol = edgeVal * _FoamColor;
                fixed4 col =  finalVal * _ColorWater;
                col += edgeCol;
                // return fixed4(_ForceDir, 1);
                if(edgeVal + finalVal < 0.01)
                    discard;

                fixed4 topColor = _SurfaceColor * (edgeVal + finalVal);
                fixed4 color = facing > 0 ? col : topColor;
                
                fixed diffuse = 0.5*dot(worldNormal, LightDir) + 0.5;
                color.rgb *= diffuse;

                float value = pow(1-dot(worldNormal, viewDir),_SectionFactor);
                value = smoothstep(0.1, 0.3, value);
                color = lerp(color, _SectionColor, value);
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

            struct appdata
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
        

            v2f vert (appdata v)
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