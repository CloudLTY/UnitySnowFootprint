Shader "Unlit/SnowGround"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _StepTex ("StepTex", 2D) = "black" { }
        _BumpMap ("NormalMap", 2D) = "Bump" { }
        _Size ("Size", float) = 14
        _DissFactor ("DissFactor", float) = 0.1
        _DissplacePower ("DissplacePower", Range(-1, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            
            CGPROGRAM
            
            #pragma vertex vertTess
            #pragma fragment frag

            #pragma hull hull_shader
            #pragma domain domain_shader
            #pragma target 5.0

            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct Vs_In
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };

            struct Hs_In
            {
                float4 vertex: INTERNALTESSPOS;
                float2 uv: TEXCOORD0;
                float2 uv2: TEXCOORD1;
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
            };


            struct Fs_In
            {
                float4 clipPos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 worldNormal: TEXCOORD1;
                half3 tspace0: TEXCOORD2;
                half3 tspace1: TEXCOORD3;
                half3 tspace2: TEXCOORD4;
                half3 ambient: COLOR0;
            };

            struct HS_CONSTANT_DATA_OUTPUT
            {
                float edge[3]: SV_TessFactor;
                float inside: SV_InsideTessFactor;
            };

            sampler2D _MainTex;
            sampler2D _BumpMap;
            sampler2D _StepTex;
            float4 _MainTex_ST;
            float _Size;
            float _DissFactor;
            float _DissplacePower;
            

            // Vertex shader
            Hs_In vertTess(Vs_In i)
            {
                Hs_In o;
                o.vertex = i.vertex;
                o.uv = i.uv;
                o.uv2 = i.uv;
                o.normal = i.normal;
                o.tangent = i.tangent;

                return o;
            }

            

            HS_CONSTANT_DATA_OUTPUT constantsHS(InputPatch < Hs_In, 3 > V, uint PatchID: SV_PrimitiveID)
            {
                HS_CONSTANT_DATA_OUTPUT output = (HS_CONSTANT_DATA_OUTPUT)0;
                float2 uv = V[0].uv;
                float factor = tex2Dlod(_StepTex, float4(uv, 0, 0)).r ;
                output.edge[0] = output.edge[1] = output.edge[2] = lerp(1.0, 64.0, factor * _DissFactor);
                output.inside = lerp(1.0, 64.0, factor);
                return output;
            }

            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [patchconstantfunc("constantsHS")]
            [outputcontrolpoints(3)]

            Hs_In hull_shader(InputPatch < Hs_In, 3 > V, uint ID: SV_OutputControlPointID)
            {
                return V[ID];
            }


            //
            inline Fs_In vert(Hs_In v)
            {
                Fs_In o;
                

                o.clipPos = UnityObjectToClipPos(v.vertex);
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

            [domain("tri")]
            Fs_In domain_shader(HS_CONSTANT_DATA_OUTPUT input, const OutputPatch < Hs_In, 3> P, float3 K: SV_DomainLocation)
            {
                Hs_In ds;
                ds.vertex = P[0].vertex * K.x + P[1].vertex * K.y + P[2].vertex * K.z;
                ds.uv = (P[0].uv * K.x + P[1].uv * K.y + P[2].uv * K.z) * _MainTex_ST.xy + _MainTex_ST.zw;
                ds.uv = P[0].uv2 * K.x + P[1].uv2 * K.y + P[2].uv2 * K.z;
                ds.normal = P[0].normal * K.x + P[1].normal * K.y + P[2].normal * K.z;
                ds.tangent = P[0].tangent * K.x + P[1].tangent * K.y + P[2].tangent * K.z;
                return vert(ds);
            }


            // Fragment shader
            fixed4 frag(Fs_In i): SV_Target
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
                // sample the texture
                fixed4 diffuse = tex2D(_MainTex, i.uv);

                float4 FinalColor;
                FinalColor.rgb = diffuse.rgb * _LightColor0.rgb * NdotL + diffuse.rgb * i.ambient;
                FinalColor.a = diffuse.a;
                // apply fog
                return FinalColor;
            }
            ENDCG
            
        }
    }
}
// todo:
// 2019-5-5 23:14:26
// 世界空间的法线贴图