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
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(i.vertex.xy / 1000, 0, 0);
            }
            ENDCG
        }
    }
}