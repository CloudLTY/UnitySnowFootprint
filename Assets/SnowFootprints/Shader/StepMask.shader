Shader "Unlit/StepMask"
{
    Properties
    {
        _Expand ("Expand", Range(-1, 0)) = -0.2
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Name "mask"
            ColorMask R
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
            };

            float _Expand;

            v2f vert(appdata v)
            {
                v2f o;
                float3 vpos = v.vertex + normalize(v.normal) * _Expand;
                o.vertex = UnityObjectToClipPos(vpos);
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(1, 0, 0, 1);
                return col;
            }
            ENDCG
            
        }

        Pass
        {
            Name "depth"
            ColorMask G
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float depth: DEPTH;
            };


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = -UnityObjectToViewPos(v.vertex).z * _ProjectionParams.w;
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(0, 1 - i.depth, 0, 1);
                return col;
            }
            ENDCG
            
        }
    }
}
