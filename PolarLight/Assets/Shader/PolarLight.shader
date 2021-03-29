    Shader "Unlit/PolarLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Direction("Direction", Vector) = (0, 0, 0, 0)
        _Color("Color", Color) = (1, 0, 0, 0)
        _Noise("Noise", 2D) = "white" {}
        _Speed("Speed", float) = 1
        _A("A", float) = 100
        _P("P", float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "LightMode" = "ForwardBase"}
        LOD 100

        Pass
        {
            Blend SrcAlpha oneMinusSrcAlpha
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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 ViewPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _Noise;

            float2 _Direction;

            fixed4 _Color;

            float _Speed;
            float _P;
            float _A;


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.ViewPos = mul(UNITY_MATRIX_V, o.worldPos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 worldPos = i.worldPos.xz;

                float noise = tex2D(_Noise, i.uv);

                float sinVal = noise*_A * sin(3.14159*_P*(worldPos.x) + _Time.y * _Speed) + worldPos.x;

                float Curve = _Color.r * smoothstep(5, 0, abs(sinVal-worldPos.y));

                noise = tex2D(_Noise, i.uv+0.453);

                sinVal = noise*_A * sin(3.14159*_P*(worldPos.x*2) + _Time.y * _Speed) + worldPos.x+100;

                Curve += _Color.r * smoothstep(5, 0, abs(sinVal-worldPos.y));

                return fixed4(Curve, -i.ViewPos.z, 0, Curve);
            }
            ENDCG
        }
        Pass
        {
            Blend SrcAlpha oneMinusSrcAlpha
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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 ViewPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _Noise;

            float2 _Direction;

            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;
                float offset = 0.01;
                for(int j = 0; j < 16; ++j)
                { 
                    float2 uv = i.uv+normalize(float2(0, 4))*j*offset;
                    uv.y = i.uv.y+j*offset;
                    col += tex2D(_MainTex, uv);
                }
                
                return fixed4(col.r, 0, 0, col.r);
            }
            ENDCG
        }
        Pass
        {
            Blend SrcAlpha oneMinusSrcAlpha
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
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 ViewPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _Noise;

            float2 _Direction;

            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;
                float offset = 0.01;
                float weight[3] = {0.4026, 0.2442, 0.0545};
                for(int j = 0; j < 3; ++j)
                { 
                    float2 uv = i.uv+normalize(float2(0, 1))*j*offset;
                    col += weight[j] * tex2D(_MainTex, uv);
                }
                
                return fixed4(col.r, 0, 0, col.r);
            }
            ENDCG
        }
    }
}
