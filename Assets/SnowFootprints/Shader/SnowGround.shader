Shader "Unlit/SnowGround"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _BumpMap ("NormalMap", 2D) = "Bump" { }
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct vertData
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 clipPos: SV_POSITION;
                float3 worldNormal: TEXCOORD2;
                float3 worldPos: TEXCOORD3;
                half3 tspace0: TEXCOORD4;
                half3 tspace1: TEXCOORD5;
                half3 tspace2: TEXCOORD6;
                SHADOW_COORDS(7)
                half3 ambient: COLOR0;
            };

            sampler2D _MainTex;
            sampler2D _BumpMap;
            float4 _MainTex_ST;

            // Vertex shader
            v2f vert(vertData v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // World Space NormalMap
                float3 wTangent = UnityObjectToWorldDir(v.tangent);
                half3 wBitangent = cross(o.worldNormal, wTangent) * v.tangent.w ;
                // output the tangent space matrix
                o.tspace0 = half3(wTangent.x, wBitangent.x, o.worldNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, o.worldNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, o.worldNormal.z);

                // Ambient
                o.ambient = ShadeSH9(half4(o.worldNormal, 1))

                // Shadow
                TRANSFER_SHADOW(o);
                return o;
            }

            // Fragment shader
            fixed4 frag(v2f i): SV_Target
            {
                // sample the normal map, and decode from the Unity encoding
                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                // transform normal from tangent to world space
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);
                worldNormal = normalize(worldNormal);
                float NdotL = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                half shadow = SHADOW_ATTENUATION(i);
                // sample the texture
                fixed4 diffuse = tex2D(_MainTex, i.uv);

                float4 FinalColor;
                FinalColor.rgb = diffuse.rgb * _LightColor0.rgb * NdotL * shadow + diffuse.rgb * i.ambient;
                FinalColor.a = diffuse.a;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return FinalColor;
            }
            ENDCG
            
        }
    }
}
// todo:
// 2019-5-5 23:14:26
// 世界空间的法线贴图