Shader "Unlit/ReflectionShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "black" {}
		_BaseColor ("Color", Color) = (0, 0, 0, 1)
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
				float3 reflection : TEXCOORD1; 
			};

			sampler2D _MainTex;
			samplerCUBE _ReflectTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				// Compute position and normal in worldspace
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz; 
				float3 N = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz);
				float3 I = normalize(posWorld - _WorldSpaceCameraPos.xyz);
				o.reflection = reflect(I, N); 

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_MainTex, i.uv);
				half4 reflectedData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.reflection); 
				half3 reflectedColor = DecodeHDR(reflectedData, unity_SpecCube0_HDR);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, reflectedColor);
				return fixed4(reflectedColor.rgb, 0);
			}
			ENDCG
		}
	}
}
