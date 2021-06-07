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

            float4x4 _CamFrustum;

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
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                int index;
                if(v.uv.x < 0.5)
                {
                    if(v.uv.y < 0.5)
                            index = 2;
                        else 
                            index = 0;
                }
                else
                {
                    if(v.uv.y < 0.5)
                        index = 3;
                    else 
                        index = 1;
                }
                float3 ray = _CamFrustum[index].xyz;
                o.ray = ray;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                col.rgb = normalize(i.ray);
                return col;
            }
            ENDCG
        }
    }
}
