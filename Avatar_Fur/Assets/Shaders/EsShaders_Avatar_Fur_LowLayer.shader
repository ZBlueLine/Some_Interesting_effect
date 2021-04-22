Shader "EsShaders/Avatar LowLayer Fur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _NoiseTex ("Noise Texture", 2D) = "white" {}
        [Toggle(ENABLE_SECOND_NOISE_TEX)]enable_second_noise_tex("enable second noise texture", float) = 0
        _SecondNoiseTex("Second Noise Texture", 2D) = "black" {}

        _FurColor("Fur Color", Color) = (0, 0, 0, 1)
        _FurLength("Furry Length", Range(0, 0.2)) = 1
        _FurRadius("Fur Radius", Range(100,20)) = 1
        _OcclusionColor("Occlusion Color", Color) = (0, 0, 0, 1)
        _OcclusionRange("_OcclusionRange", Range(0, 3)) = 1
        _OcclusionPower("_OcclusionPower", Range(0, 3)) = 2
        _UVOffset("Uv Offset", Vector) = (0, 0, 0, 0)

        _FresnalColor("Fresnal Color", Color) = (1, 1, 1, 1)
        _FresnalBias("Fresnal Bias", Range(0.0, 2)) = 0.1
        _FresnalPower("Fresnel Power", Range(0, 10)) = 5
        _FresnalScale("Fresnel Scale", Range(0, 10)) = 0.1

        _FurDirLightExposure("Furry DirLight Exposure", Range(0, 10)) = 1
        _LightFilter("Light Filter", Range(-1, 1)) = 0
        // _TangentOffsetTex("Tangent Offset Texture", 2D) = "balck" {}
        _SpecColor1("_SpecColor1",color) = (0,0,0,1)
        _SpecColor2("_SpecColor1",color) = (0,0,0,1)
        _SpecInfo("SpecInfo" , vector) = (1,0,1,0)
        _AnisotropicScale("_AnisotropicPowerScale", Range(0, 1)) = 0.5
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
            #define FURSTEP 0.05

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
            #define FURSTEP 0.15

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
            #define FURSTEP 0.25

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
            #define FURSTEP 0.35

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
            #define FURSTEP 0.45

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
            #define FURSTEP 0.5

            #include "UnityCG.cginc"
            #include "EsShaders_Avatar_Fur.cginc"
            ENDCG
        }
    }
}
