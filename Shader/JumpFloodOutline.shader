Shader "Unlit/JumpFloodOutline"
{
    Properties
    {
        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
        _OutlineColor("Outline Color", color) = (0,0,0,0)
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
                return distance(bestCoord, i.screenPos);;
                return bestDist != 100 ? float4(bestCoord, 0, 1) : float4(0, 0, 1, 0);
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
            float4 _OutlineColor;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            float _StepSize;

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

                // float isBehind = encodedDepth > distance(worldPos, _WorldSpaceCameraPos);
                float depthDiff = encodedDepth - distance(worldPos, _WorldSpaceCameraPos);
                depthDiff = saturate(depthDiff *4);

                float distanceField = distance(col.rg, i.vertex.xy / _ScreenParams.xy) * (col.b == 0);
                float outsideMask = step(.00109, distanceField);

                float innerAA = smoothstep(0, .005, distanceField);

                float a = 0.006;
                float aa = 1 - smoothstep(a, a + .0015, distanceField);
                aa = pow(aa, 2);
                

                
                
                col2 += lerp( 1 - _OutlineColor, _OutlineColor, depthDiff) * outsideMask * aa * innerAA;
                return col2;
                return lerp(col2, _OutlineColor, outsideMask * aa);
            }
            ENDHLSL
        }
    }




}