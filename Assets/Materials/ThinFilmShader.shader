Shader "Custom/ThinFilmShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0

		// Refractive index cannot go below 1, and diamond's refractive index is 2.42.
		// Use refractive index of water as the default.
		_RefractiveIndex ("Refractive Index", Range(1, 3)) = 1.33 

		// Film thickness, in nm
		_Thickness ("Film thickness (uniform)", Range(0, 2000)) = 300 

		// Let's do bubbles and coated objects in the same shader
		_BaseOpacity("Opacity of substrate", Range(0, 1)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf ThinFilm fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		#include "UnityPBSLighting.cginc"

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		float _RefractiveIndex;
		float _Thickness; 
		float _BaseOpacity;

		inline fixed3 bump3y(fixed3 x, fixed3 yoffset) {
			float3 y = 1 - x * x;
			y = saturate(y - yoffset);
			return y;
		}

		inline fixed3 SpectralZucconi6(float w) {
			float x = saturate((w - 400.0) / 300.0);

			const fixed3 c1 = fixed3(3.54585104, 2.93225262, 2.41593945);
			const fixed3 x1 = fixed3(0.69549072, 0.49228336, 0.27699880);
			const fixed3 y1 = fixed3(0.02312639, 0.15225084, 0.52607955);

			const fixed3 c2 = fixed3(3.90307140, 3.21182957, 3.96587128);
			const fixed3 x2 = fixed3(0.11748627, 0.86755042, 0.66077860);
			const fixed3 y2 = fixed3(0.84897130, 0.88445281, 0.73949448);

			return bump3y(c1 * (x - x1), y1) + bump3y(c2 * (x - x2), y2);
		}

		inline fixed4 LightingThinFilm (SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi) {
			// Original color from standard shader
			fixed4 pbr = LightingStandard(s, viewDir, gi);
			float3 L = gi.light.dir;
			float3 V = viewDir;
			float3 N = s.Normal;

			float d = _Thickness;
			float r = _RefractiveIndex;
			float a = _BaseOpacity;

			// Add diffractive iridescence
			fixed3 reflectedColor = 0;

			float sin_ThetaL;
			float cos_ThetaR;

			sin_ThetaL = dot(L, N);
			float radical = 1 - ((sin_ThetaL / r) * (sin_ThetaL / r));
			if (radical <= 0) return pbr;
			cos_ThetaR = sqrt(radical);

			for (int n = 1; n <= 4; n++) // for multiples of wavelength up to 8w
			{
				float wavelength = (r*2*d*cos_ThetaR)/((float)n + 0.5);
				reflectedColor += SpectralZucconi6(wavelength);
			}
			reflectedColor = saturate(reflectedColor);

			// Add reflected color to material color
			pbr.rgb += reflectedColor;
			return pbr;
		}

		void LightingThinFilm_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi) {
			// All custom PBR surface shaders need a _GI function. We're just reusing the Standard shader's GI function.
			LightingStandard_GI(s, data, gi);
		}

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
