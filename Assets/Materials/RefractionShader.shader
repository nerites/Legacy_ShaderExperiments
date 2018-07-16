Shader "Unlit/RefractionShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_IOR ("Index of Refraction", Range(1, 3)) = 1.5
		_Color("Material Color", Color) = (1, 1, 1, 1)
		_Transparency("Transparency", Range(0, 1)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 T : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			float _IOR;
			fixed4 _Color;
			float _Transparency; 

			float3 refract(float3 I, float3 N, float relIOR) {
				// relIOR is the relative index of refraction.
				// For this scene, the origin medium is air, so relIOR = 1/_IOR. 
				// Returns refracted vector T. 
				float cosI = dot(-I, N);
				float cosT2 = 1.0f - relIOR * relIOR * (1.0f - cosI * cosI);
				float3 T = relIOR * I + ((relIOR * cosI - sqrt(abs(cosT2))) * N);
				return T * (float3)(cosT2 > 0); 
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				float3 N = mul((float3x3)unity_ObjectToWorld, v.normal);
				N = normalize(N);

				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;

				// Compute incident and refracted vectors
				float3 I = normalize(posWorld - _WorldSpaceCameraPos.xyz);
				
				o.T = refract(I, N, 1/_IOR);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				
				half4 refractedData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.T);
				half3 refractedColor = DecodeHDR(refractedData, unity_SpecCube0_HDR);

				fixed4 finalColor = lerp(_Color, fixed4(refractedColor, 1), _Transparency)

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalColor);
				return finalColor;
			}
			ENDCG
		}
	}
}
