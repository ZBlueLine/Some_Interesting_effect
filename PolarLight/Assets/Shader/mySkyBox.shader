Shader "Unlit/mySkyBox"
{
    Properties
    {
        _MainTex ("Texture", Cube) = "white" {}
        _PolarRT("Polar RT", 2D) = "white" {}
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 ScreenPos : TEXCOORD1;
            };

            samplerCUBE _MainTex;
            float4 _MainTex_ST;

            sampler2D _PolarRT;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.ScreenPos = ComputeScreenPos(o.pos);
                o.uv = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.ScreenPos /= i.ScreenPos.w;
                fixed3 cubeCol = texCUBE(_MainTex, i.uv);
                fixed3 polarLightCol = tex2D(_PolarRT, i.ScreenPos.xy);
                fixed3 col = lerp(cubeCol, polarLightCol, polarLightCol.r);

                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
