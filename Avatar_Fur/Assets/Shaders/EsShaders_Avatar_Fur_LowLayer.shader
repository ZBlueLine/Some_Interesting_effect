Shader "EsShaders/Avatar LowLayer Fur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        [Toggle(ENABLE_SECOND_NOISE_TEX)]enable_second_noise_tex("enable second noise texture", float) = 0
        _SecondNoiseTex("Second Noise Texture", 2D) = "black" {}

        _FurColor("Fur Color", Color) = (0, 0, 0, 1)
        _FurLength("Furry Length", Range(0, 1)) = 1
        _FurRadius("Fur Radius", Range(15, 0)) = 1
        _OcclusionColor("Occlusion Color", Color) = (0, 0, 0, 1)
        _OcclusionPower("_OcclusionPower", Range(0, 10)) = 2
        _UVOffset("UV Offset", Vector) = (0, 0, 0, 0)
        _FresnelPow("Fresnel Power", Range(0, 10)) = 5
        _FresnelScale("Fresnel Scale", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjection" = "True"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.0

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.1

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.2

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.3

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.4

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.4

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.6

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.7

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.8

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }

        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.9

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_fur
            #pragma fragment frag_fur
            // make fog work
            #pragma shader_feature ENABLE_SECOND_NOISE_TEX
            #define FURSTEP 0.99

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
    }
}
