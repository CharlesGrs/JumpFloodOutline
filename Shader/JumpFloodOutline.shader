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
                float bestDist = 100;
                float2 bestCoord = 0;


                UNITY_UNROLL
                for (int u = -1; u <= 1; u++)
                {
                    UNITY_UNROLL
                    for (int v = -1; v <= 1; v++)
                    {
                        float2 offsetUV = i.uv + float2(u, v) * (_MainTex_TexelSize.xy * _StepSize);
                        float3 offsetPos = tex2D(_MainTex, offsetUV).rgb;
                        float2 disp = i.vertex.xy / 1000 - offsetPos.xy;

                        float dist = dot(disp, disp);

                        if (offsetPos.b == 0 && dist < bestDist)
                        {
                            bestDist = dist;
                            bestCoord = offsetPos.xy;
                        }
                    }
                }


                return bestDist != 100 ? float4(bestCoord, 0, 1) : float4(0, 0, 1, 0);
                return distance(bestCoord, i.screenPos);;
                return bestDist != 100 ? float4(bestCoord, 0, 1) : float4(0, 0, 1, 0);
            }
            ENDCG
        }

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
            sampler2D _JumpFloodRT;
            float4 _OutlineColor;
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
                float4 col = tex2D(_JumpFloodRT, i.uv);
                float4 col2 = tex2D(_MainTex, i.uv);
                float df = distance(col.rg, i.vertex.xy / 1000);

                float outline = step(.00109 , df);
                float outline2 = step(.00109 , df - .005);
                float aa = 1-smoothstep(0,abs(sin(_Time.y*2))*.01 +.002, df);
                // outline -= outline2;
                col2+= _OutlineColor * outline* aa;
                return col2;
                return lerp(col2,_OutlineColor, outline*aa);
            }
            ENDCG
        }
    }




}