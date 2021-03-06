﻿Shader "Unlit/FresnelGlassShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Bias ("Bias", Range(0, 10)) = 0.1
		_Scale ("Scale", Range(0, 20)) = 2
		_Power ("Power", Range(0, 4)) = 1
		_BaseColor("BaseColor", Color) = (0, 0, 0, 1)
		_IOR("Index of Refraction", Range(1, 3)) = 1.5
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
				float R : TEXCOORD1;
				float3 reflection : TEXCOORD2;
				float3 transmission : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Bias;
			float _Scale;
			float _Power;
			half4 _BaseColor;

			float _IOR;
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

				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 N = mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz; // UnityObjectToWorldNormal(v.normal); //

				float3 I = normalize(posWorld - _WorldSpaceCameraPos.xyz); // View vector // normalize(UnityWorldSpaceViewDir(posWorld)); //
				o.R = _Bias + _Scale * pow(1.0 + dot(I, N), _Power);
				
				o.reflection = reflect(I, N);

				o.transmission = refract(I, N, 1 / _IOR);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 reflectedData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.reflection);
				half3 reflectedColor = DecodeHDR(reflectedData, unity_SpecCube0_HDR);
				
				half4 refractedData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.transmission);
				half3 refractedColor = DecodeHDR(refractedData, unity_SpecCube0_HDR);
				fixed4 transparentColor = lerp(_BaseColor, fixed4(refractedColor, 1), _Transparency);

				half3 fresnelIntensity = lerp((0, 0, 0, 1), (1, 1, 1, 1), i.R);
				half3 fresneledReflection = fresnelIntensity * reflectedColor;

				fixed4 finalColor = transparentColor + fixed4(fresneledReflection, 0);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, finalColor);

				return finalColor;
			}
			ENDCG
		}
	}
}
