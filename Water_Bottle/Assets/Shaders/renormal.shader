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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i, fixed facing : VFace) : SV_Target
            {
                float3 worldNormal = normalize(i.worldnormal);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                // float waterHeight = cos(i.worldPos.x*UNITY_PI +_Time.y);

                float waterHeight = tex2D(_NoiseTex, float2(i.worldPos.x, i.worldPos.z)*0.1);
                float3 dx = ddx(i.worldPos);
                float3 dy = ddy(i.worldPos);
                dx.y = ddx(waterHeight);
                dy.y = ddy(waterHeight);
                worldNormal = normalize(cross(dy, dx));
                return waterHeight;
                // return fixed4(worldNormal, 1);

                fixed diffuse = 0.5*dot(worldNormal, LightDir) + 0.5;
                return diffuse;
            }
            ENDCG
        }
    }
}