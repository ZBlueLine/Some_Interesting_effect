// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RayMarchShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            uniform float4x4 _CamFrustum;
            uniform float4x4 _CamToWorld;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
                float index : TEXCOORD2;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                
                half index;
                if(o.uv.x < 0.5 && o.uv.y < 0.5)
                    index = 3;
                else if(o.uv.x > 0.5 && o.uv.y < 0.5)
                    index = 2;
                else if(o.uv.x > 0.5 && o.uv.y > 0.5)
                    index = 1;
                else if(o.uv.x < 0.5 && o.uv.y > 0.5)
                    index = 0;
                
                o.ray=_CamFrustum[(int)index].xyz;
                o.ray = mul(o.ray, unity_MatrixV);

                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                // just invert the colors
		        float3 direction = normalize(i.ray.xyz);
                return fixed4(direction, 1);
            }
            ENDCG
        }
    }
}
