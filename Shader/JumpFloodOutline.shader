Shader "Unlit/JumpFloodOutline"
{
    Properties
    {
        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
        [HDR]_OutlineColor("Outline Color", color) = (0,0,0,0)
        [HDR]_OutlineColorInsideObject("Outline Color Inside Object", color) = (0,0,0,0)

        [Header(Size)][Space]
        _OutlineSickness("OutlineSickness", Range(0.1,0.0000)) = 0.005
        _OutlineAA("OutlineAA", Range(0.1,0.0001)) = 0.01

        
        [Header(Distance FallOff)][Space]
        _DistanceMax("DistanceMax", float) = 200
        _DistancePow("DistancePow", float) = 2
        _MinSizeDistanceFactor("Distance Size Factor", range(0,1)) = 0.1

    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _StepSize;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 sc = ComputeScreenPos(o.vertex);
                o.screenPos = sc.xy / sc.w;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float bestDist = 999;
                float2 bestCoord = 0;
                float bestDepth = 0;

                UNITY_UNROLL
                for (int u = -1; u <= 1; u++)
                {
                    UNITY_UNROLL
                    for (int v = -1; v <= 1; v++)
                    {
                        float2 offsetUV = i.uv + float2(u, v) * (_MainTex_TexelSize.xy * _StepSize);
                        float4 offsetPos = tex2D(_MainTex, offsetUV).rgba;
                        float2 disp = i.vertex.xy / _ScreenParams.xy - offsetPos.xy;

                        float dist = dot(disp, disp);

                        if (offsetPos.b == 0 && dist < bestDist)
                        {
                            bestDepth = offsetPos.a;
                            bestDist = dist;
                            bestCoord = offsetPos.xy;
                        }
                    }
                }


                return bestDist != 999 ? float4(bestCoord, 0, bestDepth) : float4(0, 0, 1, 0);
            }
            ENDCG
        }

        Pass
        {
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
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _JumpFloodRT;
            float4 _OutlineColor, _OutlineColorInsideObject;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float _StepSize, _EnableAA;

            float _DistanceMax, _DistancePow, _MinSizeDistanceFactor;

            float _OutlineAA, _OutlineSickness;

            v2f vert(appdata v)
            {
                v2f o;
                float u = _StepSize;
                o.vertex = TransformObjectToHClip(v.vertex);
                float4 sc = ComputeScreenPos(o.vertex);
                o.screenPos = sc.xy / sc.w;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_JumpFloodRT, i.uv);
                float4 col2 = tex2D(_MainTex, i.uv);
                float encodedDepth = col.a;

                float2 UV = i.vertex.xy / _ScaledScreenParams.xy;

                #if UNITY_REVERSED_Z
                real depth = SampleSceneDepth(UV);
                #else
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);


                float d = pow(saturate(encodedDepth / _DistanceMax), _DistancePow);
                // float isBehind = encodedDepth > distance(worldPos, _WorldSpaceCameraPos);
                float depthDiff = encodedDepth - distance(worldPos, _WorldSpaceCameraPos);

                depthDiff = saturate(depthDiff * 100);

                float distanceField = distance(col.rg, i.vertex.xy / _ScreenParams.xy) * (col.b == 0);
                float outsideMask = step(.0007, distanceField);


                float oS = lerp(_OutlineSickness, _OutlineSickness * _MinSizeDistanceFactor, d);
                float oA = lerp(_OutlineAA, _OutlineAA * _MinSizeDistanceFactor, d);
                float aa = 1 - smoothstep(oS, oS + oA, distanceField);
                aa = pow(aa, 2);

                col2 += lerp(_OutlineColor, _OutlineColorInsideObject, depthDiff) * outsideMask * aa;
                return col2;
                return lerp(col2, _OutlineColor, outsideMask * aa);
            }
            ENDHLSL
        }
    }




}