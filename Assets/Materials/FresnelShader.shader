Shader "Unlit/FresnelShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Bias ("Bias", Range(0, 10)) = 1
		_Scale ("Scale", Range(0, 20)) = 2
		_Power ("Power", Range(0, 4)) = 1
		_BaseColor("BaseColor", Color) = (0, 0, 0, 1)
		_FresnelColor("FresnelColor", Color) = (1, 1, 1, 1)
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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Bias;
			float _Scale;
			float _Power;
			half4 _BaseColor;
			half4 _FresnelColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);

				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				float3 normWorld = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0.0)).xyz); // UnityObjectToWorldNormal(v.normal); //

				float3 I = normalize(posWorld - _WorldSpaceCameraPos.xyz); // View vector // normalize(UnityWorldSpaceViewDir(posWorld)); //
				o.R = _Bias + _Scale * pow(1.0 + dot(I, normWorld), _Power);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = _BaseColor; //tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return lerp(col, _FresnelColor, i.R);
			}
			ENDCG
		}
	}
}
