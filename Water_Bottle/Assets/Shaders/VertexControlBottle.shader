    Shader "Unlit/VertexControlBottle"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightFactor("Water Height", float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #pragma target 5.0

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
                float4 modelPosRH : TEXCOORD1;
                float3 normal : NORMAL;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _HeightFactor;
            struct SpringData
            {
                float3 cachedWorldPos;
                float3 cachedVelocity;
            };
            uniform RWStructuredBuffer<SpringData> _myWriteBuffer : register(u1);
            uniform RWStructuredBuffer<SpringData> _myReadBuffer : register(u2);            

            v2f vert (appdata v)
            {
                v2f o;
                o.modelPosRH = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 0.0));
                if(o.modelPosRH.y > _HeightFactor)
                {
                    v.vertex.xyz = mul(unity_WorldToObject, float4(o.modelPosRH.x, _HeightFactor, o.modelPosRH.z, o.modelPosRH.w));
                    o.normal = float3(0, 1, 0);
                }
                else
                    o.normal = UnityObjectToWorldNormal(v.normal);
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 worldNormal = normalize(i.normal);

                fixed3 diffuse = 0.5*dot(worldNormal, LightDir) + 0.5;

                return fixed4(diffuse, 1);
            }
            ENDCG
        }
    }
}
