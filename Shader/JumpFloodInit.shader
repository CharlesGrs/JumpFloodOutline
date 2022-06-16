Shader "Unlit/JumpFloodInit"
{
    Properties {}
    SubShader
    {
        LOD 100

        Pass
        {
            Tags
            {
                "RenderType"="Opaque" "LightTag" = "JFA"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 wPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.wPos = TransformObjectToWorld(v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 UV = i.vertex.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(UV);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                float encodedDepth = distance(i.wPos, _WorldSpaceCameraPos) ;
                return float4(i.vertex.xy / _ScreenParams.xy, 0, encodedDepth);
            }
            ENDHLSL
        }
    }
}