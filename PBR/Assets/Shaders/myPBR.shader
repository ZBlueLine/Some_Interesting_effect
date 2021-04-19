Shader "Custom/myPBR"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Normal Map", 2D) = "bump" {}
        _MetallicTex("Metallic Texture", 2D) = "black" {}

        _Distance("Light distance", float) = 0
        _TintColor("Tint Color", Color) = (0, 0, 0, 0)
        _Roughness("Roughness", Range(0, 1)) = 0
        _Metallic("Metallic", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
			Tags { "LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 TBN0 :TEXCOORD2;
                float3 TBN1 :TEXCOORD3;
                float3 TBN2 :TEXCOORD4;
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MetallicTex;
            sampler2D _NormalTex;

            float _Distance;
            fixed4 _TintColor;
            float _Roughness;
            float _Metallic;

            float DistributionGGX(float3 N, float3 H, float roughness)
            {
                float a      = roughness*roughness;
                float a2     = a*a;
                float NdotH  = max(dot(N, H), 0.0);
                float NdotH2 = NdotH*NdotH;

                float nom   = a2;
                float denom = (NdotH2 * (a2 - 1.0) + 1.0);
                denom = UNITY_PI * denom * denom;

                return nom / denom;
            }
            float3 fresnelSchlick(float cosTheta, float3 F0)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
            }  

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float r = (roughness + 1.0);
                float k = (r*r) / 8.0;

                float nom   = NdotV;
                float denom = NdotV * (1.0 - k) + k;

                return nom / denom;
            }
            float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
            {
                float NdotV = max(dot(N, V), 0.0);
                float NdotL = max(dot(N, L), 0.0);
                float ggx2  = GeometrySchlickGGX(NdotV, roughness);
                float ggx1  = GeometrySchlickGGX(NdotL, roughness);

                return ggx1 * ggx2;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                float3 tangent = normalize(mul(v.tangent, (float3x3)unity_WorldToObject));
                float3 binormal = cross(tangent, o.normal)*v.tangent.w;
                o.TBN0 = float3(tangent.x, binormal.x, o.normal.x);
                o.TBN1 = float3(tangent.y, binormal.y, o.normal.y);
                o.TBN2 = float3(tangent.z, binormal.z, o.normal.z);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                _Metallic = tex2D(_MetallicTex, i.uv).a;
                float3x3 tbn = float3x3(i.TBN0, i.TBN1, i.TBN2);
                float3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));
                // return fixed4(normal, 1);
                normal = normalize(mul(tbn, normal));

                float3 N = normal;
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 H = normalize(V + L);
                // float distance = length(_WorldSpaceLightPos0.xyz - i.worldPos);

                fixed3 albedo = pow(tex2D(_MainTex, i.uv).rgb, 2.2);

                float attenuation = 1.0/(_Distance*_Distance);
                float cosTheta = max(dot(H, N), 0.0);



                float NDF = DistributionGGX(N, H, _Roughness);
                float G   = GeometrySmith(N, V, L, _Roughness);
                float3 F0 = 0.04; 
                F0 = lerp(F0, albedo, _Metallic);
                float3 F  = fresnelSchlick(max(dot(H, L), 0.0), F0);

                float3 nominator = NDF * G * F;

                float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.00001; 
                
                float3 specular = nominator / denominator;  
                
                fixed3 Flambert = albedo.rgb/UNITY_PI;
                
                float3 radiance = _LightColor0.rgb * attenuation;

                
                float3 kS = F;
                float3 kD = float3(1.0, 1.0, 1.0) - kS;
                kD *= 1.0 - _Metallic;

                float NdotL = max(dot(N, L), 0.0);      
                fixed3 Lo = (kD*Flambert + specular)*radiance*NdotL;
                
                fixed3 ambient = float3(0.03, 0.03, 0.03) * albedo;// * ao;

                fixed3 col = ambient + Lo;

                col = col / (col + 1.0);
                col = pow(col, 1.0/2.2);      
                
                return fixed4(col, 0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}

