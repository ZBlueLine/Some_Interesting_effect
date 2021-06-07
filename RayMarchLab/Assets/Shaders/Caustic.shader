Shader "Unlit/Caustic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frequence1("Frequence 1", Range(0, 1)) = 1
        _Frequence2("Frequence 2", Range(0, 1)) = 1
        _Frequence3("Frequence 3", Range(0, 1)) = 1
        _Range("_Range" , Range(0, 100)) = 10
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float _Frequence1;
            float _Frequence2;
            float _Frequence3;
            float _Range;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 k=_Time.y*.5;

                k.xy = i.uv.xy*_Range;
                k.xyw = mul(k.xyw, float3x3(-2,-1,2, 3,-2,1, 1,2,2)*_Frequence1);
                float f1 = length(0.5-frac(k.xyw));

                k.xyw = mul(k.xyw, float3x3(-2,-1,2, 3,-2,1, 1,2,2) * _Frequence2);
                float f2 = length(0.5-frac(k.xyw));

                k.xyw = mul(k.xyw, float3x3(-2,-1,2, 3,-2,1, 1,2,2) * _Frequence3);
                float f3 = length(0.5-frac(k.xyw));

                //return min(min(f1, f2), f3);
                k = pow(min(min(f1, f2), f3), 7.0)*25.0+float4(0,0,0,1);
                return k;
            }
            ENDCG
        }
    }
}
