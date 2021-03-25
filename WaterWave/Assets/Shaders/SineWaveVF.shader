Shader "Custom/surfWaves" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_WaveTex ("Albedo (RGB)", 2D) = "white" {}

		_WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1,0,0.5,10)
		_WaveB ("Wave B", Vector) = (0,1,0.25,20)

		_FoamColor("foam color", Color) = (1, 1, 1, 1)
		_Foamness("_Foamness", float) = 1

		_NshiftValue("_NshiftValue", float) = 1
		_ScaleValue("_ScaleValue", float) = 1
		_PowerValue("_PowerValue", float) = 35
		_BackLightColor("_BackLightColor", Color) = (0, 0, 0, 1)
	}
	SubShader 
	{
		Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProject" = "True" "LightMode" = "ForwardBase"}
		LOD 200
		Pass
		{
			// Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _WaveTex;
			sampler2D _CameraDepthTexture;

			float4 _WaveTex_ST;

			fixed4 _Color;
			float4 _WaveA;
			float4 _WaveB;

			fixed4 _FoamColor;
			float _Foamness;
			float _NshiftValue;
			float _ScaleValue;
			float _PowerValue;

			fixed4 _BackLightColor;
			

			float3 GerstnerWave (float4 wave, float3 p, inout float3 tangent, inout float3 binormal) 
			{
				float steepness = wave.z;
				float wavelength = wave.w;
				float k = 2 * UNITY_PI / wavelength;
				float c = sqrt(9.8 / k);
				float2 d = normalize(wave.xy);
				float f = k * (dot(d, p.xz) - c * _Time.y);
				float a = steepness / k;
				
				//p.x += d.x * (a * cos(f));
				//p.y = a * sin(f);
				//p.z += d.y * (a * cos(f));

				tangent += float3(
					-d.x * d.x * (steepness * sin(f)),
					d.x * (steepness * cos(f)),
					-d.x * d.y * (steepness * sin(f))
				);
				binormal += float3(
					-d.x * d.y * (steepness * sin(f)),
					d.y * (steepness * cos(f)),
					-d.y * d.y * (steepness * sin(f))
				);
				return float3(
					d.x * (a * cos(f)),
					a * sin(f),
					d.y * (a * cos(f))
				);
			}

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal : TEXCOORD0;
				float4 ScreenPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float2 uv : TEXCOORD3;
			};
			
			v2f vert(appdata_full v)
			{
				v2f o;
				float3 gridPoint = v.vertex.xyz;
				float3 tangent = float3(1, 0, 0);
				float3 binormal = float3(0, 0, 1);
				float3 p = gridPoint;
				p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
				p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
				float3 normal = normalize(cross(binormal, tangent));
				v.vertex.xyz = p;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = normal;
				o.ScreenPos = ComputeScreenPos(o.pos);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _WaveTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
				float3 BNormal = UnpackNormal(tex2D(_WaveTex, i.uv));

				fixed3 albedo = _Color;

				float3 worldNormal = normalize(i.normal);

				float3 LightDir = normalize(_WorldSpaceLightPos0).xyz;

				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

				float3 H = normalize(viewDir + LightDir);

				float3 shift_H = normalize(-worldNormal*_NshiftValue + -LightDir);
				fixed backLight = saturate(pow(dot(shift_H, viewDir), _PowerValue)*_ScaleValue);

				float sampleDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.ScreenPos.xy/i.ScreenPos.w);
				float backGroundDepth = LinearEyeDepth(sampleDepth);
				
				float foam = 1-saturate(_Foamness*(backGroundDepth - i.ScreenPos.w));

				fixed3 diffuse = albedo * max(0.0, dot(worldNormal, LightDir));

				worldNormal = normalize(worldNormal + BNormal*0.5);
				fixed3 specular = saturate(pow(saturate(dot(worldNormal, H)), 90));

				fixed4 col = fixed4 (diffuse, _Color.a);
				col.rgb += specular;
				col.rgb += backLight*_BackLightColor;
				col = lerp(col, _FoamColor, foam);
				// linearDepth *= 10;
				// return fixed4(shift_H, 1);
				return col;
			}
			ENDCG
		}
		
	}
	FallBack "Diffuse"
}
